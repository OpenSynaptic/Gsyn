/// Repositories — typed CRUD over sqflite.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gsyn/data/database/database_helper.dart';
import 'package:gsyn/data/models/models.dart';

// ─── Device Repository ───

class DeviceRepository {
  final _db = DatabaseHelper.instance;

  Future<void> upsertDevice(Device device) async {
    final db = await _db.database;
    final existing = await db.query(
      'devices',
      where: 'aid = ?',
      whereArgs: [device.aid],
    );
    if (existing.isEmpty) {
      await db.insert('devices', device.toMap());
    } else {
      await db.update(
        'devices',
        device.toMap(),
        where: 'aid = ?',
        whereArgs: [device.aid],
      );
    }
  }

  Future<List<Device>> getAllDevices() async {
    final db = await _db.database;
    final rows = await db.query('devices', orderBy: 'last_seen_ms DESC');
    return rows.map((r) => Device.fromMap(r)).toList();
  }

  Future<Device?> getDeviceByAid(int aid) async {
    final db = await _db.database;
    final rows = await db.query('devices', where: 'aid = ?', whereArgs: [aid]);
    return rows.isEmpty ? null : Device.fromMap(rows.first);
  }

  Future<int> getOnlineCount() async {
    final db = await _db.database;
    final cutoff = DateTime.now()
        .subtract(const Duration(minutes: 5))
        .millisecondsSinceEpoch;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM devices WHERE last_seen_ms > ?',
      [cutoff],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  Future<int> getTotalCount() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM devices');
    return (result.first['c'] as int?) ?? 0;
  }
}

// ─── Sensor Data Repository ───

class SensorDataRepository {
  final _db = DatabaseHelper.instance;

  Future<void> insertReading(SensorData data) async {
    final db = await _db.database;
    await db.insert('sensor_data', data.toMap());
  }

  Future<void> insertBatch(List<SensorData> batch) async {
    final db = await _db.database;
    final b = db.batch();
    for (final d in batch) {
      b.insert('sensor_data', d.toMap());
    }
    await b.commit(noResult: true);
  }

  Future<List<SensorData>> query({
    int? deviceAid,
    String? sensorId,
    int? fromMs,
    int? toMs,
    int limit = 500,
  }) async {
    final db = await _db.database;
    final where = <String>[];
    final args = <dynamic>[];

    if (deviceAid != null) {
      where.add('device_aid = ?');
      args.add(deviceAid);
    }
    if (sensorId != null) {
      where.add('sensor_id = ?');
      args.add(sensorId);
    }
    if (fromMs != null) {
      where.add('timestamp_ms >= ?');
      args.add(fromMs);
    }
    if (toMs != null) {
      where.add('timestamp_ms <= ?');
      args.add(toMs);
    }

    final rows = await db.query(
      'sensor_data',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'timestamp_ms DESC',
      limit: limit,
    );
    return rows.map((r) => SensorData.fromMap(r)).toList();
  }

  /// Get the latest reading per sensor for a device.
  Future<List<SensorData>> getLatestByDevice(int deviceAid) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT * FROM sensor_data WHERE id IN (
        SELECT MAX(id) FROM sensor_data WHERE device_aid = ? GROUP BY sensor_id
      )
    ''',
      [deviceAid],
    );
    return rows.map((r) => SensorData.fromMap(r)).toList();
  }
}

// ─── Alert Repository ───

class AlertRepository {
  final _db = DatabaseHelper.instance;

  Future<int> insert(Alert alert) async {
    final db = await _db.database;
    return db.insert('alerts', alert.toMap());
  }

  Future<List<Alert>> getAlerts({
    int? level,
    bool? acknowledged,
    int limit = 100,
  }) async {
    final db = await _db.database;
    final where = <String>[];
    final args = <dynamic>[];

    if (level != null) {
      where.add('level = ?');
      args.add(level);
    }
    if (acknowledged != null) {
      where.add('acknowledged = ?');
      args.add(acknowledged ? 1 : 0);
    }

    final rows = await db.query(
      'alerts',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_ms DESC',
      limit: limit,
    );
    return rows.map((r) => Alert.fromMap(r)).toList();
  }

  Future<void> acknowledge(int id) async {
    final db = await _db.database;
    await db.update(
      'alerts',
      {'acknowledged': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getUnacknowledgedCount() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM alerts WHERE acknowledged = 0',
    );
    return (result.first['c'] as int?) ?? 0;
  }
}

// ─── Rule Repository ───

class RuleRepository {
  final _db = DatabaseHelper.instance;

  Future<int> insert(Rule rule) async {
    final db = await _db.database;
    return db.insert('rules', rule.toMap());
  }

  Future<void> update(Rule rule) async {
    final db = await _db.database;
    await db.update(
      'rules',
      rule.toMap(),
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('rules', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Rule>> getAllRules() async {
    final db = await _db.database;
    final rows = await db.query('rules', orderBy: 'id ASC');
    return rows.map((r) => Rule.fromMap(r)).toList();
  }

  Future<List<Rule>> getEnabledRules() async {
    final db = await _db.database;
    final rows = await db.query('rules', where: 'enabled = 1');
    return rows.map((r) => Rule.fromMap(r)).toList();
  }

  Future<void> toggleEnabled(int id, bool enabled) async {
    final db = await _db.database;
    await db.update(
      'rules',
      {'enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

// ─── Operation Log Repository ───

class OperationLogRepository {
  final _db = DatabaseHelper.instance;

  Future<void> log(
    String action, {
    String user = 'system',
    String details = '',
  }) async {
    final db = await _db.database;
    await db.insert('operation_logs', {
      'user': user,
      'action': action,
      'details': details,
      'timestamp_ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<OperationLog>> query({int limit = 200}) async {
    final db = await _db.database;
    final rows = await db.query(
      'operation_logs',
      orderBy: 'timestamp_ms DESC',
      limit: limit,
    );
    return rows.map((r) => OperationLog.fromMap(r)).toList();
  }
}

// ─── Riverpod providers ───

final deviceRepositoryProvider = Provider((_) => DeviceRepository());
final sensorDataRepositoryProvider = Provider((_) => SensorDataRepository());
final alertRepositoryProvider = Provider((_) => AlertRepository());
final ruleRepositoryProvider = Provider((_) => RuleRepository());
final operationLogRepositoryProvider = Provider(
  (_) => OperationLogRepository(),
);
