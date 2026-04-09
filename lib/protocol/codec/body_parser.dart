/// OpenSynaptic body parser — parses FULL body text into SensorReadings.
/// Port of osrx_sensor_unpack() + multi-sensor support from template_grammar.
import 'dart:convert';
import 'dart:typed_data';
import 'package:opensynaptic_dashboard/protocol/codec/base62.dart';
import 'package:opensynaptic_dashboard/protocol/models/sensor_reading.dart';

class BodyParseResult {
  final String headerAid;
  final String headerState;
  final String tsToken;
  final List<SensorReading> readings;

  const BodyParseResult({
    required this.headerAid,
    required this.headerState,
    required this.tsToken,
    required this.readings,
  });
}

class BodyParser {
  /// Parse a FULL body from raw bytes.
  /// Body format: "{aid}.{status}.{ts_b64}|{sid}>{state}.{unit}:{b62}|..."
  static BodyParseResult? parseBody(Uint8List body) {
    if (body.isEmpty) return null;
    try {
      final text = utf8.decode(body, allowMalformed: true);
      return parseBodyText(text);
    } catch (_) {
      return null;
    }
  }

  /// Parse a FULL body from text string.
  static BodyParseResult? parseBodyText(String text) {
    if (text.isEmpty) return null;

    // Find first '|' separating header from sensor segments
    final firstPipe = text.indexOf('|');
    if (firstPipe < 0) return null;

    final header = text.substring(0, firstPipe);
    final payload = text.substring(firstPipe + 1);

    // Parse header: "{aid}.{status}.{ts_b64}"
    String headerAid = '';
    String headerState = '';
    String tsToken = '';

    // Split by last '.' to get ts_b64
    final lastDot = header.lastIndexOf('.');
    if (lastDot < 0) return null;
    tsToken = header.substring(lastDot + 1);
    final rest = header.substring(0, lastDot);

    // Split rest by first '.' to get aid and status
    final firstDot = rest.indexOf('.');
    if (firstDot < 0) {
      headerAid = rest;
      headerState = 'U';
    } else {
      headerAid = rest.substring(0, firstDot);
      headerState = rest.substring(firstDot + 1);
    }

    // Parse sensor segments: "{sid}>{state}.{unit}:{b62}"
    final readings = <SensorReading>[];
    for (final seg in payload.split('|')) {
      if (seg.isEmpty) continue;
      final reading = _parseSensorSegment(seg);
      if (reading != null) readings.add(reading);
    }

    return BodyParseResult(
      headerAid: headerAid,
      headerState: headerState,
      tsToken: tsToken,
      readings: readings,
    );
  }

  /// Parse a single sensor segment: "{sid}>{state}.{unit}:{b62}"
  static SensorReading? _parseSensorSegment(String seg) {
    // Find '>'
    final gtPos = seg.indexOf('>');
    if (gtPos <= 0) return null;

    final sensorId = seg.substring(0, gtPos);
    final content = seg.substring(gtPos + 1);

    // Find '.' after state
    final dotPos = content.indexOf('.');
    if (dotPos < 0) return null;

    final state = content.substring(0, dotPos);
    final afterDot = content.substring(dotPos + 1);

    // Find ':' after unit
    final colonPos = afterDot.indexOf(':');
    if (colonPos < 0) return null;

    final unit = afterDot.substring(0, colonPos);
    String b62Val = afterDot.substring(colonPos + 1);

    // Strip any extension markers (#, !, @)
    for (final marker in ['#', '!', '@']) {
      final idx = b62Val.indexOf(marker);
      if (idx >= 0) b62Val = b62Val.substring(0, idx);
    }

    final value = Base62.decodeValue(b62Val);

    return SensorReading(
      sensorId: sensorId,
      unit: unit,
      value: value,
      state: state,
      rawB62: b62Val,
    );
  }
}
