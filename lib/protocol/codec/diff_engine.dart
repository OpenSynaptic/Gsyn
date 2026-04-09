// OpenSynaptic DIFF/HEART template engine.
// Port of the template-learning and reconstruction logic from unified_parser.py.
import 'dart:convert';
import 'dart:typed_data';
import 'package:opensynaptic_dashboard/protocol/codec/commands.dart';
import 'package:opensynaptic_dashboard/protocol/codec/base62.dart';

/// Cached template state for a (aid, tid) pair.
class _TemplateState {
  String signature; // template with {TS} and \x01 placeholders
  List<Uint8List> valsBin; // cached binary values for each slot

  _TemplateState({required this.signature, required this.valsBin});
}

class DiffEngine {
  // Map<aidStr, Map<tidStr, TemplateState>>
  final Map<String, Map<String, _TemplateState>> _cache = {};

  /// Process a complete packet and return decoded body text.
  /// Handles FULL (learns template), HEART (uses cached), DIFF (updates changed).
  /// Returns the reconstructed full body string, or null on error.
  String? processPacket({
    required int cmd,
    required int aid,
    required int tid,
    required Uint8List body,
  }) {
    final baseCmd = OsCmd.normalizeDataCmd(cmd);
    final aidStr = aid.toString();
    final tidStr = tid.toString().padLeft(2, '0');

    switch (baseCmd) {
      case OsCmd.dataFull:
        return _handleFull(aidStr, tidStr, body);
      case OsCmd.dataHeart:
        return _handleHeart(aidStr, tidStr);
      case OsCmd.dataDiff:
        return _handleDiff(aidStr, tidStr, body);
      default:
        return null;
    }
  }

  /// FULL: learn template from body text, cache values.
  String? _handleFull(String aidStr, String tidStr, Uint8List body) {
    if (body.isEmpty) return null;

    final text = utf8.decode(body, allowMalformed: true);
    final decomp = _decompose(text);
    if (decomp == null) return null;

    final aidTemplates = _cache.putIfAbsent(aidStr, () => {});
    aidTemplates[tidStr] = _TemplateState(
      signature: decomp.signature,
      valsBin: decomp.valsBin,
    );

    return text;
  }

  /// HEART: reconstruct from cached template + cached values (no changes).
  String? _handleHeart(String aidStr, String tidStr) {
    final state = _cache[aidStr]?[tidStr];
    if (state == null || state.valsBin.isEmpty) return null;

    return _reconstruct(state.signature, state.valsBin);
  }

  /// DIFF: read bitmask, update changed slots, reconstruct.
  String? _handleDiff(String aidStr, String tidStr, Uint8List body) {
    final state = _cache[aidStr]?[tidStr];
    if (state == null || state.valsBin.isEmpty) return null;

    final numVals = state.valsBin.length;
    final maskLen = (numVals + 7) ~/ 8;

    if (body.length < maskLen) return null;

    // Read bitmask (big-endian)
    int mask = 0;
    for (int i = 0; i < maskLen; i++) {
      mask = (mask << 8) | body[i];
    }

    int off = maskLen;
    for (int i = 0; i < numVals; i++) {
      if ((mask >> i) & 1 == 1) {
        if (off >= body.length) return null;
        final vLen = body[off];
        off += 1;
        if (off + vLen > body.length) return null;
        state.valsBin[i] = Uint8List.fromList(body.sublist(off, off + vLen));
        off += vLen;
      }
    }

    return _reconstruct(state.signature, state.valsBin);
  }

  /// Decompose a FULL body text into signature + value slots.
  /// Matches _decompose_for_receive() from unified_parser.py.
  _DecompResult? _decompose(String text) {
    // Skip any prefix before ';'
    String work = text;
    final semi = work.indexOf(';');
    if (semi >= 0) work = work.substring(semi + 1);

    final pipe = work.indexOf('|');
    if (pipe < 0) return null;

    final head = work.substring(0, pipe);
    final payload = work.substring(pipe + 1);

    // Replace ts_token with {TS} placeholder
    final lastDot = head.lastIndexOf('.');
    if (lastDot < 0) return null;
    final hBase = head.substring(0, lastDot);

    final sigSegments = <String>[];
    final valsBin = <Uint8List>[];

    for (final seg in payload.split('|')) {
      if (seg.isEmpty) continue;

      final gt = seg.indexOf('>');
      final colon = seg.indexOf(':');
      if (gt >= 0 && colon >= 0 && colon > gt) {
        final tag = seg.substring(0, gt);
        final content = seg.substring(gt + 1);
        final colonInContent = content.indexOf(':');
        if (colonInContent < 0) continue;

        final meta = content.substring(0, colonInContent);
        final val = content.substring(colonInContent + 1);

        sigSegments.add('$tag>\x01:\x01');
        valsBin.add(Uint8List.fromList(utf8.encode(meta)));
        valsBin.add(Uint8List.fromList(utf8.encode(val)));
      } else {
        sigSegments.add(seg);
      }
    }

    final sig = '$hBase.{TS}|${sigSegments.join('|')}|';
    return _DecompResult(signature: sig, valsBin: valsBin);
  }

  /// Reconstruct full body text from signature + values.
  String _reconstruct(String signature, List<Uint8List> valsBin) {
    String result = signature;
    // Replace {TS} with current timestamp (or use a placeholder)
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    result = result.replaceFirst('{TS}', Base62.encodeTimestamp(nowSec));

    // Replace \x01 placeholders with values
    for (final val in valsBin) {
      result = result.replaceFirst(
        '\x01',
        utf8.decode(val, allowMalformed: true),
      );
    }

    return result;
  }

  /// Clear all cached templates.
  void clear() => _cache.clear();

  /// Get template count for diagnostics.
  int get templateCount {
    int count = 0;
    for (final m in _cache.values) {
      count += m.length;
    }
    return count;
  }
}

class _DecompResult {
  final String signature;
  final List<Uint8List> valsBin;

  const _DecompResult({required this.signature, required this.valsBin});
}
