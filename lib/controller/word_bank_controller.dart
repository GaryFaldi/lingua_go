import 'package:get/get.dart';
import '../data/models/vocab_model.dart';
import '../data/models/quest_model.dart';
import '../data/local/database_helper.dart';

class WordBankController extends GetxController {
  var words = <Vocab>[].obs;
  int _currentUserId = 0;
  bool _hasLoaded = false;

  Future<void> loadWords(int userId) async {
    if (_hasLoaded && _currentUserId == userId) return;

    _currentUserId = userId;

    final dbData = await DatabaseHelper.instance.getWordBank(userId);

    words.value = dbData
        .map(
          (data) => Vocab(
            word: data['word'] as String,
            meaning: data['meaning'] as String? ?? '',
          ),
        )
        .toList();

    _hasLoaded = true;
  }

  Future<void> removeFromWordBank(String word) async {
    await DatabaseHelper.instance.removeWordFromBank(_currentUserId, word);
    words.removeWhere((v) => v.word == word);
  }

  Future<void> addToWordBank(VocabItem item) async {
    await DatabaseHelper.instance.addWordToBank(
      _currentUserId,
      word: item.word,
      meaning: item.meaning,
      example: '',
      category: '',
    );

    final vocab = Vocab(word: item.word, meaning: item.meaning);
    words.add(vocab);
  }
}
