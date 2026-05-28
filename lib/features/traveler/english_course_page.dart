import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EnglishCoursePage extends StatefulWidget {
  const EnglishCoursePage({super.key});

  @override
  State<EnglishCoursePage> createState() => _EnglishCoursePageState();
}

class _EnglishCoursePageState extends State<EnglishCoursePage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final String searchUrl =
        "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('English Course near me')}";

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('intent://') ||
                request.url.startsWith('android-app://') ||
                request.url.startsWith('geo:')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(searchUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kursus Bahasa Inggris',
          style: TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
