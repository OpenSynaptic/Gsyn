/// OpenSynaptic command byte constants — from osfx_handshake_cmd.h
class OsCmd {
  // Data commands
  static const int dataFull = 63;
  static const int dataFullSec = 64;
  static const int dataDiff = 170;
  static const int dataDiffSec = 171;
  static const int dataHeart = 127;
  static const int dataHeartSec = 128;

  // Control commands
  static const int idRequest = 1;
  static const int idAssign = 2;
  static const int idPoolReq = 3;
  static const int idPoolRes = 4;
  static const int handshakeAck = 5;
  static const int handshakeNack = 6;
  static const int ping = 9;
  static const int pong = 10;
  static const int timeRequest = 11;
  static const int timeResponse = 12;
  static const int secureDictReady = 13;
  static const int secureChannelAck = 14;

  /// Normalize secure data cmd → base cmd.
  static int normalizeDataCmd(int cmd) {
    switch (cmd) {
      case dataFullSec:
        return dataFull;
      case dataDiffSec:
        return dataDiff;
      case dataHeartSec:
        return dataHeart;
      default:
        return cmd;
    }
  }

  /// Check if cmd is a data command (FULL/DIFF/HEART or secure variants).
  static bool isDataCmd(int cmd) {
    return cmd == dataFull ||
        cmd == dataFullSec ||
        cmd == dataDiff ||
        cmd == dataDiffSec ||
        cmd == dataHeart ||
        cmd == dataHeartSec;
  }

  /// Check if cmd is a secure variant.
  static bool isSecureCmd(int cmd) {
    return cmd == dataFullSec || cmd == dataDiffSec || cmd == dataHeartSec;
  }

  /// Human-readable name.
  static String name(int cmd) {
    switch (cmd) {
      case dataFull:
        return 'DATA_FULL';
      case dataFullSec:
        return 'DATA_FULL_SEC';
      case dataDiff:
        return 'DATA_DIFF';
      case dataDiffSec:
        return 'DATA_DIFF_SEC';
      case dataHeart:
        return 'DATA_HEART';
      case dataHeartSec:
        return 'DATA_HEART_SEC';
      case idRequest:
        return 'ID_REQUEST';
      case idAssign:
        return 'ID_ASSIGN';
      case idPoolReq:
        return 'ID_POOL_REQ';
      case idPoolRes:
        return 'ID_POOL_RES';
      case handshakeAck:
        return 'HANDSHAKE_ACK';
      case handshakeNack:
        return 'HANDSHAKE_NACK';
      case ping:
        return 'PING';
      case pong:
        return 'PONG';
      case timeRequest:
        return 'TIME_REQUEST';
      case timeResponse:
        return 'TIME_RESPONSE';
      default:
        return 'UNKNOWN(0x${cmd.toRadixString(16)})';
    }
  }
}
