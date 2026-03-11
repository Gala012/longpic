import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'db_long_pic_entity.dart';
class DbLongPic extends GetxService {
  static DbLongPic get to => Get.find();
  late Database _db;
  static const String _tableName = 'history_records';
  static const int _dbVersion = 1;
  Future<DbLongPic> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'long_pic.db');
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
    return this;
  }
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        thumbnail TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }
  Future<List<HistoryRecord>> getHistoryRecords() async {
    try {
      final maps = await _db.query(
        _tableName,
        orderBy: 'created_at DESC, id DESC',
      );
      return maps.map((m) => HistoryRecord.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }
  Future<int?> insertHistoryRecord(HistoryRecord record) async {
    try {
      final id = await _db.insert(_tableName, record.toMap());
      return id;
    } catch (e) {
      return null;
    }
  }
  Future<bool> updateHistoryRecord(int id, String title) async {
    try {
      final count = await _db.update(
        _tableName,
        {'title': title},
        where: 'id = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }
  Future<bool> deleteHistoryRecord(int id) async {
    try {
      final count = await _db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }
  Future<bool> deleteHistoryRecords(List<int> ids) async {
    try {
      final placeholders = ids.map((_) => '?').join(',');
      final count = await _db.delete(
        _tableName,
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }
  Future<bool> clearAllHistoryRecords() async {
    try {
      await _db.delete(_tableName);
      return true;
    } catch (e) {
      return false;
    }
  }
}
