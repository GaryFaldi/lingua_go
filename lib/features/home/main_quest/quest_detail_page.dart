import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../../controller/word_bank_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/quest_model.dart';
import 'spell_correction_model.dart';
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
  bool _isTypo = false;
  int _correctCount = 0;

  // ── ML Auto-Correction (Naive Bayes) ─────────────────────────
  final _spellModel = NaiveBayesSpellModel();

  @override
  void initState() {
    super.initState();
    _spellModel.loadModel(); // load JSON saat page dibuka
  }

  String? _getSpellSuggestion(String input, String correct) {
    return _spellModel.predictCorrection(input, correct);
  }

  void _checkAnswer() {
    final vocab = widget.level.vocabs[_currentIndex];
    final input = _answerCtrl.text.trim();
    if (input.isEmpty) return;

    final correct = vocab.word.toLowerCase();
    final userInput = input.toLowerCase();

    setState(() {
      if (userInput == correct) {
        // ✅ Benar
        _answered = true;
        _isCorrect = true;
        _isTypo = false;
        _feedback = '✅ Benar! Bagus sekali!';
        _correctCount++;
      } else {
        final suggestion = _getSpellSuggestion(userInput, vocab.word);
        if (suggestion != null) {
          // 🤔 Typo — tetap answered, bisa lanjut
          _answered = true;
          _isCorrect = false;
          _isTypo = true;
          _feedback =
              '🤔 Hampir benar! Maksud kamu "$suggestion"?\n'
              'Jawaban yang benar: ${vocab.word}';
        } else {
          // ❌ Salah — reset, harus jawab ulang
          _answered = false;
          _isCorrect = false;
          _isTypo = false;
          _feedback = '❌ Salah! Coba lagi.';
          _answerCtrl.clear();
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
        _isTypo = false; // tambah ini
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
    final wordBankCtrl = Get.find<WordBankController>();
    final total = widget.level.vocabs.length;
    final progress = (_currentIndex + 1) / total;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: Text('Level ${widget.level.level}: ${widget.level.title}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Obx(() {
            final inBank = wordBankCtrl.words.any((v) => v.word == vocab.word);
            return IconButton(
              onPressed: () async {
                if (inBank) {
                  await wordBankCtrl.removeFromWordBank(vocab.word);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${vocab.word}" dihapus dari Word Bank'),
                    ),
                  );
                } else {
                  await wordBankCtrl.addToWordBank(vocab);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '"${vocab.word}" ditambahkan ke Word Bank ⭐',
                      ),
                    ),
                  );
                }
              },
              icon: Icon(
                inBank ? Icons.bookmark : Icons.bookmark_border,
                color: inBank ? Colors.amber : Colors.grey,
              ),
              tooltip: 'Simpan ke Word Bank',
            );
          }),
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
                    _currentIndex < widget.level.vocabs.length - 1
                        ? Icons.arrow_forward
                        : Icons.emoji_events,
                  ),
                  label: Text(
                    _currentIndex < widget.level.vocabs.length - 1
                        ? 'Kata Berikutnya'
                        : 'Selesai! 🎉',
                  ),
                  style: ElevatedButton.styleFrom(
                    // Benar = hijau, Typo = orange, (Salah tidak sampai sini)
                    backgroundColor: _isCorrect ? Colors.green : Colors.orange,
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
