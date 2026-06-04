import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CertificationCenterPage extends StatefulWidget {
  const CertificationCenterPage({super.key});

  @override
  State<CertificationCenterPage> createState() =>
      _CertificationCenterPageState();
}

class _CertificationCenterPageState extends State<CertificationCenterPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final String searchUrl =
        "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('TOEFL IELTS Certification Center near me')}";

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
        title: const Text('Pusat Sertifikasi', style: TextStyle(fontSize: 16)),
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
