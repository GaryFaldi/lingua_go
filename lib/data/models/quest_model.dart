class QuestLevel {
  final int level;
  final String title;
  final String subtitle;
  final String emoji;
  final List<VocabItem> vocabs;
  final bool isUnlocked;
  final int xpReward;

  const QuestLevel({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.vocabs,
    this.isUnlocked = false,
    this.xpReward = 100,
  });
}

class VocabItem {
  final String word;
  final String meaning;
  final String example;
  final String pronunciation;
  final String category;

  const VocabItem({
    required this.word,
    required this.meaning,
    required this.example,
    this.pronunciation = '',
    required this.category,
  });
}
