/// OpenSynaptic wire packet decoder — exact port of osrx_packet.c
import 'dart:typed_data';
import 'package:gsyn/protocol/codec/crc.dart';
import 'package:gsyn/protocol/models/packet_meta.dart';

class PacketDecoder {
  /// Decode a raw byte buffer into PacketMeta.
  /// Matches osrx_packet_decode() from OSynaptic-RX.
  ///
  /// Returns null if packet is malformed (too short, null).
  static PacketMeta? decode(Uint8List packet) {
    // Minimum: 13 header + 0 body + 3 CRC = 16 bytes
    if (packet.length < 16) return null;

    final bodyLen = packet.length - 13 - 3;
    if (bodyLen < 0) return null;

    // Parse header
    final cmd = packet[0];
    final routeCount = packet[1];
    final aid =
        (packet[2] << 24) | (packet[3] << 16) | (packet[4] << 8) | packet[5];
    final tid = packet[6];

    // Timestamp: 6 bytes big-endian; we keep lower 32 bits (bytes 9-12)
    final tsSec =
        (packet[9] << 24) | (packet[10] << 16) | (packet[11] << 8) | packet[12];

    // CRC-8: over body only
    final gotCrc8 = packet[packet.length - 3];
    int expCrc8;
    if (bodyLen > 0) {
      expCrc8 = OsCrc.crc8(Uint8List.sublistView(packet, 13, 13 + bodyLen));
    } else {
      expCrc8 = 0; // CRC-8 of empty = init=0, no bytes processed
    }
    final crc8Ok = expCrc8 == gotCrc8;

    // CRC-16: over all bytes except the last 2
    final gotCrc16 =
        (packet[packet.length - 2] << 8) | packet[packet.length - 1];
    final expCrc16 = OsCrc.crc16(
      Uint8List.sublistView(packet, 0, packet.length - 2),
    );
    final crc16Ok = expCrc16 == gotCrc16;

    return PacketMeta(
      cmd: cmd,
      routeCount: routeCount,
      aid: aid,
      tid: tid,
      tsSec: tsSec,
      bodyOffset: 13,
      bodyLen: bodyLen,
      crc8Ok: crc8Ok,
      crc16Ok: crc16Ok,
    );
  }
}
