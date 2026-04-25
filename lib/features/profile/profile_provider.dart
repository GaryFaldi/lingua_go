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

  Future<void> loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    _photoPath = prefs.getString('photo_path');
    notifyListeners();
  }

  Future<String?> pickPhoto(ImageSource source, int? userId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('photo_path', picked.path);

    if (userId != null) {
      await _repo.updatePhotoPath(userId, picked.path);
    }

    _photoPath = picked.path;
    notifyListeners();
    return picked.path;
  }

  Future<bool> toggleBiometric(bool value) async {
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
    await prefs.setBool('biometric_enabled', value);
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

  Future<void> saveSuggestion({
    required int userId,
    required String kesan,
    required String saran,
  }) async {
    await _repo.saveSuggestion(userId: userId, kesan: kesan, saran: saran);
  }
}
