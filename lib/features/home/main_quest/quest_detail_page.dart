import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/quest_model.dart';
import 'quest_provider.dart';

class QuestDetailPage extends StatefulWidget {
  final QuestLevel level;
  const QuestDetailPage({super.key, required this.level});

  @override
  State<QuestDetailPage> createState() => _QuestDetailPageState();
}

class _QuestDetailPageState extends State<QuestDetailPage> {
  int _currentIndex = 0;
  final _answerCtrl = TextEditingController();
  String _feedback = '';
  bool _isCorrect = false;
  bool _answered = false;
  int _correctCount = 0;

  // ── ML Auto-Correction ────────────────────────────────

  // Hitung Levenshtein distance untuk spell checking
  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final d = List.generate(
      s.length + 1,
      (i) => List.generate(t.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s.length; i++) d[i][0] = i;
    for (int j = 0; j <= t.length; j++) d[0][j] = j;

    for (int i = 1; i <= s.length; i++) {
      for (int j = 1; j <= t.length; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1,
          d[i][j - 1] + 1,
          d[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return d[s.length][t.length];
  }

  // Cek jawaban dengan ML auto-correction
  String? _getSpellSuggestion(String input, String correct) {
    final distance = _levenshtein(input.toLowerCase(), correct.toLowerCase());
    // Jika jarak 1-2 karakter = typo, beri saran
    if (distance > 0 && distance <= 2) return correct;
    return null;
  }

  void _checkAnswer() {
    final vocab = widget.level.vocabs[_currentIndex];
    final input = _answerCtrl.text.trim();
    if (input.isEmpty) return;

    final correct = vocab.word.toLowerCase();
    final userInput = input.toLowerCase();

    setState(() {
      _answered = true;
      if (userInput == correct) {
        _isCorrect = true;
        _feedback = '✅ Benar! Bagus sekali!';
        _correctCount++;
      } else {
        _isCorrect = false;
        final suggestion = _getSpellSuggestion(userInput, vocab.word);
        if (suggestion != null) {
          // ML: Deteksi typo dan beri saran
          _feedback =
              '🤔 Hampir benar! Maksud kamu "$suggestion"?\n'
              'Jawaban yang benar: ${vocab.word}';
        } else {
          _feedback = '❌ Salah. Jawaban: ${vocab.word}';
        }
      }
    });
  }

  void _nextVocab() {
    if (_currentIndex < widget.level.vocabs.length - 1) {
      setState(() {
        _currentIndex++;
        _answerCtrl.clear();
        _feedback = '';
        _answered = false;
        _isCorrect = false;
      });
    } else {
      _showCompletionDialog();
    }
  }

  Future<void> _showCompletionDialog() async {
    final quest = context.read<QuestProvider>();
    final xp = widget.level.xpReward;

    // Tambah XP dan tandai level selesai
    await quest.addXp(xp);
    await quest.completeLevel(widget.level.level);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 8),
            const Text(
              'Level Selesai!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Kamu menjawab $_correctCount/'
              '${widget.level.vocabs.length} dengan benar',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+$xp XP',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
              child: const Text('Kembali ke Home'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vocab = widget.level.vocabs[_currentIndex];
    final quest = context.watch<QuestProvider>();
    final isInBank = quest.isInWordBank(vocab.word);
    final total = widget.level.vocabs.length;
    final progress = (_currentIndex + 1) / total;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: Text('Level ${widget.level.level}: ${widget.level.title}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Tombol tambah ke Word Bank
          IconButton(
            onPressed: () {
              if (isInBank) {
                quest.removeFromWordBank(vocab.word);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${vocab.word}" dihapus dari Word Bank'),
                  ),
                );
              } else {
                quest.addToWordBank(vocab);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${vocab.word}" ditambahkan ke Word Bank ⭐'),
                  ),
                );
              }
            },
            icon: Icon(
              isInBank ? Icons.bookmark : Icons.bookmark_border,
              color: isInBank ? Colors.amber : Colors.grey,
            ),
            tooltip: 'Simpan ke Word Bank',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Progress ───────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kata ${_currentIndex + 1} dari $total',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryBlue,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Vocab Card ─────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Kartu vocab
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            vocab.word,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (vocab.pronunciation.isNotEmpty)
                            Text(
                              '[${vocab.pronunciation}]',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              vocab.meaning,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Contoh kalimat
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contoh Kalimat:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '"${vocab.example}"',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Input Jawaban ───────────────────────
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Ketik kata dalam bahasa Inggris:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _answerCtrl,
                      enabled: !_answered,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText:
                            'Tulis "${vocab.word}" dalam bahasa Inggris...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _answered
                                ? (_isCorrect ? Colors.green : Colors.red)
                                : Colors.grey,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: _answered
                            ? Icon(
                                _isCorrect ? Icons.check_circle : Icons.cancel,
                                color: _isCorrect ? Colors.green : Colors.red,
                              )
                            : null,
                      ),
                      onSubmitted: (_) => !_answered ? _checkAnswer() : null,
                    ),
                    const SizedBox(height: 12),

                    // ── Feedback ML ─────────────────────────
                    if (_feedback.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _isCorrect
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isCorrect
                                ? Colors.green.shade200
                                : Colors.orange.shade200,
                          ),
                        ),
                        child: Text(
                          _feedback,
                          style: TextStyle(
                            color: _isCorrect
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── Tombol ─────────────────────────────────────
            if (!_answered)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _checkAnswer,
                  icon: const Icon(Icons.check),
                  label: const Text('Cek Jawaban'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _nextVocab,
                  icon: Icon(
                    // Tambahkan operator < (lebih kecil dari)
                    _currentIndex < widget.level.vocabs.length - 1
                        ? Icons.arrow_forward
                        : Icons.emoji_events,
                  ),
                  label: Text(
                    // Tambahkan operator < (lebih kecil dari)
                    _currentIndex < widget.level.vocabs.length - 1
                        ? 'Kata Berikutnya'
                        : 'Selesai! 🎉',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCorrect
                        ? Colors.green
                        : AppTheme.primaryBlue,
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
