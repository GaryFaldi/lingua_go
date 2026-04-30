import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

class ChatBotProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static const _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static const _systemPrompt =
      'Kamu adalah LinguaBot, asisten belajar bahasa Inggris yang ramah dan '
      'interaktif. Tugasmu membantu pengguna belajar kosakata, grammar, '
      'pronunciation tips, dan percakapan sehari-hari dalam bahasa Inggris. '
      'Selalu jawab dalam bahasa Indonesia kecuali diminta sebaliknya. '
      'Berikan contoh kalimat, koreksi kesalahan dengan sopan, dan buat '
      'belajar terasa menyenangkan. Jawab singkat dan jelas.';

  ChatBotProvider() {
    _messages.add(
      ChatMessage(
        text:
            '👋 Halo! Aku LinguaBot, teman belajar bahasa Inggrismu!\n\n'
            'Mau belajar apa hari ini? 😊',
        isUser: false,
        time: DateTime.now(),
      ),
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessage(text: text, isUser: true, time: DateTime.now()));
    _isLoading = true;
    notifyListeners();

    try {
      // PERBAIKAN HISTORY: Masukkan role 'user' dan 'model'
      final history = _messages
          .take(
            _messages.length - 1,
          ) // Ambil semua kecuali pesan terakhir yang baru diketik
          .where(
            (m) => m.text.isNotEmpty && !m.text.startsWith('⚠️'),
          ) // Abaikan pesan error
          .map(
            (m) => {
              'role': m.isUser ? 'user' : 'model',
              'parts': [
                {'text': m.text},
              ],
            },
          )
          .toList();

      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {
            'parts': [
              {'text': _systemPrompt},
            ],
          },
          'contents': [
            ...history,
            {
              'role': 'user',
              'parts': [
                {'text': text},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 500,
            'topP': 0.95,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply =
            data['candidates'][0]['content']['parts'][0]['text'] as String;
        _messages.add(
          ChatMessage(text: reply, isUser: false, time: DateTime.now()),
        );
      } else if (response.statusCode == 429) {
        // TANGKAP ERROR KUOTA
        debugPrint('=== RATE LIMIT 429 ===');
        debugPrint('Response body: ${response.body}'); // TAMBAH INI
        _messages.add(
          ChatMessage(
            text:
                '⚠️ LinguaBot lagi sibuk banget. Tunggu 1 menit ya, baru tanya lagi!',
            isUser: false,
            time: DateTime.now(),
          ),
        );
      } else if (response.statusCode == 503) {
        await Future.delayed(const Duration(seconds: 3));
        // Hapus pesan user yang tadi ditambahkan, baru retry
        _messages.removeLast();
        _isLoading = false;
        await sendMessage(text);
        return;
      } else {
        debugPrint('=== ERROR ${response.statusCode} ===');
        debugPrint('Error: ${response.body}');
        _addErrorMessage();
      }
    } catch (e) {
      debugPrint('Catch Error: $e');
      _addErrorMessage();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _addErrorMessage() {
    _messages.add(
      ChatMessage(
        text: '⚠️ Maaf, terjadi kesalahan. Coba lagi ya!',
        isUser: false,
        time: DateTime.now(),
      ),
    );
  }

  void clearChat() {
    _messages.clear();
    _messages.add(
      ChatMessage(
        text: 'Chat direset. Mau belajar apa lagi? 😊',
        isUser: false,
        time: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}
