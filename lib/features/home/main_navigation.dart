// lib/features/home/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../profile/profile_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _PlaceholderPage(label: 'Home', icon: Icons.home_rounded),
    _PlaceholderPage(label: 'Traveler Corners', icon: Icons.explore_rounded),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: const Color(0xFF6C63FF).withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF6C63FF)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded, color: Color(0xFF6C63FF)),
            label: 'Traveler',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon:
                Icon(Icons.person_rounded, color: Color(0xFF6C63FF)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Placeholder sementara untuk Home & Traveler
class _PlaceholderPage extends StatelessWidget {
  final String label;
  final IconData icon;
  const _PlaceholderPage({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: const Color(0xFF6C63FF)),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Coming soon...',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}