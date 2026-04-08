/// Unified transport manager — merges UDP + MQTT streams, routes commands.
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opensynaptic_dashboard/protocol/transport/udp_transport.dart';
import 'package:opensynaptic_dashboard/protocol/transport/mqtt_transport.dart';
import 'package:opensynaptic_dashboard/protocol/models/device_message.dart';

class TransportManager {
  final UdpTransport udp = UdpTransport();
  final MqttTransport mqtt = MqttTransport();

  final _messageController = StreamController<DeviceMessage>.broadcast();
  final _statsController = StreamController<TransportStats>.broadcast();

  StreamSubscription? _udpSub;
  StreamSubscription? _mqttSub;

  int _totalMessages = 0;
  int _messagesThisSecond = 0;

  Stream<DeviceMessage> get messageStream => _messageController.stream;
  Stream<TransportStats> get statsStream => _statsController.stream;
  int get totalMessages => _totalMessages;

  TransportManager() {
    _udpSub = udp.messageStream.listen(_onMessage);
    _mqttSub = mqtt.messageStream.listen(_onMessage);

    // Periodic stats update
    Timer.periodic(const Duration(seconds: 1), (_) {
      _statsController.add(TransportStats(
        udpConnected: udp.isRunning,
        mqttConnected: mqtt.isConnected,
        messagesPerSecond: _messagesThisSecond,
        totalMessages: _totalMessages,
      ));
      _messagesThisSecond = 0;
    });
  }

  void _onMessage(DeviceMessage msg) {
    _totalMessages++;
    _messagesThisSecond++;
    _messageController.add(msg);
  }

  /// Send a command frame via the appropriate transport.
  Future<bool> sendCommand({
    required Uint8List frame,
    required int deviceAid,
    String? udpHost,
    int? udpPort,
  }) async {
    // Try MQTT first, then UDP
    if (mqtt.isConnected) {
      return mqtt.publish(deviceAid, frame);
    }
    if (udp.isRunning && udpHost != null && udpPort != null) {
      return udp.send(frame, udpHost, udpPort);
    }
    return false;
  }

  void dispose() {
    _udpSub?.cancel();
    _mqttSub?.cancel();
    udp.dispose();
    mqtt.dispose();
    _messageController.close();
    _statsController.close();
  }
}

class TransportStats {
  final bool udpConnected;
  final bool mqttConnected;
  final int messagesPerSecond;
  final int totalMessages;

  const TransportStats({
    required this.udpConnected,
    required this.mqttConnected,
    required this.messagesPerSecond,
    required this.totalMessages,
  });
}

// Riverpod providers
final transportManagerProvider = Provider<TransportManager>((ref) {
  final manager = TransportManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});

final messageStreamProvider = StreamProvider<DeviceMessage>((ref) {
  return ref.watch(transportManagerProvider).messageStream;
});

final transportStatsProvider = StreamProvider<TransportStats>((ref) {
  return ref.watch(transportManagerProvider).statsStream;
});

