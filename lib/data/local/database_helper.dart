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

    // Tabel word_bank (vocab simpanan per user)
    await db.execute('''
      CREATE TABLE word_bank (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        word TEXT NOT NULL,
        meaning TEXT,
        example TEXT,
        category TEXT,
        added_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id),
        UNIQUE(user_id, word)
      )
    ''');

    // Tabel quest_progress (progress level per user)
    await db.execute('''
      CREATE TABLE quest_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        xp INTEGER DEFAULT 0,
        completed_levels INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');
  }

  // ── Quest Progress ──────────────────────────────────────

  /// Ambil XP dan completed_levels milik user tertentu
  Future<Map<String, int>> getQuestProgress(int userId) async {
    final db = await database;
    final result = await db.query(
      'quest_progress',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (result.isEmpty) {
      return {'xp': 0, 'completed_levels': 0};
    }
    return {
      'xp': result.first['xp'] as int,
      'completed_levels': result.first['completed_levels'] as int,
    };
  }

  /// Simpan atau update XP user
  Future<void> updateXp(int userId, int newXp) async {
    final db = await database;
    await db.insert('quest_progress', {
      'user_id': userId,
      'xp': newXp,
      'completed_levels': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    // Kalau sudah ada row, update saja xp-nya
    await db.rawUpdate('UPDATE quest_progress SET xp = ? WHERE user_id = ?', [
      newXp,
      userId,
    ]);
  }

  /// Simpan atau update completed_levels user
  Future<void> updateCompletedLevels(int userId, int completedLevels) async {
    final db = await database;
    // Pastikan row ada dulu
    final existing = await db.query(
      'quest_progress',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (existing.isEmpty) {
      await db.insert('quest_progress', {
        'user_id': userId,
        'xp': 0,
        'completed_levels': completedLevels,
      });
    } else {
      await db.update(
        'quest_progress',
        {'completed_levels': completedLevels},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }
  }

  /// Update XP dan completed_levels sekaligus (atomic)
  Future<void> updateProgress(int userId, int xp, int completedLevels) async {
    final db = await database;
    final existing = await db.query(
      'quest_progress',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (existing.isEmpty) {
      await db.insert('quest_progress', {
        'user_id': userId,
        'xp': xp,
        'completed_levels': completedLevels,
      });
    } else {
      await db.update(
        'quest_progress',
        {'xp': xp, 'completed_levels': completedLevels},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }
  }

  // ── Word Bank ────────────────────────────────────────────

  /// Ambil semua word bank milik user tertentu
  Future<List<Map<String, dynamic>>> getWordBank(int userId) async {
    final db = await database;
    return await db.query(
      'word_bank',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'added_at DESC',
    );
  }

  /// Tambah kata ke word bank (ignore kalau sudah ada)
  Future<void> addWordToBank(
    int userId, {
    required String word,
    required String meaning,
    required String example,
    required String category,
  }) async {
    final db = await database;
    await db.insert(
      'word_bank',
      {
        'user_id': userId,
        'word': word,
        'meaning': meaning,
        'example': example,
        'category': category,
        'added_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore, // skip kalau duplikat
    );
  }

  /// Hapus kata dari word bank
  Future<void> removeWordFromBank(int userId, String word) async {
    final db = await database;
    await db.delete(
      'word_bank',
      where: 'user_id = ? AND word = ?',
      whereArgs: [userId, word],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
