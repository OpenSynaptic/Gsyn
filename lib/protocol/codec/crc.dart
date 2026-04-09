/// OpenSynaptic CRC algorithms — exact port of ostx_crc.c
/// CRC-8/SMBUS: poly=0x07, init=0x00
/// CRC-16/CCITT-FALSE: poly=0x1021, init=0xFFFF
import 'dart:typed_data';

class OsCrc {
  /// CRC-8/SMBUS over [data]. Matches ostx_crc8().
  static int crc8(Uint8List data, {int poly = 0x07, int init = 0x00}) {
    if (data.isEmpty) return 0;
    int crc = init & 0xFF;
    for (int i = 0; i < data.length; i++) {
      crc = (crc ^ data[i]) & 0xFF;
      for (int bit = 0; bit < 8; bit++) {
        if ((crc & 0x80) != 0) {
          crc = ((crc << 1) ^ poly) & 0xFF;
        } else {
          crc = (crc << 1) & 0xFF;
        }
      }
    }
    return crc;
  }

  /// CRC-16/CCITT-FALSE over [data]. Matches ostx_crc16().
  static int crc16(Uint8List data, {int poly = 0x1021, int init = 0xFFFF}) {
    if (data.isEmpty) return 0;
    int crc = init & 0xFFFF;
    for (int i = 0; i < data.length; i++) {
      crc = (crc ^ (data[i] << 8)) & 0xFFFF;
      for (int bit = 0; bit < 8; bit++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ poly) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc;
  }
}
