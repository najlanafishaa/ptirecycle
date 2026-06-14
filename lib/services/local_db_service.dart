import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/parking_history.dart';

class LocalDbService {
  static final LocalDbService instance = LocalDbService._init();
  static Database? _database;

  LocalDbService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('siparku.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE parking_history (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        zoneName TEXT NOT NULL,
        slotCode TEXT NOT NULL,
        checkInTime TEXT NOT NULL,
        checkOutTime TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertParkingHistory(ParkingHistory history) async {
    final db = await instance.database;
    return await db.insert(
      'parking_history',
      history.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ParkingHistory?> getActiveParking(String userId) async {
    final db = await instance.database;
    final maps = await db.query(
      'parking_history',
      where: 'userId = ? AND status = ?',
      whereArgs: [userId, 'Aktif'],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return ParkingHistory.fromMap(maps.first);
    }
    return null;
  }

  Future<List<ParkingHistory>> getHistoryList(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'parking_history',
      where: 'userId = ?',
      orderBy: 'checkInTime DESC',
    );

    return result.map((json) => ParkingHistory.fromMap(json)).toList();
  }

  Future<int> updateParkingHistory(ParkingHistory history) async {
    final db = await instance.database;
    return await db.update(
      'parking_history',
      history.toMap(),
      where: 'id = ?',
      whereArgs: [history.id],
    );
  }

  Future<int> deleteHistoryItem(String id) async {
    final db = await instance.database;
    return await db.delete(
      'parking_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
