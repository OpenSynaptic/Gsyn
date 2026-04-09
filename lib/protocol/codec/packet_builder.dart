/// OpenSynaptic wire packet builder — exact port of ostx_packet.c
/// Builds FULL frames and sensor packets for TX.
import 'dart:typed_data';
import 'dart:convert';
import 'package:gsyn/protocol/codec/crc.dart';
import 'package:gsyn/protocol/codec/base62.dart';
import 'package:gsyn/protocol/codec/commands.dart';

class PacketBuilder {
  /// Build a raw OpenSynaptic wire packet.
  /// Matches ostx_packet_build() from OSynaptic-TX.
  ///
  /// Wire format:
  ///   [0]      cmd
  ///   [1]      route_count (fixed 1)
  ///   [2..5]   source_aid (big-endian u32)
  ///   [6]      tid
  ///   [7..12]  timestamp (48-bit big-endian; bytes 7-8 = 0, 9-12 = ts_sec)
  ///   [13..]   body
  ///   [-3]     CRC-8 of body
  ///   [-2..-1] CRC-16 of all preceding bytes
  static Uint8List? buildPacket({
    required int cmd,
    required int aid,
    required int tid,
    required int tsSec,
    required Uint8List body,
  }) {
    final frameLen = 13 + body.length + 3;
    if (frameLen > 512) return null; // safety limit

    final out = Uint8List(frameLen);
    int off = 0;

    out[off++] = cmd & 0xFF;
    out[off++] = 1; // route_count = 1

    // aid: 4-byte big-endian
    out[off++] = (aid >> 24) & 0xFF;
    out[off++] = (aid >> 16) & 0xFF;
    out[off++] = (aid >> 8) & 0xFF;
    out[off++] = aid & 0xFF;

    out[off++] = tid & 0xFF;

    // timestamp: 6-byte big-endian; upper 2 bytes = 0
    out[off++] = 0;
    out[off++] = 0;
    out[off++] = (tsSec >> 24) & 0xFF;
    out[off++] = (tsSec >> 16) & 0xFF;
    out[off++] = (tsSec >> 8) & 0xFF;
    out[off++] = tsSec & 0xFF;

    // body
    for (int i = 0; i < body.length; i++) {
      out[off++] = body[i];
    }

    // CRC-8 over body
    final crc8Val = OsCrc.crc8(body);
    out[off++] = crc8Val;

    // CRC-16 over all preceding bytes
    final crc16Val = OsCrc.crc16(Uint8List.sublistView(out, 0, off));
    out[off++] = (crc16Val >> 8) & 0xFF;
    out[off++] = crc16Val & 0xFF;

    return out;
  }

  /// Build a single-sensor FULL packet matching ostx_sensor_pack().
  /// Body format: "{aid}.U.{ts_b64}|{sid}>U.{unit}:{b62}|"
  static Uint8List? buildSensorPacket({
    required int aid,
    required int tid,
    required int tsSec,
    required String sensorId,
    required String unit,
    required double value,
  }) {
    final aidStr = aid.toString();
    final tsB64 = Base62.encodeTimestamp(tsSec);
    final b62 = Base62.encodeValue(value);

    // Body: "{aid}.U.{ts_b64}|{sid}>U.{unit}:{b62}|"
    final bodyStr = '$aidStr.U.$tsB64|$sensorId>U.$unit:$b62|';
    final body = Uint8List.fromList(utf8.encode(bodyStr));

    return buildPacket(
      cmd: OsCmd.dataFull,
      aid: aid,
      tid: tid,
      tsSec: tsSec,
      body: body,
    );
  }

  /// Build a multi-sensor FULL packet.
  /// Body format: "{nodeId}.{nodeState}.{ts_b64}|{s1}>U.{u1}:{v1}|{s2}>U.{u2}:{v2}|..."
  static Uint8List? buildMultiSensorPacket({
    required int aid,
    required int tid,
    required int tsSec,
    required String nodeId,
    required String nodeState,
    required List<Map<String, dynamic>> sensors,
  }) {
    final tsB64 = Base62.encodeTimestamp(tsSec);

    final buf = StringBuffer('$nodeId.$nodeState.$tsB64|');
    for (final s in sensors) {
      final sid = s['sensor_id'] as String;
      final unit = s['unit'] as String;
      final val = s['value'] as double;
      final state = s['state'] as String? ?? 'U';
      final b62 = Base62.encodeValue(val);
      buf.write('$sid>$state.$unit:$b62|');
    }

    final body = Uint8List.fromList(utf8.encode(buf.toString()));

    return buildPacket(
      cmd: OsCmd.dataFull,
      aid: aid,
      tid: tid,
      tsSec: tsSec,
      body: body,
    );
  }

  /// Build a PING control frame: [cmd:1][seq:2]
  static Uint8List buildPing(int seq) {
    final out = Uint8List(3);
    out[0] = OsCmd.ping;
    out[1] = (seq >> 8) & 0xFF;
    out[2] = seq & 0xFF;
    return out;
  }

  /// Build a PONG control frame: [cmd:1][seq:2]
  static Uint8List buildPong(int seq) {
    final out = Uint8List(3);
    out[0] = OsCmd.pong;
    out[1] = (seq >> 8) & 0xFF;
    out[2] = seq & 0xFF;
    return out;
  }

  /// Build an ID_REQUEST control frame: [cmd:1][seq:2]
  static Uint8List buildIdRequest(int seq) {
    final out = Uint8List(3);
    out[0] = OsCmd.idRequest;
    out[1] = (seq >> 8) & 0xFF;
    out[2] = seq & 0xFF;
    return out;
  }

  /// Build a TIME_REQUEST control frame: [cmd:1][seq:2]
  static Uint8List buildTimeRequest(int seq) {
    final out = Uint8List(3);
    out[0] = OsCmd.timeRequest;
    out[1] = (seq >> 8) & 0xFF;
    out[2] = seq & 0xFF;
    return out;
  }
}
