import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    return openDatabase(
      join(path, 'local_app_data.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sync_metadata(
            data_type TEXT PRIMARY KEY,
            last_sync_time INTEGER
          )
        ''');
      },
      version: 1,
    );
  }

  Future<DateTime?> getLastSyncTime(String dataType) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'sync_metadata',
      where: 'data_type = ?',
      whereArgs: [dataType],
    );
    
    if (result.isNotEmpty && result.first['last_sync_time'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(
          result.first['last_sync_time']);
    }
    return null;
  }

  Future<void> updateLastSyncTime(String dataType, DateTime time) async {
    final db = await database;
    await db.insert(
      'sync_metadata',
      {
        'data_type': dataType,
        'last_sync_time': time.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}