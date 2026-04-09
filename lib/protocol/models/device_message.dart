/// A fully decoded device message from an OpenSynaptic packet.
import 'package:opensynaptic_dashboard/protocol/models/packet_meta.dart';
import 'package:opensynaptic_dashboard/protocol/models/sensor_reading.dart';

class DeviceMessage {
  final PacketMeta meta;
  final int deviceAid;
  final String nodeId;
  final String nodeState;
  final int timestampSec;
  final List<SensorReading> readings;
  final DateTime receivedAt;
  final String transportType; // 'udp' or 'mqtt'

  DeviceMessage({
    required this.meta,
    required this.deviceAid,
    this.nodeId = '',
    this.nodeState = '',
    required this.timestampSec,
    required this.readings,
    DateTime? receivedAt,
    this.transportType = 'udp',
  }) : receivedAt = receivedAt ?? DateTime.now();

  @override
  String toString() =>
      'DeviceMessage(aid=$deviceAid, sensors=${readings.length}, ts=$timestampSec)';
}
