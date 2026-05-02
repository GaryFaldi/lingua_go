import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LanguageCenterPage extends StatelessWidget {
  const LanguageCenterPage({super.key});

  Future<void> _openMap(String query) async {
    final String geoUrl = "geo:0,0?q=${Uri.encodeComponent(query)}";
    final String webUrl =
        "https://www.google.com/maps/search/${Uri.encodeComponent(query)}";

    try {
      final Uri geoUri = Uri.parse(geoUrl);
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalNonBrowserApplication);
      } else {
        final Uri webUri = Uri.parse(webUrl);
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint("Gagal membuka Maps: $e");
    }
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
            onTap: () => _openMap("English Course near me"),
          ),
          const SizedBox(height: 15),
          _buildLocationCard(
            icon: Icons.assignment_turned_in_rounded,
            color: Colors.blue,
            title: "Pusat Sertifikasi",
            description: "Lokasi ujian resmi untuk TOEFL, IELTS, atau TOEIC.",
            onTap: () => _openMap("TOEFL IELTS Certification Center near me"),
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
