import 'package:flutter/material.dart';
import 'time_conversion.dart'; // Import file jam yang sudah kita buat

class TravelerPage extends StatelessWidget {
  const TravelerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Traveler Corners', 
          style: TextStyle(fontWeight: FontWeight.bold)),
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
                    MaterialPageRoute(builder: (context) => const TimeConversionPage()),
                  );
                },
              ),
              _buildMenuCard(
                icon: Icons.currency_exchange_rounded,
                iconColor: Colors.green,
                title: "Currency Converter",
                subtitle: "Konversi mata uang asing",
                onTap: () {
                  // Nanti diisi fitur lain
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMenuSection(
            title: "Information",
            items: [
              _buildMenuCard(
                icon: Icons.translate_rounded,
                iconColor: Colors.orange,
                title: "Travel Phrases",
                subtitle: "Kalimat penting untuk traveling",
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, 
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
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
              )
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