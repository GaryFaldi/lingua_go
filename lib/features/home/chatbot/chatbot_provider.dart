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
  String get _apiUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent';

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
            'Kamu bisa tanya:\n'
            '• Arti & contoh kalimat sebuah kata\n'
            '• Cara grammar yang benar\n'
            '• Tips pronunciation\n'
            '• Latihan percakapan\n\n'
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
      // Ambil 5 pesan user terakhir sebagai history
      final history = _messages
          .where((m) => m.isUser)
          .toList()
          .reversed
          .take(5)
          .toList()
          .reversed
          .map(
            (m) => {
              'role': 'user',
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
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 500},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply =
            data['candidates'][0]['content']['parts'][0]['text'] as String;
        _messages.add(
          ChatMessage(text: reply, isUser: false, time: DateTime.now()),
        );
      } else {
        debugPrint('Status: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
        _addErrorMessage();
      }
    } catch (_) {
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
