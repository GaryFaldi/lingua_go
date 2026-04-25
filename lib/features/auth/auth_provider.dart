// lib/features/auth/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/hash_helper.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();
  final LocalAuthentication _localAuth = LocalAuthentication();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _lockedUsername;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  String? get lockedUsername => _lockedUsername;

  // ── Session ──────────────────────────────────────────────
  Future<void> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId != null) {
      // Jangan restore _currentUser langsung!
      // Cukup set _lockedUsername supaya masuk LockScreen dulu
      _lockedUsername = prefs.getString('locked_username') ?? 'Pengguna';
      notifyListeners();
    }
    // Kalau tidak ada userId sama sekali → LoginPage (lockedUsername tetap null)
  }

  Future<void> _saveSession(int userId, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
    await prefs.setString('locked_username', username);
  }

  // ── Register ─────────────────────────────────────────────
  Future<bool> register(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repo.register(username: username, password: password);

    _isLoading = false;
    if (!result.success) _errorMessage = result.message;
    notifyListeners();
    return result.success;
  }

  // ── Login ─────────────────────────────────────────────────
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repo.login(username: username, password: password);

    _isLoading = false;
    if (result.success && result.user != null) {
      _currentUser = result.user;
      _lockedUsername = null;
      await _saveSession(result.user!.id!, result.user!.username);
    } else {
      _errorMessage = result.message;
    }
    notifyListeners();
    return result.success;
  }

  // ── Unlock dengan Password (LockScreen) ───────────────────
  Future<bool> unlockWithPassword(String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      _errorMessage = 'Sesi tidak ditemukan';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final user = await _repo.getUserById(userId);
    if (user == null) {
      _errorMessage = 'User tidak ditemukan';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final isValid = HashHelper.verifyPassword(
      password,
      user.salt,
      user.passwordHash,
    );
    if (!isValid) {
      _errorMessage = 'Password salah!';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _currentUser = user;
    _lockedUsername = null;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  // ── Biometric Login ───────────────────────────────────────
  Future<bool> loginWithBiometric() async {
    try {
      final bool canAuth = await _localAuth.canCheckBiometrics;
      if (!canAuth) {
        _errorMessage = 'Perangkat tidak mendukung biometrik';
        notifyListeners();
        return false;
      }

      final bool didAuth = await _localAuth.authenticate(
        localizedReason: 'Gunakan sidik jari untuk masuk ke LinguaQuest',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuth) {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('user_id');
        if (userId != null) {
          _currentUser = await _repo.getUserById(userId);
          _lockedUsername = null;
          notifyListeners();
          return true;
        } else {
          _errorMessage =
              'Belum ada sesi tersimpan. Login dengan password dulu.';
          notifyListeners();
          return false;
        }
      }
      return false;
    } catch (e) {
      _errorMessage = 'Biometrik gagal: $e';
      notifyListeners();
      return false;
    }
  }

  // ── Logout → LockScreen ───────────────────────────────────
  Future<void> logout() async {
    _lockedUsername = _currentUser?.username;
    _currentUser = null;
    notifyListeners();
  }

  // ── Logout Permanen → LoginPage ───────────────────────────
  Future<void> logoutAndClearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('locked_username');
    _currentUser = null;
    _lockedUsername = null;
    notifyListeners();
  }
}
