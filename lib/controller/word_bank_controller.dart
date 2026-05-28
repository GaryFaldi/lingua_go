import 'package:get/get.dart';
import '../data/models/vocab_model.dart';

class WordBankController extends GetxController {
  // Gunakan .obs agar list ini menjadi reaktif (observable)
  var words = <Vocab>[
    Vocab(word: 'Dragoon', meaning: 'Seorang prajurit kuda; kavaleri.'),
    Vocab(word: 'Please', meaning: 'Tolong / Mohon'),
    Vocab(word: 'Bread', meaning: 'Roti'),
  ].obs;

  // Fungsi untuk menghapus kata
  void removeFromWordBank(String word) {
    words.removeWhere((v) => v.word == word);
    // TODO: Tambahkan logika untuk menghapus dari SQLite di sini nantinya
  }

  // Fungsi untuk menambah kata
  void addToWordBank(Vocab vocab) {
    words.add(vocab);
  }
}