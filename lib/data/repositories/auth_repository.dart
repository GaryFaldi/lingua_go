// lib/data/repositories/auth_repository.dart
import 'package:sqflite/sqflite.dart';
import '../local/database_helper.dart';
import '../models/user_model.dart';
import '../../core/utils/hash_helper.dart';

class AuthRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Register user baru
  Future<({bool success, String message})> register({
    required String username,
    required String password,
  }) async {
    try {
      final db = await _dbHelper.database;

      // Cek apakah username sudah ada
      final existing = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      if (existing.isNotEmpty) {
        return (success: false, message: 'Username sudah dipakai!');
      }

      // Pakai username sebagai salt
      final salt = username.toLowerCase();
      final hash = HashHelper.hashPassword(password, salt);

      final user = UserModel(
        username: username,
        passwordHash: hash,
        salt: salt,
        createdAt: DateTime.now(),
      );

      await db.insert(
        'users',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return (success: true, message: 'Registrasi berhasil!');
    } catch (e) {
      return (success: false, message: 'Terjadi kesalahan: $e');
    }
  }

  /// Login user
  Future<({bool success, String message, UserModel? user})> login({
    required String username,
    required String password,
  }) async {
    try {
      final db = await _dbHelper.database;

      final results = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      if (results.isEmpty) {
        return (
          success: false,
          message: 'Username tidak ditemukan!',
          user: null
        );
      }

      final user = UserModel.fromMap(results.first);
      final isValid =
          HashHelper.verifyPassword(password, user.salt, user.passwordHash);

      if (!isValid) {
        return (success: false, message: 'Password salah!', user: null);
      }

      return (success: true, message: 'Login berhasil!', user: user);
    } catch (e) {
      return (success: false, message: 'Terjadi kesalahan: $e', user: null);
    }
  }

  /// Ambil user berdasarkan ID (untuk restore session)
  Future<UserModel?> getUserById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }
}
