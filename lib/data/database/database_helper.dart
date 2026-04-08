// SQLite database helper — singleton with versioned migrations.
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/opensynaptic_dashboard.db';
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE devices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        aid INTEGER UNIQUE NOT NULL,
        name TEXT NOT NULL DEFAULT '',
        type TEXT NOT NULL DEFAULT 'sensor',
        lat REAL DEFAULT 0.0,
        lng REAL DEFAULT 0.0,
        status TEXT NOT NULL DEFAULT 'offline',
        transport_type TEXT NOT NULL DEFAULT 'udp',
        last_seen_ms INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sensor_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_aid INTEGER NOT NULL,
        sensor_id TEXT NOT NULL,
        unit TEXT NOT NULL DEFAULT '',
        value REAL NOT NULL,
        raw_b62 TEXT DEFAULT '',
        timestamp_ms INTEGER NOT NULL,
        FOREIGN KEY (device_aid) REFERENCES devices(aid)
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_sensor_data_aid_ts ON sensor_data(device_aid, timestamp_ms)');

    await db.execute('''
      CREATE TABLE alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_aid INTEGER NOT NULL,
        sensor_id TEXT NOT NULL DEFAULT '',
        level INTEGER NOT NULL DEFAULT 0,
        message TEXT NOT NULL DEFAULT '',
        acknowledged INTEGER NOT NULL DEFAULT 0,
        created_ms INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_alerts_aid_level ON alerts(device_aid, level)');

    await db.execute('''
      CREATE TABLE rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL DEFAULT '',
        device_aid_filter INTEGER DEFAULT NULL,
        sensor_id_filter TEXT DEFAULT NULL,
        operator TEXT NOT NULL DEFAULT '>',
        threshold REAL NOT NULL DEFAULT 0.0,
        action_type TEXT NOT NULL DEFAULT 'create_alert',
        action_payload TEXT NOT NULL DEFAULT '{}',
        enabled INTEGER NOT NULL DEFAULT 1,
        cooldown_ms INTEGER NOT NULL DEFAULT 60000
      )
    ''');

    await db.execute('''
      CREATE TABLE operation_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user TEXT NOT NULL DEFAULT 'system',
        action TEXT NOT NULL DEFAULT '',
        details TEXT NOT NULL DEFAULT '',
        timestamp_ms INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'viewer',
        created_ms INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE dashboard_layout (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        layout_json TEXT NOT NULL DEFAULT '{}',
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_commands (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_aid INTEGER NOT NULL,
        frame_hex TEXT NOT NULL,
        created_ms INTEGER NOT NULL
      )
    ''');

    // Insert default admin user (password: admin)
    await db.insert('users', {
      'username': 'admin',
      'password_hash': '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918',
      'role': 'admin',
      'created_ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  /// Get database file size in bytes.
  Future<int> getDatabaseSize() async {
    final db = await database;
    final result = await db.rawQuery('PRAGMA page_count');
    final pageCount = Sqflite.firstIntValue(result) ?? 0;
    final result2 = await db.rawQuery('PRAGMA page_size');
    final pageSize = Sqflite.firstIntValue(result2) ?? 4096;
    return pageCount * pageSize;
  }

  /// Prune old sensor data beyond retention days.
  Future<int> pruneOldData(int retentionDays) async {
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(Duration(days: retentionDays))
        .millisecondsSinceEpoch;
    return db.delete('sensor_data', where: 'timestamp_ms < ?', whereArgs: [cutoff]);
  }
}

