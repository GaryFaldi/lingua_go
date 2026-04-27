import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/quest_model.dart';
import '../../../data/local/quest_data.dart';

class QuestProvider extends ChangeNotifier {
  List<QuestLevel> _levels = [];
  int _currentXp = 0;
  int _completedLevels = 0;
  List<VocabItem> _wordBank = [];

  List<QuestLevel> get levels => _levels;
  int get currentXp => _currentXp;
  int get completedLevels => _completedLevels;
  List<VocabItem> get wordBank => _wordBank;
  int get currentLevel => _completedLevels + 1;

  // Level terbuka berdasarkan progress
  bool isLevelUnlocked(int level) => level <= currentLevel;

  QuestProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentXp = prefs.getInt('user_xp') ?? 0;
    _completedLevels = prefs.getInt('completed_levels') ?? 0;

    // Load word bank
    final wordBankKeys = prefs.getStringList('word_bank_words') ?? [];
    final wordBankMeanings = prefs.getStringList('word_bank_meanings') ?? [];

    _wordBank = [];
    for (int i = 0; i < wordBankKeys.length; i++) {
      _wordBank.add(
        VocabItem(
          word: wordBankKeys[i],
          meaning: i < wordBankMeanings.length ? wordBankMeanings[i] : '',
          example: '',
          category: 'saved',
        ),
      );
    }

    _levels = QuestData.levels;
    notifyListeners();
  }

  // Tambah XP setelah selesai level
  Future<void> addXp(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    _currentXp += amount;
    await prefs.setInt('user_xp', _currentXp);
    notifyListeners();
  }

  // Tandai level selesai
  Future<void> completeLevel(int level) async {
    if (level > _completedLevels) {
      final prefs = await SharedPreferences.getInstance();
      _completedLevels = level;
      await prefs.setInt('completed_levels', _completedLevels);
      notifyListeners();
    }
  }

  // Tambah ke Word Bank
  Future<void> addToWordBank(VocabItem vocab) async {
    if (_wordBank.any((v) => v.word == vocab.word)) return;

    _wordBank.add(vocab);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'word_bank_words',
      _wordBank.map((v) => v.word).toList(),
    );
    await prefs.setStringList(
      'word_bank_meanings',
      _wordBank.map((v) => v.meaning).toList(),
    );

    notifyListeners();
  }

  // Hapus dari Word Bank
  Future<void> removeFromWordBank(String word) async {
    _wordBank.removeWhere((v) => v.word == word);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'word_bank_words',
      _wordBank.map((v) => v.word).toList(),
    );
    await prefs.setStringList(
      'word_bank_meanings',
      _wordBank.map((v) => v.meaning).toList(),
    );

    notifyListeners();
  }

  bool isInWordBank(String word) => _wordBank.any((v) => v.word == word);

  // Level title berdasarkan XP
  String get rankTitle {
    if (_currentXp >= 3000) return '🏆 Grand Master';
    if (_currentXp >= 2000) return '💎 Diamond';
    if (_currentXp >= 1000) return '🥇 Gold';
    if (_currentXp >= 500) return '🥈 Silver';
    if (_currentXp >= 100) return '🥉 Bronze';
    return '🌱 Beginner';
  }
}
