// lib/features/quest/presentation/spell_correction_model.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

/// Naive Bayes Spell Correction Model
///
/// Model ini TIDAK di-train di Dart, melainkan di-load dari parameter
/// hasil training Python (train_spell_model.ipynb) yang diekspor ke JSON.
///
/// Alur:
///   [Python Notebook] → train → export spell_model.json
///                                       ↓
///   [Flutter] → loadModel() → baca JSON → inferensi Naive Bayes
class NaiveBayesSpellModel {
  // ── Model Parameters (diisi saat loadModel()) ───────────────────────────────

  /// Prior probability P(correct_word) dari training Python
  Map<String, double> _prior = {};

  /// Likelihood P(length_diff | word) dari training Python
  Map<String, Map<String, double>> _lengthLikelihood = {};

  /// Likelihood P(char_overlap | word) dari training Python
  Map<String, Map<String, double>> _charLikelihood = {};

  /// Threshold posterior (dari metadata JSON)
  double _threshold = -10.0;

  bool _isLoaded = false;

  // ── Load Model dari Asset ────────────────────────────────────────────────────

  /// Load parameter model dari `assets/models/spell_model.json`.
  /// Wajib dipanggil sekali sebelum [predictCorrection].
  ///
  /// Contoh pemanggilan di initState:
  /// ```dart
  /// await _spellModel.loadModel();
  /// ```
  Future<void> loadModel() async {
    if (_isLoaded) return;

    // Baca file JSON dari Flutter assets
    final raw = await rootBundle.loadString('assets/models/spell_model.json');
    final Map<String, dynamic> json = jsonDecode(raw);

    // Ambil threshold dari metadata
    final metadata = json['metadata'] as Map<String, dynamic>;
    _threshold = (metadata['threshold'] as num).toDouble();

    // Parse prior: { "hello": 0.025, ... }
    _prior = (json['prior'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );

    // Parse length_likelihood: { "hello": { "1": 0.4, "2": 0.3 }, ... }
    _lengthLikelihood =
        (json['length_likelihood'] as Map<String, dynamic>).map(
      (word, distRaw) => MapEntry(
        word,
        (distRaw as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
    );

    // Parse char_likelihood: { "hello": { "3": 0.5, "4": 0.3 }, ... }
    _charLikelihood = (json['char_likelihood'] as Map<String, dynamic>).map(
      (word, distRaw) => MapEntry(
        word,
        (distRaw as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
    );

    _isLoaded = true;
  }

  // ── Helper ───────────────────────────────────────────────────────────────────

  /// Hitung jumlah karakter unik yang sama (case-insensitive)
  int _countCharOverlap(String a, String b) {
    final setA = a.toLowerCase().split('').toSet();
    final setB = b.toLowerCase().split('').toSet();
    return setA.intersection(setB).length;
  }

  // ── Inferensi: Log-Posterior P(correct | input) ──────────────────────────────

  double _posteriorLog(String input, String candidateKey) {
    // Prior — fallback jika kata tidak ada di model
    final prior = _prior[candidateKey] ?? (1.0 / (_prior.length + 1));
    double logProb = log(prior);

    // Feature 1: length difference
    final lengthDiff = (input.length - candidateKey.length).abs().toString();
    final lengthProb = _lengthLikelihood[candidateKey]?[lengthDiff] ?? 0.1;
    logProb += log(lengthProb);

    // Feature 2: char overlap
    final overlap = _countCharOverlap(input, candidateKey).toString();
    final charProb = _charLikelihood[candidateKey]?[overlap] ?? 0.05;
    logProb += log(charProb);

    return logProb;
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Prediksi apakah [input] adalah typo dari [correctWord].
  ///
  /// Signature identik dengan _getSpellSuggestion sebelumnya:
  /// - Return [correctWord] jika terdeteksi typo
  /// - Return null jika jawaban memang salah (bukan typo)
  ///
  /// Pastikan [loadModel()] sudah dipanggil sebelum fungsi ini.
  String? predictCorrection(String input, String correctWord) {
    assert(_isLoaded, 'Panggil loadModel() sebelum predictCorrection()');

    final inputLower   = input.toLowerCase();
    final correctLower = correctWord.toLowerCase();

    if (inputLower == correctLower) return null;

    final score = _posteriorLog(inputLower, correctLower);
    return score > _threshold ? correctWord : null;
  }
}
