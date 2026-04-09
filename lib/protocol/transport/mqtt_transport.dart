/// MQTT transport for OpenSynaptic — connects to broker, subscribes/publishes.
import 'dart:async';
import 'dart:typed_data';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'package:gsyn/protocol/codec/packet_decoder.dart';
import 'package:gsyn/protocol/codec/body_parser.dart';
import 'package:gsyn/protocol/codec/diff_engine.dart';
import 'package:gsyn/protocol/codec/commands.dart';
import 'package:gsyn/protocol/models/device_message.dart';

class MqttTransport {
  MqttServerClient? _client;
  final DiffEngine _diffEngine = DiffEngine();
  final _messageController = StreamController<DeviceMessage>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  bool _connected = false;
  String _topicPrefix = 'opensynaptic';

  Stream<DeviceMessage> get messageStream => _messageController.stream;
  Stream<String> get statusStream => _statusController.stream;
  bool get isConnected => _connected;

  /// Connect to MQTT broker and subscribe to data topics.
  Future<bool> connect({
    required String broker,
    int port = 1883,
    String? username,
    String? password,
    String topicPrefix = 'opensynaptic',
    String clientId = 'os_dashboard',
  }) async {
    try {
      await disconnect();
      _topicPrefix = topicPrefix;

      _client = MqttServerClient.withPort(broker, clientId, port);
      _client!.logging(on: false);
      _client!.keepAlivePeriod = 30;
      _client!.autoReconnect = true;
      _client!.onConnected = () {
        _connected = true;
        _statusController.add('connected');
      };
      _client!.onDisconnected = () {
        _connected = false;
        _statusController.add('disconnected');
      };
      _client!.onAutoReconnect = () {
        _statusController.add('reconnecting');
      };
      _client!.onAutoReconnected = () {
        _connected = true;
        _statusController.add('connected');
        _subscribeDataTopics();
      };

      final connMsg = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean();

      _client!.connectionMessage = connMsg;

      await _client!.connect(username, password);

      if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
        _connected = true;
        _statusController.add('connected');
        _subscribeDataTopics();
        _listenMessages();
        return true;
      }

      return false;
    } catch (e) {
      _statusController.add('error: $e');
      return false;
    }
  }

  void _subscribeDataTopics() {
    _client?.subscribe('$_topicPrefix/+/data', MqttQos.atLeastOnce);
    _client?.subscribe('$_topicPrefix/+/status', MqttQos.atLeastOnce);
  }

  void _listenMessages() {
    _client?.updates.listen((List<MqttReceivedMessage<MqttMessage>> events) {
      for (final event in events) {
        final msg = event.payload as MqttPublishMessage;
        final payload = msg.payload.message;
        if (payload != null && payload.isNotEmpty) {
          _processPacket(Uint8List.fromList(payload));
        }
      }
    });
  }

  /// Publish a raw frame to a device command topic.
  Future<bool> publish(int deviceAid, Uint8List frame) async {
    if (_client == null || !_connected) return false;
    try {
      final topic = '$_topicPrefix/$deviceAid/cmd';
      final builder = MqttPayloadBuilder();
      final buf = typed.Uint8Buffer();
      buf.addAll(frame);
      builder.addBuffer(buf);
      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Disconnect from broker.
  Future<void> disconnect() async {
    _client?.disconnect();
    _client = null;
    _connected = false;
    _statusController.add('disconnected');
  }

  void _processPacket(Uint8List raw) {
    final meta = PacketDecoder.decode(raw);
    if (meta == null || !meta.crc16Ok || !meta.crc8Ok) return;

    if (!OsCmd.isDataCmd(meta.cmd)) return;

    final body = Uint8List.sublistView(
      raw,
      meta.bodyOffset,
      meta.bodyOffset + meta.bodyLen,
    );
    final bodyText = _diffEngine.processPacket(
      cmd: meta.cmd,
      aid: meta.aid,
      tid: meta.tid,
      body: body,
    );

    if (bodyText == null) return;

    final parsed = BodyParser.parseBodyText(bodyText);
    if (parsed == null || parsed.readings.isEmpty) return;

    _messageController.add(
      DeviceMessage(
        meta: meta,
        deviceAid: meta.aid,
        nodeId: parsed.headerAid,
        nodeState: parsed.headerState,
        timestampSec: meta.tsSec,
        readings: parsed.readings,
        transportType: 'mqtt',
      ),
    );
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
  }
}
