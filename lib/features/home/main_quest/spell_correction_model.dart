import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class NaiveBayesSpellModel {
  Map<String, double> _prior = {};
  Map<String, Map<String, double>> _lengthLikelihood = {};
  Map<String, Map<String, double>> _charLikelihood = {};
  double _threshold = -6.5;
  bool _isLoaded = false;

  Future<void> loadModel() async {
    if (_isLoaded) return;

    final raw = await rootBundle.loadString('assets/models/spell_model.json');
    final Map<String, dynamic> json = jsonDecode(raw);

    _threshold = (json['metadata']['threshold'] as num).toDouble();

    _prior = (json['prior'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );

    _lengthLikelihood = (json['length_likelihood'] as Map<String, dynamic>).map(
      (word, distRaw) => MapEntry(
        word,
        (distRaw as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
    );

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

  int _countCharOverlap(String a, String b) {
    final setA = a.toLowerCase().split('').toSet();
    final setB = b.toLowerCase().split('').toSet();
    return setA.intersection(setB).length;
  }

  double _posteriorLog(String input, String candidateKey) {
    final prior = _prior[candidateKey] ?? (1.0 / (_prior.length + 1));
    double logProb = log(prior);

    final lengthDiff = (input.length - candidateKey.length).abs().toString();
    final lengthProb = _lengthLikelihood[candidateKey]?[lengthDiff] ?? 0.1;
    logProb += log(lengthProb);

    final overlap = _countCharOverlap(input, candidateKey).toString();
    final charProb = _charLikelihood[candidateKey]?[overlap] ?? 0.05;
    logProb += log(charProb);

    return logProb;
  }

  String? predictCorrection(String input, String correctWord) {
    if (!_isLoaded) return null;

    final inputLower = input.toLowerCase();
    final correctLower = correctWord.toLowerCase();

    if (inputLower == correctLower) return null;

    final score = _posteriorLog(inputLower, correctLower);
    return score > _threshold ? correctWord : null;
  }
}
