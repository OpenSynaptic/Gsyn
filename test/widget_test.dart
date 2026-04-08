import 'package:flutter_test/flutter_test.dart';
import 'package:opensynaptic_dashboard/protocol/codec/base62.dart';
import 'package:opensynaptic_dashboard/protocol/codec/crc.dart';
import 'package:opensynaptic_dashboard/protocol/codec/packet_builder.dart';
import 'package:opensynaptic_dashboard/protocol/codec/packet_decoder.dart';
import 'package:opensynaptic_dashboard/protocol/codec/commands.dart';
import 'dart:typed_data';

void main() {
  group('Base62 codec', () {
    test('encode zero', () {
      expect(Base62.encode(0), '0');
    });
    test('encode positive', () {
      expect(Base62.encode(62), '10');
      expect(Base62.encode(1), '1');
      expect(Base62.encode(61), 'Z');
    });
    test('encode negative', () {
      expect(Base62.encode(-1), '-1');
    });
    test('round-trip', () {
      for (final v in [0, 1, -1, 100, 215000, -999999, 2147483647]) {
        expect(Base62.decode(Base62.encode(v)), v);
      }
    });
    test('value encoding (21.5 Celsius)', () {
      final encoded = Base62.encodeValue(21.5);
      final decoded = Base62.decodeValue(encoded);
      expect((decoded - 21.5).abs() < 0.001, true);
    });
  });

  group('CRC', () {
    test('crc8 empty returns 0', () {
      expect(OsCrc.crc8(Uint8List(0)), 0);
    });
    test('crc16 empty returns 0', () {
      expect(OsCrc.crc16(Uint8List(0)), 0);
    });
    test('crc8 known value', () {
      final data = Uint8List.fromList([0x31, 0x32, 0x33]);
      final crc = OsCrc.crc8(data);
      expect(crc, isNonZero);
    });
  });

  group('Packet encode/decode round-trip', () {
    test('FULL sensor packet round-trip', () {
      final frame = PacketBuilder.buildSensorPacket(
        aid: 12345,
        tid: 1,
        tsSec: 1710000000,
        sensorId: 'T1',
        unit: 'Cel',
        value: 21.5,
      );
      expect(frame, isNotNull);
      expect(frame!.length, greaterThanOrEqualTo(16));

      final meta = PacketDecoder.decode(frame);
      expect(meta, isNotNull);
      expect(meta!.cmd, OsCmd.dataFull);
      expect(meta.aid, 12345);
      expect(meta.tid, 1);
      expect(meta.tsSec, 1710000000);
      expect(meta.crc8Ok, true);
      expect(meta.crc16Ok, true);
      expect(meta.bodyLen, greaterThan(0));
    });
  });

  group('Commands', () {
    test('normalize secure variants', () {
      expect(OsCmd.normalizeDataCmd(64), 63);
      expect(OsCmd.normalizeDataCmd(171), 170);
      expect(OsCmd.normalizeDataCmd(128), 127);
      expect(OsCmd.normalizeDataCmd(63), 63);
    });
  });
}
