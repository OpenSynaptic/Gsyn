/// UDP transport for OpenSynaptic — receives/sends datagrams.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:gsyn/protocol/codec/packet_decoder.dart';
import 'package:gsyn/protocol/codec/body_parser.dart';
import 'package:gsyn/protocol/codec/diff_engine.dart';
import 'package:gsyn/protocol/codec/commands.dart';
import 'package:gsyn/protocol/models/device_message.dart';

class UdpTransport {
  RawDatagramSocket? _socket;
  final DiffEngine _diffEngine = DiffEngine();
  final _messageController = StreamController<DeviceMessage>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  bool _running = false;

  Stream<DeviceMessage> get messageStream => _messageController.stream;
  Stream<String> get statusStream => _statusController.stream;
  bool get isRunning => _running;

  /// Start listening for UDP datagrams on [host]:[port].
  Future<bool> listen(String host, int port) async {
    try {
      await stop();
      _socket = await RawDatagramSocket.bind(
        host == '0.0.0.0' ? InternetAddress.anyIPv4 : InternetAddress(host),
        port,
      );
      _running = true;
      _statusController.add('connected');

      _socket!.listen(
        (event) {
          if (event == RawSocketEvent.read) {
            final dg = _socket!.receive();
            if (dg != null) {
              _processPacket(Uint8List.fromList(dg.data));
            }
          }
        },
        onError: (e) {
          _statusController.add('error: $e');
        },
        onDone: () {
          _running = false;
          _statusController.add('disconnected');
        },
      );

      return true;
    } catch (e) {
      _statusController.add('error: $e');
      return false;
    }
  }

  /// Send raw frame to a target address.
  Future<bool> send(Uint8List frame, String host, int port) async {
    if (_socket == null) return false;
    try {
      _socket!.send(frame, InternetAddress(host), port);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stop the UDP listener.
  Future<void> stop() async {
    _socket?.close();
    _socket = null;
    _running = false;
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
        transportType: 'udp',
      ),
    );
  }

  void dispose() {
    stop();
    _messageController.close();
    _statusController.close();
  }
}
