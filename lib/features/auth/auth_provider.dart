// lib/features/auth/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();
  final LocalAuthentication _localAuth = LocalAuthentication();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  // ── Session ──────────────────────────────────────────────
  Future<void> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId != null) {
      _currentUser = await _repo.getUserById(userId);
      notifyListeners();
    }
  }

  Future<void> _saveSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }

  // ── Register ─────────────────────────────────────────────
  Future<bool> register(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repo.register(username: username, password: password);

    _isLoading = false;
    if (!result.success) {
      _errorMessage = result.message;
    }
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
      await _saveSession(result.user!.id!);
    } else {
      _errorMessage = result.message;
    }
    notifyListeners();
    return result.success;
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
        // Restore session dari SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('user_id');
        if (userId != null) {
          _currentUser = await _repo.getUserById(userId);
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

  // ── Logout ────────────────────────────────────────────────
  //   Future<void> logout() async {
  //   // Jangan hapus user_id! Biarkan tersimpan untuk biometrik
  //   _currentUser = null;
  //   notifyListeners();
  // }

  // Kalau mau benar-benar hapus sesi (misal ganti akun)
  Future<void> logoutAndClearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    _currentUser = null;
    notifyListeners();
  }
}
