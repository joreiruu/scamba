import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'message_classifications.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE classifications (
            message_id TEXT PRIMARY KEY,
            is_spam INTEGER,
            confidence REAL,
            classified_at INTEGER
          )
        ''');
      },
    );
  }

  Future<Map<String, dynamic>?> getStoredClassification(String messageId) async {
    final db = await database;
    final results = await db.query(
      'classifications',
      where: 'message_id = ?',
      whereArgs: [messageId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> storeClassification(String messageId, bool isSpam, double confidence) async {
    final db = await database;
    await db.insert(
      'classifications',
      {
        'message_id': messageId,
        'is_spam': isSpam ? 1 : 0,
        'confidence': confidence,
        'classified_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}