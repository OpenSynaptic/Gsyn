/// Data models for the app.

class Device {
  final int? id;
  final int aid;
  final String name;
  final String type;
  final double lat;
  final double lng;
  final String status;
  final String transportType;
  final int lastSeenMs;

  const Device({
    this.id,
    required this.aid,
    this.name = '',
    this.type = 'sensor',
    this.lat = 0.0,
    this.lng = 0.0,
    this.status = 'offline',
    this.transportType = 'udp',
    this.lastSeenMs = 0,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'aid': aid,
        'name': name,
        'type': type,
        'lat': lat,
        'lng': lng,
        'status': status,
        'transport_type': transportType,
        'last_seen_ms': lastSeenMs,
      };

  factory Device.fromMap(Map<String, dynamic> m) => Device(
        id: m['id'] as int?,
        aid: m['aid'] as int,
        name: (m['name'] as String?) ?? '',
        type: (m['type'] as String?) ?? 'sensor',
        lat: (m['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (m['lng'] as num?)?.toDouble() ?? 0.0,
        status: (m['status'] as String?) ?? 'offline',
        transportType: (m['transport_type'] as String?) ?? 'udp',
        lastSeenMs: (m['last_seen_ms'] as int?) ?? 0,
      );

  Device copyWith({String? name, String? status, double? lat, double? lng, int? lastSeenMs, String? type}) =>
      Device(
        id: id,
        aid: aid,
        name: name ?? this.name,
        type: type ?? this.type,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        status: status ?? this.status,
        transportType: transportType,
        lastSeenMs: lastSeenMs ?? this.lastSeenMs,
      );
}

class SensorData {
  final int? id;
  final int deviceAid;
  final String sensorId;
  final String unit;
  final double value;
  final String rawB62;
  final int timestampMs;

  const SensorData({
    this.id,
    required this.deviceAid,
    required this.sensorId,
    this.unit = '',
    required this.value,
    this.rawB62 = '',
    required this.timestampMs,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'device_aid': deviceAid,
        'sensor_id': sensorId,
        'unit': unit,
        'value': value,
        'raw_b62': rawB62,
        'timestamp_ms': timestampMs,
      };

  factory SensorData.fromMap(Map<String, dynamic> m) => SensorData(
        id: m['id'] as int?,
        deviceAid: m['device_aid'] as int,
        sensorId: (m['sensor_id'] as String?) ?? '',
        unit: (m['unit'] as String?) ?? '',
        value: (m['value'] as num).toDouble(),
        rawB62: (m['raw_b62'] as String?) ?? '',
        timestampMs: m['timestamp_ms'] as int,
      );
}

class Alert {
  final int? id;
  final int deviceAid;
  final String sensorId;
  final int level; // 0=info, 1=warning, 2=critical
  final String message;
  final bool acknowledged;
  final int createdMs;

  const Alert({
    this.id,
    required this.deviceAid,
    this.sensorId = '',
    this.level = 0,
    this.message = '',
    this.acknowledged = false,
    required this.createdMs,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'device_aid': deviceAid,
        'sensor_id': sensorId,
        'level': level,
        'message': message,
        'acknowledged': acknowledged ? 1 : 0,
        'created_ms': createdMs,
      };

  factory Alert.fromMap(Map<String, dynamic> m) => Alert(
        id: m['id'] as int?,
        deviceAid: m['device_aid'] as int,
        sensorId: (m['sensor_id'] as String?) ?? '',
        level: (m['level'] as int?) ?? 0,
        message: (m['message'] as String?) ?? '',
        acknowledged: (m['acknowledged'] as int?) == 1,
        createdMs: m['created_ms'] as int,
      );

  String get levelName {
    switch (level) {
      case 2: return 'Critical';
      case 1: return 'Warning';
      default: return 'Info';
    }
  }
}

class Rule {
  final int? id;
  final String name;
  final int? deviceAidFilter;
  final String? sensorIdFilter;
  final String operator;
  final double threshold;
  final String actionType;
  final String actionPayload;
  final bool enabled;
  final int cooldownMs;

  const Rule({
    this.id,
    this.name = '',
    this.deviceAidFilter,
    this.sensorIdFilter,
    this.operator = '>',
    this.threshold = 0.0,
    this.actionType = 'create_alert',
    this.actionPayload = '{}',
    this.enabled = true,
    this.cooldownMs = 60000,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'device_aid_filter': deviceAidFilter,
        'sensor_id_filter': sensorIdFilter,
        'operator': operator,
        'threshold': threshold,
        'action_type': actionType,
        'action_payload': actionPayload,
        'enabled': enabled ? 1 : 0,
        'cooldown_ms': cooldownMs,
      };

  factory Rule.fromMap(Map<String, dynamic> m) => Rule(
        id: m['id'] as int?,
        name: (m['name'] as String?) ?? '',
        deviceAidFilter: m['device_aid_filter'] as int?,
        sensorIdFilter: m['sensor_id_filter'] as String?,
        operator: (m['operator'] as String?) ?? '>',
        threshold: (m['threshold'] as num?)?.toDouble() ?? 0.0,
        actionType: (m['action_type'] as String?) ?? 'create_alert',
        actionPayload: (m['action_payload'] as String?) ?? '{}',
        enabled: (m['enabled'] as int?) == 1,
        cooldownMs: (m['cooldown_ms'] as int?) ?? 60000,
      );

  /// Evaluate condition against a sensor value.
  bool evaluate(double sensorValue) {
    switch (operator) {
      case '>': return sensorValue > threshold;
      case '<': return sensorValue < threshold;
      case '>=': return sensorValue >= threshold;
      case '<=': return sensorValue <= threshold;
      case '==': return sensorValue == threshold;
      case '!=': return sensorValue != threshold;
      default: return false;
    }
  }
}

class OperationLog {
  final int? id;
  final String user;
  final String action;
  final String details;
  final int timestampMs;

  const OperationLog({
    this.id,
    this.user = 'system',
    required this.action,
    this.details = '',
    required this.timestampMs,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user': user,
        'action': action,
        'details': details,
        'timestamp_ms': timestampMs,
      };

  factory OperationLog.fromMap(Map<String, dynamic> m) => OperationLog(
        id: m['id'] as int?,
        user: (m['user'] as String?) ?? 'system',
        action: (m['action'] as String?) ?? '',
        details: (m['details'] as String?) ?? '',
        timestampMs: m['timestamp_ms'] as int,
      );
}

class AppUser {
  final int? id;
  final String username;
  final String passwordHash;
  final String role;
  final int createdMs;

  const AppUser({
    this.id,
    required this.username,
    required this.passwordHash,
    this.role = 'viewer',
    required this.createdMs,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'username': username,
        'password_hash': passwordHash,
        'role': role,
        'created_ms': createdMs,
      };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: m['id'] as int?,
        username: (m['username'] as String?) ?? '',
        passwordHash: (m['password_hash'] as String?) ?? '',
        role: (m['role'] as String?) ?? 'viewer',
        createdMs: (m['created_ms'] as int?) ?? 0,
      );

  bool get isAdmin => role == 'admin';
}

