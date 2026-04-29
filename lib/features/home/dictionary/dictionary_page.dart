import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/quest_data.dart';
import '../../../data/models/quest_model.dart';
import '../main_quest/quest_provider.dart';

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  late TabController _tabCtrl;

  // ── State ─────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _apiResults = [];
  List<VocabItem> _localResults = [];
  String _lastQuery = '';
  String _translatedQuery = '';
  String _translatedMeaning = '';
  bool _isIndonesian = false;

  // Filter lokal
  String _selectedCategory = 'Semua';
  final _categories = [
    'Semua',
    'greeting',
    'food',
    'color',
    'family',
    'travel',
    'work',
    'health',
    'tech',
    'nature',
    'advanced',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadAllLocal();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Local Search ──────────────────────────────────────

  void _loadAllLocal({String query = ''}) {
    final all = QuestData.levels.expand((l) => l.vocabs).toList();

    setState(() {
      _localResults = all.where((v) {
        final matchQuery =
            query.isEmpty ||
            v.word.toLowerCase().contains(query.toLowerCase()) ||
            v.meaning.toLowerCase().contains(query.toLowerCase());
        final matchCat =
            _selectedCategory == 'Semua' || v.category == _selectedCategory;
        return matchQuery && matchCat;
      }).toList();
    });
  }

  // ── API Search ────────────────────────────────────────
  Future<bool> _isIndonesianWord(String word) async {
    // Deteksi sederhana: coba translate ID→EN, jika berbeda berarti memang ID
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(word)}&langpair=id|en',
        ),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final translated =
            data['responseData']['translatedText'] as String? ?? '';
        // Jika hasil translate berbeda dengan input, kemungkinan besar itu bahasa Indonesia
        return translated.toLowerCase().trim() != word.toLowerCase().trim();
      }
    } catch (_) {}
    return false;
  }

  Future<String> _translateToEnglish(String word) async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(word)}&langpair=id|en',
        ),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['responseData']['translatedText'] as String? ?? word;
      }
    } catch (_) {}
    return word;
  }

  Future<String> _translateToIndonesian(String text) async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=en|id',
        ),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['responseData']['translatedText'] as String? ?? text;
      }
    } catch (_) {}
    return text;
  }

  Future<void> _searchOnline(String word) async {
    if (word.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _apiResults = [];
      _lastQuery = word;
      _translatedQuery = '';
      _translatedMeaning = '';
      _isIndonesian = false;
    });

    try {
      // 1. Deteksi bahasa
      final isID = await _isIndonesianWord(word);
      String queryEN = word;

      if (isID) {
        // 2a. Terjemahkan ID → EN dulu
        queryEN = await _translateToEnglish(word);
        setState(() {
          _isIndonesian = true;
          _translatedQuery = queryEN;
        });
      }

      // 3. Hit dictionary API dengan kata EN
      final response = await http.get(
        Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$queryEN'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;

        // 4. Ambil definisi pertama → terjemahkan ke ID
        String firstDef = '';
        if (data.isNotEmpty) {
          final meanings = data.first['meanings'] as List? ?? [];
          if (meanings.isNotEmpty) {
            final defs = meanings.first['definitions'] as List? ?? [];
            if (defs.isNotEmpty) {
              firstDef = defs.first['definition'] as String? ?? '';
            }
          }
        }

        final translatedDef = firstDef.isNotEmpty
            ? await _translateToIndonesian(firstDef)
            : '';

        setState(() {
          _apiResults = data;
          _translatedMeaning = translatedDef;
        });
      } else if (response.statusCode == 404) {
        setState(() => _errorMessage = 'Kata "$word" tidak ditemukan');
      } else {
        setState(() => _errorMessage = 'Terjadi kesalahan server');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Tidak ada koneksi internet');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearch() {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() => _lastQuery = query); // ← set dulu sebelum pindah tab
    _loadAllLocal(query: query);
    _searchOnline(query);
    _tabCtrl.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('📖 Kamus'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryBlue,
          tabs: const [
            Tab(text: '📚 Koleksi Lokal'),
            Tab(text: '🌐 Kamus Online'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Search Bar ─────────────────────────────────
          _buildSearchBar(),

          // ── Tab Content ────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [_buildLocalTab(), _buildOnlineTab()],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _onSearch(),
              onChanged: (val) => _loadAllLocal(query: val),
              decoration: InputDecoration(
                hintText: 'Cari kata...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.primaryBlue,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _loadAllLocal();
                          setState(() {
                            _apiResults = [];
                            _errorMessage = null;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF0F4FF),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _onSearch,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Icon(Icons.search, size: 20),
          ),
        ],
      ),
    );
  }

  // ── LOCAL TAB ─────────────────────────────────────────

  Widget _buildLocalTab() {
    return Column(
      children: [
        // Filter kategori
        _buildCategoryFilter(),

        // Jumlah hasil
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${_localResults.length} kata ditemukan',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),

        // List vocab
        Expanded(
          child: _localResults.isEmpty
              ? _buildEmptyState('🔍', 'Tidak ada kata yang cocok')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _localResults.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      _buildLocalCard(context, _localResults[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final isSelected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = cat);
              _loadAllLocal(query: _searchCtrl.text);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                cat == 'Semua' ? '🌟 Semua' : cat,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocalCard(BuildContext context, VocabItem vocab) {
    final quest = context.read<QuestProvider>();
    final isInBank = quest.isInWordBank(vocab.word);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          // Category icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                _categoryEmoji(vocab.category),
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Word info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      vocab.word,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (vocab.pronunciation.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '[${vocab.pronunciation}]',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  vocab.meaning,
                  style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 14,
                  ),
                ),
                if (vocab.example.isNotEmpty)
                  Text(
                    '"${vocab.example}"',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Bookmark button
          IconButton(
            onPressed: () {
              if (isInBank) {
                quest.removeFromWordBank(vocab.word);
              } else {
                quest.addToWordBank(vocab);
              }
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isInBank
                        ? '"${vocab.word}" dihapus dari Word Bank'
                        : '"${vocab.word}" disimpan ke Word Bank ⭐',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            icon: Icon(
              isInBank ? Icons.bookmark : Icons.bookmark_border,
              color: isInBank ? Colors.amber : Colors.grey,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ── ONLINE TAB ────────────────────────────────────────

  Widget _buildOnlineTab() {
    if (_lastQuery.isEmpty) {
      return Column(
        children: [
          // ← Tambah di sini
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.shade50,
            child: const Row(
              children: [
                Icon(Icons.wifi, size: 14, color: Colors.blue),
                SizedBox(width: 6),
                Text(
                  'Fitur ini membutuhkan koneksi internet',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: _buildEmptyState(
                '🌐',
                'Cari kata dalam Bahasa Inggris atau Indonesia\nhasil akan ditampilkan dengan terjemahan',
              ),
            ),
          ),
        ],
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildEmptyState('😕', _errorMessage!);
    }

    if (_apiResults.isEmpty) {
      return _buildEmptyState('📭', 'Tidak ada hasil untuk "$_lastQuery"');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _apiResults.length + 1, // +1 untuk translation banner
      itemBuilder: (_, i) {
        if (i == 0) return _buildTranslationBanner();
        return _buildOnlineCard(context, _apiResults[i - 1]);
      },
    );
  }

  // Banner terjemahan di atas hasil
  Widget _buildTranslationBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isIndonesian) ...[
            Row(
              children: [
                const Text('🇮🇩', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  '"$_lastQuery"',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Text(' → ', style: TextStyle(color: Colors.grey)),
                const Text('🇬🇧', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  '"$_translatedQuery"',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          if (_translatedMeaning.isNotEmpty) ...[
            const Text(
              '📝 Arti dalam Bahasa Indonesia:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              _translatedMeaning,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOnlineCard(BuildContext context, Map<String, dynamic> entry) {
    final word = entry['word'] as String? ?? '';
    final phonetics = entry['phonetics'] as List? ?? [];
    final phonetic =
        entry['phonetic'] as String? ??
        (phonetics.isNotEmpty
            ? (phonetics.first['text'] as String? ?? '')
            : '');
    final meanings = entry['meanings'] as List? ?? [];

    // Ambil definisi pertama untuk Word Bank
    String firstMeaning = '';
    if (meanings.isNotEmpty) {
      final defs = meanings.first['definitions'] as List? ?? [];
      if (defs.isNotEmpty) {
        firstMeaning = defs.first['definition'] as String? ?? '';
      }
    }

    final quest = context.read<QuestProvider>();
    final isInBank = quest.isInWordBank(word);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (phonetic.isNotEmpty)
                        Text(
                          phonetic,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),

                // Copy button
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: word));
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Disalin!')));
                  },
                  icon: const Icon(Icons.copy, color: Colors.white70, size: 20),
                ),

                // Bookmark
                IconButton(
                  onPressed: () {
                    if (isInBank) {
                      quest.removeFromWordBank(word);
                    } else {
                      quest.addToWordBank(
                        VocabItem(
                          word: word,
                          meaning: firstMeaning,
                          example: '',
                          category: 'online',
                        ),
                      );
                    }
                    setState(() {});
                  },
                  icon: Icon(
                    isInBank ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),

          // ── Meanings ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: meanings.take(3).map<Widget>((meaning) {
                final pos = meaning['partOfSpeech'] as String? ?? '';
                final defs = meaning['definitions'] as List? ?? [];
                final synonyms = meaning['synonyms'] as List? ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Part of speech badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pos,
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Definitions (maks 2)
                    ...defs.take(2).map((def) {
                      final definition = def['definition'] as String? ?? '';
                      final example = def['example'] as String? ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '• ',
                                  style: TextStyle(
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    definition,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            if (example.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 12,
                                  top: 4,
                                ),
                                child: Text(
                                  '"$example"',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),

                    // Synonyms
                    if (synonyms.isNotEmpty) ...[
                      const Text(
                        'Sinonim:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: synonyms
                            .take(4)
                            .map(
                              (s) => GestureDetector(
                                onTap: () {
                                  _searchCtrl.text = s.toString();
                                  _onSearch();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryPurple.withOpacity(
                                      0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.primaryPurple.withOpacity(
                                        0.2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    s.toString(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryPurple,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────

  Widget _buildEmptyState(String emoji, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ],
      ),
    );
  }

  String _categoryEmoji(String category) {
    const map = {
      'greeting': '👋',
      'food': '🍔',
      'color': '🎨',
      'family': '👨‍👩‍👧‍👦',
      'travel': '✈️',
      'work': '💼',
      'health': '🏥',
      'tech': '💻',
      'nature': '🌿',
      'advanced': '🎓',
      'saved': '⭐',
      'online': '🌐',
    };
    return map[category] ?? '📝';
  }
}
