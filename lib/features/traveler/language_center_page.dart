import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LanguageCenterPage extends StatelessWidget {
  const LanguageCenterPage({super.key});

  void _openMap(BuildContext context, String query, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InAppMapPage(query: query, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Language Centers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black, // Memastikan ikon back berwarna hitam
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Temukan bantuan belajar di dekatmu",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          _buildLocationCard(
            icon: Icons.school_rounded,
            color: Colors.orange,
            title: "Kursus Bahasa Inggris",
            description:
                "Cari bimbingan belajar atau kursus intensif terdekat.",
            onTap: () => _openMap(
              context,
              "English Course near me",
              "Kursus Bahasa Inggris",
            ),
          ),
          const SizedBox(height: 15),
          _buildLocationCard(
            icon: Icons.assignment_turned_in_rounded,
            color: Colors.blue,
            title: "Pusat Sertifikasi",
            description: "Lokasi ujian resmi untuk TOEFL, IELTS, atau TOEIC.",
            onTap: () => _openMap(
              context,
              "TOEFL IELTS Certification Center near me",
              "Pusat Sertifikasi",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.map_outlined, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// Halaman baru untuk menampilkan Peta di dalam aplikasi
class InAppMapPage extends StatefulWidget {
  final String query;
  final String title;

  const InAppMapPage({super.key, required this.query, required this.title});

  @override
  State<InAppMapPage> createState() => _InAppMapPageState();
}

class _InAppMapPageState extends State<InAppMapPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Format URL pencarian Google Maps
    final String searchUrl =
        "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.query)}";

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('intent://') ||
                request.url.startsWith('android-app://') ||
                request.url.startsWith('geo:')) {
              debugPrint('Blokir redirect ke aplikasi native: ${request.url}');
              return NavigationDecision.prevent; // Paksa tetap di web
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false; // Hilangkan loading saat peta selesai dimuat
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(searchUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
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
