import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../data/local/quest_data.dart';
import '../../../data/models/quest_model.dart';
import '../main_quest/quest_provider.dart';

class ShakeChallengePage extends StatefulWidget {
  const ShakeChallengePage({super.key});

  @override
  State<ShakeChallengePage> createState() => _ShakeChallengePageState();
}

class _ShakeChallengePageState extends State<ShakeChallengePage>
    with SingleTickerProviderStateMixin {
  StreamSubscription<AccelerometerEvent>? _sub;
  late AnimationController _shakeAnim;

  // State
  bool _isWaitingShake = true;
  bool _quizActive = false;
  bool _answered = false;
  bool _isCorrect = false;
  int _score = 0;
  int _round = 0;
  static const int _maxRounds = 5;

  VocabItem? _currentVocab;
  List<String> _options = [];
  final _rand = Random();

  // Shake detection
  double _lastX = 0, _lastY = 0, _lastZ = 0;
  static const double _shakeThreshold = 15.0;
  DateTime _lastShake = DateTime.now();

  @override
  void initState() {
    super.initState();
    _shakeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _startListening();
  }

  void _startListening() {
    _sub = accelerometerEventStream().listen((event) {
      final now = DateTime.now();
      if (now.difference(_lastShake).inMilliseconds < 1000) return;

      final dx = (event.x - _lastX).abs();
      final dy = (event.y - _lastY).abs();
      final dz = (event.z - _lastZ).abs();

      if ((dx + dy + dz) > _shakeThreshold) {
        _lastShake = now;
        _onShake();
      }

      _lastX = event.x;
      _lastY = event.y;
      _lastZ = event.z;
    });
  }

  void _onShake() {
    if (!_isWaitingShake) return;
    _shakeAnim.forward(from: 0);
    _loadNextQuiz();
  }

  void _loadNextQuiz() {
    // Ambil semua vocab dari semua level
    final allVocabs = QuestData.levels.expand((l) => l.vocabs).toList();

    allVocabs.shuffle();
    final vocab = allVocabs.first;

    // Buat 4 pilihan jawaban
    final wrongOptions = allVocabs.where((v) => v.word != vocab.word).toList()
      ..shuffle();

    final options = [vocab.meaning];
    for (int i = 0; i < 3 && i < wrongOptions.length; i++) {
      options.add(wrongOptions[i].meaning);
    }
    options.shuffle();

    setState(() {
      _currentVocab = vocab;
      _options = options;
      _isWaitingShake = false;
      _quizActive = true;
      _answered = false;
    });
  }

  void _answerQuestion(String selected) {
    if (_answered) return;
    final correct = _currentVocab!.meaning;
    final isCorrect = selected == correct;

    setState(() {
      _answered = true;
      _isCorrect = isCorrect;
      if (isCorrect) _score += 10;
      _round++;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_round >= _maxRounds) {
        _showResult();
      } else {
        setState(() {
          _isWaitingShake = true;
          _quizActive = false;
        });
      }
    });
  }

  Future<void> _showResult() async {
    final quest = context.read<QuestProvider>();
    final xp = _score ~/ 2;
    await quest.addXp(xp);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _score >= 40
                  ? '🏆'
                  : _score >= 20
                  ? '🎯'
                  : '💪',
              style: const TextStyle(fontSize: 60),
            ),
            const SizedBox(height: 8),
            Text(
              'Skor: $_score/${_maxRounds * 10}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '+$xp XP didapat!',
              style: const TextStyle(color: Colors.amber),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Selesai'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _shakeAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1B4B),
      appBar: AppBar(
        title: const Text(
          'Shake Challenge! 🎲',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isWaitingShake ? _buildShakePrompt() : _buildQuiz(),
    );
  }

  Widget _buildShakePrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Score & Round info
          if (_round > 0) ...[
            Text(
              'Ronde $_round/$_maxRounds',
              style: const TextStyle(color: Colors.white60, fontSize: 16),
            ),
            Text(
              'Skor: $_score',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
          ],

          // Shake animation
          AnimatedBuilder(
            animation: _shakeAnim,
            builder: (_, child) {
              final offset = sin(_shakeAnim.value * pi * 4) * 10;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: const Text('📱', style: TextStyle(fontSize: 80)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Guncang HP kamu!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _round == 0 ? 'Untuk memulai kuis kilat' : 'Untuk soal berikutnya',
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 30),

          // Manual button (jika sensor tidak berfungsi)
          OutlinedButton.icon(
            onPressed: _loadNextQuiz,
            icon: const Icon(Icons.touch_app, color: Colors.white),
            label: const Text(
              'Tap jika sensor tidak berfungsi',
              style: TextStyle(color: Colors.white),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    if (_currentVocab == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Progress
          LinearProgressIndicator(
            value: _round / _maxRounds,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ronde ${_round + 1}/$_maxRounds',
                style: const TextStyle(color: Colors.white60),
              ),
              Text(
                'Skor: $_score',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Pertanyaan
          Text(
            'Apa artinya:',
            style: const TextStyle(color: Colors.white60, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            _currentVocab!.word,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_currentVocab!.pronunciation.isNotEmpty)
            Text(
              '[${_currentVocab!.pronunciation}]',
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
          const SizedBox(height: 40),

          // Pilihan jawaban
          ..._options.map((opt) {
            Color btnColor = Colors.white.withOpacity(0.1);
            Color textColor = Colors.white;

            if (_answered) {
              if (opt == _currentVocab!.meaning) {
                btnColor = Colors.green;
              } else if (!_isCorrect && _answered) {
                btnColor = Colors.red.withOpacity(0.3);
              }
            }

            return GestureDetector(
              onTap: () => _answerQuestion(opt),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: btnColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Text(
                  opt,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }),

          // Feedback
          if (_answered) ...[
            const SizedBox(height: 12),
            Text(
              _isCorrect
                  ? '✅ Benar! +10 XP'
                  : '❌ Salah! Jawaban: ${_currentVocab!.meaning}',
              style: TextStyle(
                color: _isCorrect ? Colors.green : Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
