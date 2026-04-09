// OpenSynaptic Base62 codec — exact port of ostx_b62.c / osrx_b62.c
// Alphabet: 0-9 a-z A-Z  (62 chars, case-sensitive, digits first)
import 'dart:convert';

class Base62 {
  static const String _alphabet =
      '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

  static const String _b64urlAlphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

  /// Encode a signed integer to Base62 string.
  /// Matches ostx_b62_encode() from OSynaptic-TX.
  static String encode(int value) {
    if (value == 0) return '0';

    final bool neg = value < 0;
    int n = neg ? -value : value;

    final buf = <String>[];
    while (n > 0) {
      buf.add(_alphabet[n % 62]);
      n ~/= 62;
    }

    final digits = buf.reversed.join();
    return neg ? '-$digits' : digits;
  }

  /// Decode a Base62 string to signed integer.
  /// Matches osrx_b62_decode() from OSynaptic-RX.
  static int decode(String s) {
    if (s.isEmpty) return 0;

    int start = 0;
    bool neg = false;
    if (s[0] == '-') {
      neg = true;
      start = 1;
      if (start >= s.length) return 0;
    }

    int val = 0;
    for (int i = start; i < s.length; i++) {
      final c = s.codeUnitAt(i);
      int d;
      if (c >= 48 && c <= 57) {
        d = c - 48; // '0'-'9' → 0-9
      } else if (c >= 97 && c <= 122) {
        d = 10 + (c - 97); // 'a'-'z' → 10-35
      } else if (c >= 65 && c <= 90) {
        d = 36 + (c - 65); // 'A'-'Z' → 36-61
      } else {
        return 0; // invalid character
      }
      val = val * 62 + d;
    }

    return neg ? -val : val;
  }

  /// Encode a 32-bit Unix timestamp as an 8-character base64url string.
  /// Matches ostx_b64url_ts() from OSynaptic-TX.
  /// The timestamp is treated as the lower 32 bits of a 48-bit big-endian
  /// word (upper 16 bits = 0).
  static String encodeTimestamp(int tsSec) {
    final b2 = (tsSec >> 24) & 0xFF;
    final b3 = (tsSec >> 16) & 0xFF;
    final b4 = (tsSec >> 8) & 0xFF;
    final b5 = tsSec & 0xFF;

    // Group 1: 0x00, 0x00, b2
    final out = List<int>.filled(8, 0);
    out[0] = _b64urlAlphabet.codeUnitAt(0); // 0x00 >> 2
    out[1] = _b64urlAlphabet.codeUnitAt(0); // (0&3)<<4|(0>>4)
    out[2] = _b64urlAlphabet.codeUnitAt((b2 >> 6) & 0x03);
    out[3] = _b64urlAlphabet.codeUnitAt(b2 & 0x3F);

    // Group 2: b3, b4, b5
    out[4] = _b64urlAlphabet.codeUnitAt((b3 >> 2) & 0x3F);
    out[5] = _b64urlAlphabet.codeUnitAt(
      ((b3 & 0x03) << 4) | ((b4 >> 4) & 0x0F),
    );
    out[6] = _b64urlAlphabet.codeUnitAt(
      ((b4 & 0x0F) << 2) | ((b5 >> 6) & 0x03),
    );
    out[7] = _b64urlAlphabet.codeUnitAt(b5 & 0x3F);

    return String.fromCharCodes(out);
  }

  /// Decode a base64url timestamp string back to Unix seconds.
  static int decodeTimestamp(String tsB64) {
    try {
      // Pad to 12 chars (base64 of 6 bytes = 8 chars, but urlsafe_b64decode expects padding)
      String padded = tsB64;
      while (padded.length % 4 != 0) {
        padded += '=';
      }
      final bytes = base64Url.decode(padded);
      if (bytes.length < 6) return 0;
      // 6 bytes big-endian, we take lower 4 bytes as uint32
      return (bytes[2] << 24) | (bytes[3] << 16) | (bytes[4] << 8) | bytes[5];
    } catch (_) {
      return 0;
    }
  }

  /// Scale factor used by OpenSynaptic for encoding sensor values.
  static const int valueScale = 10000;

  /// Encode a double sensor value to Base62 using the standard scale.
  static String encodeValue(double value) {
    return encode((value * valueScale).round());
  }

  /// Decode a Base62 sensor value to double using the standard scale.
  static double decodeValue(String b62) {
    return decode(b62) / valueScale;
  }
}
