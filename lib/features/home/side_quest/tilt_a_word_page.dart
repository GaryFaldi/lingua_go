import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/quest_data.dart';
import '../../../data/models/quest_model.dart';
import '../main_quest/quest_provider.dart';

class TiltAWordPage extends StatefulWidget {
  const TiltAWordPage({super.key});

  @override
  State<TiltAWordPage> createState() => _TiltAWordPageState();
}

class _TiltAWordPageState extends State<TiltAWordPage>
    with TickerProviderStateMixin {
  // ── Sensor ────────────────────────────────────────────
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  double _tiltX = 0.0; // kiri/kanan
  double _tiltY = 0.0; // atas/bawah

  // ── Game State ────────────────────────────────────────
  bool _gameStarted = false;
  bool _gamePaused = false;
  bool _gameOver = false;
  int _score = 0;
  int _lives = 3;
  int _round = 0;
  int _timeLeft = 20;
  Timer? _timer;

  // ── Word Logic ────────────────────────────────────────
  VocabItem? _currentVocab;
  late List<_FallingWord> _fallingWords;
  String? _feedbackText;
  Color _feedbackColor = Colors.green;
  bool _showFeedback = false;

  // ── Bucket (player) ───────────────────────────────────
  double _bucketX = 0.5; // 0.0 = kiri, 1.0 = kanan
  static const double _bucketSpeed = 0.015;

  // ── Screen size ───────────────────────────────────────
  double _screenWidth = 400;
  double _screenHeight = 700;

  // ── Animation ─────────────────────────────────────────
  late AnimationController _feedbackAnim;
  late AnimationController _bucketAnim;
  Timer? _gameLoop;

  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _fallingWords = [];

    _feedbackAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _bucketAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _startGyroscope();
  }

  // ── Gyroscope ─────────────────────────────────────────

  void _startGyroscope() {
    _gyroSub = gyroscopeEventStream().listen((event) {
      if (!_gameStarted || _gamePaused || _gameOver) return;

      setState(() {
        // event.y = rotasi kiri/kanan
        _tiltX = event.y.clamp(-5.0, 5.0);
        _tiltY = event.x.clamp(-5.0, 5.0);

        // Gerakkan bucket berdasarkan kemiringan
        _bucketX += (_tiltX / 5.0) * _bucketSpeed * 8;
        _bucketX = _bucketX.clamp(0.05, 0.95);
      });
    });
  }

  // ── Game Control ──────────────────────────────────────

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _gameOver = false;
      _score = 0;
      _lives = 3;
      _round = 0;
      _timeLeft = 20;
      _bucketX = 0.5;
      _fallingWords = [];
    });

    _loadNewVocab();
    _startTimer();
    _startGameLoop();
  }

  void _loadNewVocab() {
    final allVocabs = QuestData.levels.expand((l) => l.vocabs).toList()
      ..shuffle();

    _currentVocab = allVocabs.first;

    // Buat kata-kata yang jatuh: 1 benar + 3 salah
    final wrongVocabs = allVocabs
        .where((v) => v.word != _currentVocab!.word)
        .take(3)
        .toList();

    final allWords = [_currentVocab!, ...wrongVocabs]..shuffle();

    final positions = _generatePositions(allWords.length);

    setState(() {
      _round++;
      _timeLeft = 20;
      _fallingWords = List.generate(
        allWords.length,
        (i) => _FallingWord(
          word: allWords[i].word,
          meaning: allWords[i].meaning,
          isCorrect: allWords[i].word == _currentVocab!.word,
          x: positions[i],
          y: -0.1 - (i * 0.25), // mulai di atas layar
          speed: 0.002 + _rand.nextDouble() * 0.003,
        ),
      );
    });
  }

  List<double> _generatePositions(int count) {
    // Bagi layar jadi zona agar tidak tumpang tindih
    final positions = <double>[];
    final zoneWidth = 0.85 / count;
    for (int i = 0; i < count; i++) {
      final base = 0.08 + (i * zoneWidth);
      positions.add(base + _rand.nextDouble() * zoneWidth * 0.5);
    }
    positions.shuffle();
    return positions;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _onTimeOut();
        }
      });
    });
  }

  void _startGameLoop() {
    _gameLoop?.cancel();
    _gameLoop = Timer.periodic(
      const Duration(milliseconds: 16), // ~60fps
      (_) {
        if (!mounted || !_gameStarted || _gamePaused) return;
        _updateGame();
      },
    );
  }

  void _updateGame() {
    if (_fallingWords.isEmpty) return;

    setState(() {
      bool anyMissed = false;

      for (final word in _fallingWords) {
        if (word.caught || word.missed) continue;

        // Update posisi jatuh
        word.y += word.speed;

        // Cek apakah keluar layar bawah
        if (word.y > 1.1) {
          if (word.isCorrect && !word.caught) {
            word.missed = true;
            anyMissed = true;
          } else {
            word.missed = true;
          }
        }

        // Cek tabrakan dengan bucket
        _checkCatch(word);
      }

      // Jika kata benar lolos (missed)
      if (anyMissed) {
        _onMissCorrectWord();
      }

      // Semua kata sudah ditangkap/lolos → babak baru
      final allDone = _fallingWords.every((w) => w.caught || w.missed);
      if (allDone && _fallingWords.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _gameStarted && !_gameOver) {
            _loadNewVocab();
          }
        });
        _fallingWords = [];
      }
    });
  }

  void _checkCatch(_FallingWord word) {
    if (word.caught || word.missed) return;

    // Area bucket: 10% lebar layar, di bagian bawah
    const bucketWidth = 0.18;
    const bucketY = 0.88;
    const catchZone = 0.08;

    final bucketLeft = _bucketX - bucketWidth / 2;
    final bucketRight = _bucketX + bucketWidth / 2;

    final wordInBucketX = word.x >= bucketLeft && word.x <= bucketRight;
    final wordInBucketY =
        word.y >= bucketY - catchZone && word.y <= bucketY + catchZone;

    if (wordInBucketX && wordInBucketY) {
      word.caught = true;

      if (word.isCorrect) {
        _onCatchCorrect();
      } else {
        _onCatchWrong();
      }
    }
  }

  void _onCatchCorrect() {
    _score += 10 + (_timeLeft * 2); // bonus waktu
    _showFeedbackText('✅ +${10 + (_timeLeft * 2)} poin!', Colors.green);
    _timer?.cancel();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _gameStarted && !_gameOver) {
        _loadNewVocab();
        _startTimer();
      }
    });
    _fallingWords = [];
  }

  void _onCatchWrong() {
    _lives--;
    _showFeedbackText('❌ Salah! -1 nyawa', Colors.red);
    if (_lives <= 0) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _endGame();
      });
    }
  }

  void _onMissCorrectWord() {
    _lives--;
    _showFeedbackText('💨 Kata lolos! -1 nyawa', Colors.orange);
    if (_lives <= 0) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _endGame();
      });
    }
  }

  void _onTimeOut() {
    _timer?.cancel();
    _lives--;
    _showFeedbackText('⏰ Waktu habis! -1 nyawa', Colors.orange);
    if (_lives <= 0) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _endGame();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && _gameStarted && !_gameOver) {
          _loadNewVocab();
          _startTimer();
        }
      });
      _fallingWords = [];
    }
  }

  void _showFeedbackText(String text, Color color) {
    setState(() {
      _feedbackText = text;
      _feedbackColor = color;
      _showFeedback = true;
    });
    _feedbackAnim.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showFeedback = false);
    });
  }

  Future<void> _endGame() async {
    _timer?.cancel();
    _gameLoop?.cancel();

    final quest = context.read<QuestProvider>();
    final xp = _score ~/ 5;
    await quest.addXp(xp);

    if (!mounted) return;
    setState(() => _gameOver = true);
  }

  void _pauseGame() {
    setState(() => _gamePaused = !_gamePaused);
    if (_gamePaused) {
      _timer?.cancel();
      _gameLoop?.cancel();
    } else {
      _startTimer();
      _startGameLoop();
    }
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    _timer?.cancel();
    _gameLoop?.cancel();
    _feedbackAnim.dispose();
    _bucketAnim.dispose();
    super.dispose();
  }

  // ── BUILD ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A2E),
      body: SafeArea(
        child: _gameOver
            ? _buildGameOver()
            : !_gameStarted
            ? _buildStartScreen()
            : _buildGame(),
      ),
    );
  }

  // ── Start Screen ──────────────────────────────────────

  Widget _buildStartScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            const Text('📱', style: TextStyle(fontSize: 70)),
            const SizedBox(height: 16),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFFF97316)],
              ).createShader(bounds),
              child: const Text(
                'Tilt-A-Word',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Miringkan HP untuk menangkap\nkata yang sesuai artinya!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 15),
            ),
            const SizedBox(height: 40),

            // Cara Main
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Column(
                children: [
                  _HowToRow(icon: '👀', text: 'Baca arti kata di bawah'),
                  SizedBox(height: 10),
                  _HowToRow(icon: '📱', text: 'Miringkan HP kiri/kanan'),
                  SizedBox(height: 10),
                  _HowToRow(
                    icon: '🎯',
                    text: 'Tangkap kata yang artinya benar',
                  ),
                  SizedBox(height: 10),
                  _HowToRow(icon: '❌', text: 'Hindari kata yang salah'),
                  SizedBox(height: 10),
                  _HowToRow(icon: '❤️', text: '3 nyawa tersedia'),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Tombol mulai
            GestureDetector(
              onTap: _startGame,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Text(
                  'MULAI GAME',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Game Screen ───────────────────────────────────────

  Widget _buildGame() {
    return Stack(
      children: [
        // ── Starfield background ─────────────────────────
        _buildStarfield(),

        // ── HUD (top bar) ─────────────────────────────────
        Positioned(top: 0, left: 0, right: 0, child: _buildHUD()),

        // ── Arti yang harus ditangkap ─────────────────────
        if (_currentVocab != null)
          Positioned(
            bottom: 90,
            left: 0,
            right: 0,
            child: _buildMeaningPrompt(),
          ),

        // ── Falling words ─────────────────────────────────
        ..._fallingWords
            .where((w) => !w.caught && !w.missed)
            .map((w) => _buildFallingWord(w)),

        // ── Bucket ───────────────────────────────────────
        _buildBucket(),

        // ── Feedback overlay ─────────────────────────────
        if (_showFeedback) _buildFeedback(),

        // ── Pause overlay ─────────────────────────────────
        if (_gamePaused) _buildPauseOverlay(),

        // ── Pause button ──────────────────────────────────
        Positioned(
          top: 70,
          right: 16,
          child: GestureDetector(
            onTap: _pauseGame,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _gamePaused ? Icons.play_arrow : Icons.pause,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // ── Back button ──────────────────────────────────
        Positioned(
          top: 70,
          left: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStarfield() {
    return CustomPaint(
      painter: _StarfieldPainter(),
      size: Size(_screenWidth, _screenHeight),
    );
  }

  Widget _buildHUD() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 60, 8),
      child: Row(
        children: [
          const SizedBox(width: 44),
          // Lives
          Row(
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  i < _lives ? '❤️' : '🖤',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
          const Spacer(),
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '⭐ $_score',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Timer
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _timeLeft <= 5
                  ? Colors.red.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$_timeLeft',
                style: TextStyle(
                  color: _timeLeft <= 5 ? Colors.red : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeaningPrompt() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text(
            'Tangkap kata dengan arti:',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            _currentVocab?.meaning ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallingWord(_FallingWord word) {
    final x = word.x * _screenWidth;
    final y = word.y * _screenHeight;

    return Positioned(
      left: x - 45,
      top: y,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: word.isCorrect
                ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                : [
                    const Color(0xFFEC4899).withOpacity(0.7),
                    const Color(0xFFF97316).withOpacity(0.7),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
                  (word.isCorrect
                          ? const Color(0xFF6366F1)
                          : const Color(0xFFEC4899))
                      .withOpacity(0.4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Text(
          word.word,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildBucket() {
    final x = _bucketX * _screenWidth;
    const bucketWidth = 80.0;

    return Positioned(
      left: x - bucketWidth / 2,
      bottom: 30,
      child: Column(
        children: [
          // Tilt indicator
          Transform.rotate(
            angle: _tiltX * 0.15,
            child: const Text('📱', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 4),
          // Bucket visual
          Container(
            width: bucketWidth,
            height: 20,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedback() {
    return Positioned(
      top: _screenHeight * 0.35,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0).animate(_feedbackAnim),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _feedbackColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              _feedbackText ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⏸️', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            const Text(
              'PAUSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pauseGame,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Lanjutkan'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.exit_to_app, color: Colors.white),
              label: const Text(
                'Keluar',
                style: TextStyle(color: Colors.white),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Game Over Screen ──────────────────────────────────

  Widget _buildGameOver() {
    final quest = context.watch<QuestProvider>();
    final xp = _score ~/ 5;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _score >= 100
                  ? '🏆'
                  : _score >= 50
                  ? '🥈'
                  : '💀',
              style: const TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 16),
            const Text(
              'GAME OVER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),

            // Stats
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  _StatRow(
                    label: 'Skor',
                    value: '$_score',
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 8),
                  _StatRow(
                    label: 'Ronde',
                    value: '${_round - 1}',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  _StatRow(
                    label: 'XP Didapat',
                    value: '+$xp XP',
                    color: Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Tombol
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.replay),
                label: const Text('Main Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: const Text(
                  'Kembali',
                  style: TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white30),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper Classes ────────────────────────────────────────

class _FallingWord {
  final String word;
  final String meaning;
  final bool isCorrect;
  final double x;
  double y;
  final double speed;
  bool caught = false;
  bool missed = false;

  _FallingWord({
    required this.word,
    required this.meaning,
    required this.isCorrect,
    required this.x,
    required this.y,
    required this.speed,
  });
}

class _HowToRow extends StatelessWidget {
  final String icon;
  final String text;
  const _HowToRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 15),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

// ── Starfield Painter ────────────────────────────────────

class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.4);
    final rand = Random(42);
    for (int i = 0; i < 80; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      final r = rand.nextDouble() * 1.5 + 0.5;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
