// lib/core/utils/hash_helper.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HashHelper {
  // Ambil pepper dari .env
  static String get _pepper => dotenv.env['SECRET_PEPPER'] ?? 'default_pepper';

  /// Hash password dengan SHA-256 + pepper + salt (NIM user sebagai salt)
  static String hashPassword(String password, String salt) {
    final combined = '$password$_pepper$salt';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifikasi password saat login
  static bool verifyPassword(
      String inputPassword, String salt, String storedHash) {
    final inputHash = hashPassword(inputPassword, salt);
    return inputHash == storedHash;
  }
}
