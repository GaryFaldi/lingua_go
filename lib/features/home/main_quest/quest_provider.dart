// lib/features/home/main_quest/quest_provider.dart
import 'package:flutter/material.dart';
import '../../../data/models/quest_model.dart';
import '../../../data/local/quest_data.dart';
import '../../../data/local/database_helper.dart';

class QuestProvider extends ChangeNotifier {
  final int userId; // <-- wajib tahu siapa usernya
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<QuestLevel> _levels = [];
  int _currentXp = 0;
  int _completedLevels = 0;
  List<VocabItem> _wordBank = [];
  bool _isLoading = true;

  List<QuestLevel> get levels => _levels;
  int get currentXp => _currentXp;
  int get completedLevels => _completedLevels;
  List<VocabItem> get wordBank => _wordBank;
  int get currentLevel => _completedLevels + 1;
  bool get isLoading => _isLoading;
  bool isLevelUnlocked(int level) => level <= currentLevel;

  QuestProvider({required this.userId}) {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final progress = await _db.getQuestProgress(userId);
      _currentXp = progress['xp']!;
      _completedLevels = progress['completed_levels']!;

      final rows = await _db.getWordBank(userId);
      _wordBank = rows
          .map(
            (row) => VocabItem(
              word: row['word'] as String,
              meaning: row['meaning'] as String? ?? '',
              example: row['example'] as String? ?? '',
              category: row['category'] as String? ?? 'saved',
            ),
          )
          .toList();

      _levels = QuestData.levels;
    } catch (e) {
      debugPrint('QuestProvider _init error: $e'); // ← lihat di console
    } finally {
      _isLoading = false; // ← SELALU jalan, error atau tidak
      notifyListeners();
    }
  }

  // Tambah XP setelah selesai level
  Future<void> addXp(int amount) async {
    _currentXp += amount;
    debugPrint('addXp: userId=$userId, newXp=$_currentXp'); // ← tambah
    await _db.updateProgress(userId, _currentXp, _completedLevels);
    notifyListeners();
  }

  // Tandai level selesai
  Future<void> completeLevel(int level) async {
    if (level > _completedLevels) {
      _completedLevels = level;
      await _db.updateProgress(userId, _currentXp, _completedLevels);
      notifyListeners();
    }
  }

  // Tambah ke Word Bank
  Future<void> addToWordBank(VocabItem vocab) async {
    if (_wordBank.any((v) => v.word == vocab.word)) return;

    _wordBank.add(vocab);
    await _db.addWordToBank(
      userId,
      word: vocab.word,
      meaning: vocab.meaning,
      example: vocab.example,
      category: vocab.category,
    );
    debugPrint('addToWordBank: "${vocab.word}" disimpan untuk userId=$userId');
    notifyListeners();
  }

  // Hapus dari Word Bank
  Future<void> removeFromWordBank(String word) async {
    _wordBank.removeWhere((v) => v.word == word);
    await _db.removeWordFromBank(userId, word);
    notifyListeners();
  }

  bool isInWordBank(String word) => _wordBank.any((v) => v.word == word);

  // Rank berdasarkan XP
  String get rankTitle {
    if (_currentXp >= 3000) return '🏆 Grand Master';
    if (_currentXp >= 2000) return '💎 Diamond';
    if (_currentXp >= 1000) return '🥇 Gold';
    if (_currentXp >= 500) return '🥈 Silver';
    if (_currentXp >= 100) return '🥉 Bronze';
    return '🌱 Beginner';
  }
}
