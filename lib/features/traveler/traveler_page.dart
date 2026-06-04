import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'time_conversion.dart';
import 'currency_page.dart';
import 'language_center_page.dart';
import 'english_course_page.dart';
import 'certification_center_page.dart';

class TravelerPage extends StatelessWidget {
  const TravelerPage({super.key});

  Future<void> _openMap(String query) async {
    // Mencari tempat kursus atau sertifikasi terdekat
    final String googleMapsUrl =
        "https://www.google.com/maps/search/?api=1&query=$query";
    final Uri uri = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Tidak bisa membuka peta.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Traveler Corners',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildMenuSection(
            title: "Tools & Utilities",
            items: [
              _buildMenuCard(
                icon: Icons.public_rounded,
                iconColor: Colors.blue,
                title: "World Clock",
                subtitle: "Cek waktu di berbagai belahan dunia",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TimeConversionPage(),
                    ),
                  );
                },
              ),
              _buildMenuCard(
                icon: Icons.currency_exchange_rounded,
                iconColor: Colors.green,
                title: "Currency Converter",
                subtitle: "Konversi mata uang asing",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CurrencyPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMenuSection(
            title: "Language Centers",
            items: [
              _buildMenuCard(
                icon: Icons.school_rounded,
                iconColor: Colors.orange,
                title: "Kursus Bahasa Inggris",
                subtitle:
                    "Cari bimbingan belajar atau kursus intensif terdekat",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EnglishCoursePage()),
                ),
              ),
              _buildMenuCard(
                icon: Icons.assignment_turned_in_rounded,
                iconColor: Colors.blue,
                title: "Pusat Sertifikasi",
                subtitle: "Lokasi ujian resmi untuk TOEFL, IELTS, atau TOEIC",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CertificationCenterPage(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Pilih Jenis Tempat",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.school, color: Colors.orange),
                title: const Text("Kursus Bahasa Inggris"),
                onTap: () {
                  Navigator.pop(context);
                  _openMap("English Course near me");
                },
              ),
              ListTile(
                leading: const Icon(Icons.assignment, color: Colors.blue),
                title: const Text("Pusat Sertifikasi (TOEFL/IELTS)"),
                onTap: () {
                  Navigator.pop(context);
                  _openMap("TOEFL IELTS Certification Center near me");
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
