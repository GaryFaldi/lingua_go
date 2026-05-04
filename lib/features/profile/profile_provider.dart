// lib/features/profile/profile_provider.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/profile_repository.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repo = ProfileRepository();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _biometricEnabled = false;
  String? _photoPath;
  bool _isLoading = false;

  bool get biometricEnabled => _biometricEnabled;
  String? get photoPath => _photoPath;
  bool get isLoading => _isLoading;

  String _biometricKey(int userId) => 'biometric_enabled_$userId';
  String _photoKey(int userId) => 'photo_path_$userId';
  Map<String, dynamic>? _existingSuggestion;
  Map<String, dynamic>? get existingSuggestion => _existingSuggestion;
  bool get hasSuggestion => _existingSuggestion != null;

  Future<void> loadPrefs(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    _biometricEnabled = prefs.getBool(_biometricKey(userId)) ?? false;
    _photoPath = prefs.getString(_photoKey(userId));
    await loadSuggestion(userId); // ← tambah ini
    notifyListeners();
  }

  Future<String?> pickPhoto(ImageSource source, int? userId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return null;

    if (userId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_photoKey(userId), picked.path); // ✅ Key per-user
      await _repo.updatePhotoPath(userId, picked.path);
    }

    _photoPath = picked.path;
    notifyListeners();
    return picked.path;
  }

  Future<bool> toggleBiometric(bool value, int userId) async {
    // ✅ Terima userId
    if (value) {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;

      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Konfirmasi untuk mengaktifkan login sidik jari',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!didAuth) return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey(userId), value); // ✅ Key per-user
    _biometricEnabled = value;
    notifyListeners();
    return true;
  }

  Future<({bool success, String message})> changePassword({
    required int userId,
    required String username,
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      return (success: false, message: 'Password baru tidak cocok!');
    }
    return _repo.changePassword(
      userId: userId,
      username: username,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  // Update saveSuggestion — kalau sudah ada, update; kalau belum, insert
  Future<void> saveSuggestion({
    required int userId,
    required String kesan,
    required String saran,
  }) async {
    if (_existingSuggestion != null) {
      await _repo.updateSuggestion(userId: userId, kesan: kesan, saran: saran);
    } else {
      await _repo.saveSuggestion(userId: userId, kesan: kesan, saran: saran);
    }
    _existingSuggestion = {'kesan': kesan, 'saran': saran};
    notifyListeners();
  }

  Future<void> loadSuggestion(int userId) async {
    _existingSuggestion = await _repo.getSuggestion(userId);
    notifyListeners();
  }
}
