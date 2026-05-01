// lib/data/models/user_model.dart
class UserModel {
  final int? id;
  final String username;
  final String passwordHash;
  final String salt;
  final String? photoPath;
  final int xp;
  final int currentLevel;
  final DateTime createdAt;

  UserModel({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.salt,
    this.photoPath,
    this.xp = 0,
    this.currentLevel = 1,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'salt': salt,
      'photo_path': photoPath,
      'xp': xp,
      'current_level': currentLevel,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      username: map['username'],
      passwordHash: map['password_hash'],
      salt: map['salt'],
      photoPath: map['photo_path'],
      xp: map['xp'] ?? 0,
      currentLevel: map['current_level'] ?? 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
