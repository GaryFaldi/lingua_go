import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/quest_model.dart';
import 'quest_provider.dart';
import 'quest_detail_page.dart';

class QuestListPage extends StatelessWidget {
  const QuestListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final quest = context.watch<QuestProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Main Quest'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quest.levels.length,
        itemBuilder: (_, i) {
          final level = quest.levels[i];
          final isUnlocked = quest.isLevelUnlocked(level.level);
          final isCompleted = level.level <= quest.completedLevels;

          return GestureDetector(
            onTap: isUnlocked
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuestDetailPage(level: level),
                    ),
                  )
                : () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔒 Selesaikan level sebelumnya dulu!'),
                    ),
                  ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isCompleted
                    ? Border.all(color: Colors.green.shade200)
                    : level.level == quest.currentLevel
                    ? Border.all(color: AppTheme.primaryBlue, width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  // Level number circle
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green
                          : isUnlocked
                          ? AppTheme.primaryBlue
                          : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 22,
                            )
                          : !isUnlocked
                          ? const Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 18,
                            )
                          : Text(
                              '${level.level}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${level.emoji} ${level.title}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isUnlocked ? Colors.black87 : Colors.grey,
                          ),
                        ),
                        Text(
                          level.subtitle,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${level.vocabs.length} kata • +${level.xpReward} XP',
                          style: TextStyle(
                            color: isCompleted
                                ? Colors.green
                                : AppTheme.primaryBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    isUnlocked ? Icons.arrow_forward_ios : Icons.lock_outline,
                    size: 16,
                    color: isUnlocked ? AppTheme.primaryBlue : Colors.grey,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
