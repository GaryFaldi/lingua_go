import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Wajib di-import untuk GetX!
import '../../../core/theme/app_theme.dart';
import '../../../controller/word_bank_controller.dart';

class WordBankPage extends StatelessWidget {
  const WordBankPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Inisialisasi controller GetX
    final controller = Get.find<WordBankController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Word Bank ⭐'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Obx(() {
        final words = controller.words;

        // Jika kosong, tampilkan pesan kosong
        if (words.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('📭', style: TextStyle(fontSize: 60)),
                SizedBox(height: 12),
                Text(
                  'Word Bank kosong',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Simpan kata dari Main Quest\ndengan menekan ikon bookmark',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Jika ada isinya, tampilkan list
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: words.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final vocab = words[i];

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('📝', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vocab.word,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          vocab.meaning,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Hapus dari state
                      controller.removeFromWordBank(vocab.word);

                      // Munculkan notifikasi snackbar
                      Get.snackbar(
                        'Dihapus',
                        '"${vocab.word}" telah dihapus',
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                        margin: const EdgeInsets.all(16),
                      );
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
