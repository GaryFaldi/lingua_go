import 'package:get/get.dart';
import '../data/models/vocab_model.dart';
import '../data/models/quest_model.dart';

class WordBankController extends GetxController {
  var words = <Vocab>[].obs;

  void removeFromWordBank(String word) {
    words.removeWhere((v) => v.word == word);
  }

  void addToWordBank(VocabItem item) {
    final vocab = Vocab(word: item.word, meaning: item.meaning);
    words.add(vocab);
  }
}
