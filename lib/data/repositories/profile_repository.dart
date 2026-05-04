// lib/data/repositories/profile_repository.dart
import '../../data/local/database_helper.dart';
import '../../core/utils/hash_helper.dart';

class ProfileRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> updatePhotoPath(int userId, String path) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      {'photo_path': path},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<({bool success, String message})> changePassword({
    required int userId,
    required String username,
    required String oldPassword,
    required String newPassword,
  }) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (results.isEmpty) {
      return (success: false, message: 'User tidak ditemukan');
    }

    final salt = results.first['salt'] as String;
    final currentHash = results.first['password_hash'] as String;

    if (!HashHelper.verifyPassword(oldPassword, salt, currentHash)) {
      return (success: false, message: 'Password lama salah!');
    }

    final newHash = HashHelper.hashPassword(newPassword, salt);
    await db.update(
      'users',
      {'password_hash': newHash},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return (success: true, message: 'Password berhasil diubah!');
  }

  Future<void> saveSuggestion({
    required int userId,
    required String kesan,
    required String saran,
  }) async {
    final db = await _dbHelper.database;
    await db.insert('suggestions', {
      'user_id': userId,
      'kesan': kesan,
      'saran': saran,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<bool> verifyPassword({
    required int userId,
    required String password,
  }) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (results.isEmpty) return false;

    final salt = results.first['salt'] as String;
    final currentHash = results.first['password_hash'] as String;

    return HashHelper.verifyPassword(password, salt, currentHash);
  }

  Future<Map<String, dynamic>?> getSuggestion(int userId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'suggestions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    return results.isEmpty ? null : results.first;
  }

  Future<void> updateSuggestion({
    required int userId,
    required String kesan,
    required String saran,
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      'suggestions',
      {
        'kesan': kesan,
        'saran': saran,
        'created_at': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
