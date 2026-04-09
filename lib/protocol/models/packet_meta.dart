/// Parsed header fields from an OpenSynaptic wire packet.
/// Mirrors osrx_packet_meta from OSynaptic-RX.
class PacketMeta {
  final int cmd;
  final int routeCount;
  final int aid; // source device ID (u32)
  final int tid; // transaction/template ID (u8)
  final int tsSec; // lower 32 bits of 48-bit timestamp
  final int bodyOffset;
  final int bodyLen;
  final bool crc8Ok;
  final bool crc16Ok;

  const PacketMeta({
    required this.cmd,
    required this.routeCount,
    required this.aid,
    required this.tid,
    required this.tsSec,
    required this.bodyOffset,
    required this.bodyLen,
    required this.crc8Ok,
    required this.crc16Ok,
  });

  @override
  String toString() =>
      'PacketMeta(cmd=$cmd, aid=$aid, tid=$tid, ts=$tsSec, body=$bodyLen, crc8=$crc8Ok, crc16=$crc16Ok)';
}
