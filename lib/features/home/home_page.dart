import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import 'main_quest/quest_provider.dart';
import 'main_quest/quest_list_page.dart';
import 'main_quest/quest_detail_page.dart';
import 'side_quest/tilt_a_word_page.dart';
import 'side_quest/shake_challenge_page.dart';
import 'side_quest/word_bank_page.dart';
import 'dictionary/dictionary_page.dart';
import 'chatbot/chatbot_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final quest = context.watch<QuestProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────
              _buildHeader(context, user?.username ?? 'Pelajar'),
              const SizedBox(height: 20),
              const SizedBox(width: 8),
              _iconButton(
                icon: Icons.smart_toy_rounded, // 🤖 icon
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatBotPage()),
                ),
              ),
              // ── XP Banner ───────────────────────────────
              _buildXpBanner(quest),
              const SizedBox(height: 24),

              // ── Main Quest ──────────────────────────────
              _buildSectionTitle(
                '⚔️ Main Quest',
                'Lihat Semua',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => QuestListPage()),
                ),
              ),
              const SizedBox(height: 12),
              _buildMainQuestCard(context, quest),
              const SizedBox(height: 24),

              // ── Side Quest ──────────────────────────────
              _buildSectionTitle('🎮 Side Quest', null),
              const SizedBox(height: 12),
              _buildSideQuestGrid(context),
              const SizedBox(height: 24),

              // ── Daily Challenge ─────────────────────────
              _buildDailyChallenge(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, String username) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Selamat Pagi'
        : now.hour < 17
        ? 'Selamat Siang'
        : 'Selamat Malam';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Text(
                username,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),

        // Search button
        _iconButton(
          icon: Icons.search,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DictionaryPage()),
          ),
        ),
        const SizedBox(width: 8),

        // Word bank button
        _iconButton(
          icon: Icons.bookmark_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WordBankPage()),
          ),
        ),
      ],
    );
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8),
          ],
        ),
        child: Icon(icon, color: AppTheme.primaryBlue, size: 22),
      ),
    );
  }

  // ── XP Banner ──────────────────────────────────────────

  Widget _buildXpBanner(QuestProvider quest) {
    final progress = (quest.completedLevels / 10).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.rankTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${quest.currentXp} XP Total',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Level ${quest.currentLevel}/10',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progress Keseluruhan',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '${quest.completedLevels}/10 Level',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section Title ──────────────────────────────────────

  Widget _buildSectionTitle(
    String title,
    String? actionText, {
    VoidCallback? onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        if (actionText != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              actionText,
              style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 13),
            ),
          ),
      ],
    );
  }

  // ── Main Quest Card ─────────────────────────────────────

  Widget _buildMainQuestCard(BuildContext context, QuestProvider quest) {
    // Ambil level saat ini (yang sedang dikerjakan)
    final currentIdx = (quest.completedLevels).clamp(0, 9);
    final levels = quest.levels;
    if (levels.isEmpty) return const SizedBox.shrink();

    // Tampilkan level saat ini dan 2 level berikutnya
    final displayLevels = levels.skip(currentIdx).take(3).toList();

    return Column(
      children: displayLevels.map((level) {
        final isUnlocked = quest.isLevelUnlocked(level.level);
        final isCompleted = level.level <= quest.completedLevels;
        final isCurrent = level.level == quest.currentLevel;

        return GestureDetector(
          onTap: isUnlocked
              ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuestDetailPage(level: level),
                  ),
                )
              : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.shade50
                  : isCurrent
                  ? Colors.white
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: isCurrent
                  ? Border.all(color: AppTheme.primaryBlue, width: 2)
                  : isCompleted
                  ? Border.all(color: Colors.green.shade200)
                  : null,
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                // Emoji + level badge
                Stack(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.shade100
                            : isCurrent
                            ? AppTheme.primaryBlue.withOpacity(0.1)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          level.emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                    if (isCompleted)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    if (!isUnlocked)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Level ${level.level}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isCompleted
                                  ? Colors.green
                                  : isCurrent
                                  ? AppTheme.primaryBlue
                                  : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'AKTIF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        level.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isUnlocked
                              ? const Color(0xFF1E293B)
                              : Colors.grey,
                        ),
                      ),
                      Text(
                        level.subtitle,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // XP & Arrow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${level.xpReward} XP',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      isUnlocked ? Icons.arrow_forward_ios : Icons.lock_outline,
                      size: 16,
                      color: isUnlocked ? AppTheme.primaryBlue : Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Side Quest Grid ─────────────────────────────────────

  Widget _buildSideQuestGrid(BuildContext context) {
    final items = [
      _SideQuestItem(
        icon: '📱',
        title: 'Tilt-A-Word',
        subtitle: 'Gyroscope Game',
        gradient: const [Color(0xFFEC4899), Color(0xFFF97316)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TiltAWordPage()),
        ),
      ),
      _SideQuestItem(
        icon: '🎲',
        title: 'Shake!',
        subtitle: 'Kuis Kilat Harian',
        gradient: const [Color(0xFF10B981), Color(0xFF06B6D4)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShakeChallengePage()),
        ),
      ),
      _SideQuestItem(
        icon: '📖',
        title: 'Kamus',
        subtitle: 'Cari Kata',
        gradient: const [Color(0xFF3B82F6), Color(0xFF6366F1)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DictionaryPage()),
        ),
      ),
      _SideQuestItem(
        icon: '⭐',
        title: 'Word Bank',
        subtitle: 'Koleksi Vocab',
        gradient: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WordBankPage()),
        ),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: items.map((item) => _buildSideQuestCard(item)).toList(),
    );
  }

  Widget _buildSideQuestCard(_SideQuestItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: item.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: item.gradient[0].withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(item.icon, style: const TextStyle(fontSize: 28)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Daily Challenge ─────────────────────────────────────

  Widget _buildDailyChallenge(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('🔥', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tantangan Harian',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Text(
                  'Guncang HP untuk kuis kilat +50 XP!',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShakeChallengePage()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Main!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideQuestItem {
  final String icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _SideQuestItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });
}
