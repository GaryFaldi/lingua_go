// lib/data/local/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbName = dotenv.env['DB_NAME'] ?? 'linguaquest.db';
    final dbVersion = int.tryParse(dotenv.env['DB_VERSION'] ?? '1') ?? 1;
    final dbPath = join(await getDatabasesPath(), dbName);

    return await openDatabase(dbPath, version: dbVersion, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabel users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        photo_path TEXT,
        xp INTEGER DEFAULT 0,
        current_level INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // Tabel suggestions (kesan & saran TPM)
    await db.execute('''
      CREATE TABLE suggestions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        kesan TEXT,
        saran TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Tabel word_bank (vocab simpanan user)
    await db.execute('''
      CREATE TABLE word_bank (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        word TEXT NOT NULL,
        meaning TEXT,
        added_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
