// lib/features/profile/profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/local/database_helper.dart';
// import '../../data/models/suggestion_model.dart';
import '../auth/auth_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricEnabled = false;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _photoPath = prefs.getString('photo_path');
    });
  }

  // ── Foto Profil ───────────────────────────────────────────
  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('photo_path', picked.path);

    // Simpan path ke DB juga
    final auth = context.read<AuthProvider>();
    if (auth.currentUser?.id != null) {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'users',
        {'photo_path': picked.path},
        where: 'id = ?',
        whereArgs: [auth.currentUser!.id],
      );
    }

    setState(() => _photoPath = picked.path);
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: Color(0xFF6C63FF),
              ),
              title: const Text('Ambil dari Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: Color(0xFF6C63FF),
              ),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Toggle Biometrik ──────────────────────────────────────
  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perangkat tidak mendukung biometrik'),
            ),
          );
        }
        return;
      }

      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Konfirmasi untuk mengaktifkan login sidik jari',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (!didAuth) return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
    setState(() => _biometricEnabled = value);
  }

  // ── Ganti Password ────────────────────────────────────────
  void _showChangePasswordDialog() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ganti Password'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Lama'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Baru'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi Password Baru',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password baru tidak cocok!')),
                );
                return;
              }
              // TODO: panggil auth_repository untuk update password
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password berhasil diubah!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ── Kesan & Saran ─────────────────────────────────────────
  void _showSuggestionSheet() {
    final auth = context.read<AuthProvider>();
    final kesanCtrl = TextEditingController();
    final saranCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kesan & Saran TPM',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Mata Kuliah Teknologi Pemrograman Mobile',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: kesanCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Kesan',
                hintText: 'Bagaimana kesanmu tentang matkul ini?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: saranCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Saran',
                hintText: 'Ada saran untuk matkul ini?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  if (kesanCtrl.text.isEmpty && saranCtrl.text.isEmpty) {
                    return;
                  }
                  final db = await DatabaseHelper.instance.database;
                  await db.insert('suggestions', {
                    'user_id': auth.currentUser?.id ?? 0,
                    'kesan': kesanCtrl.text,
                    'saran': saranCtrl.text,
                    'created_at': DateTime.now().toIso8601String(),
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Terima kasih atas feedbackmu!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Kirim Feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logout ────────────────────────────────────────────────
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar dari LinguaQuest?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final xpProgress = (user?.xp ?? 0) % 1000;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FF),
      body: CustomScrollView(
        slivers: [
          // Header ungu
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFF6C63FF),
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap: _showPhotoOptions,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.white24,
                              backgroundImage: _photoPath != null
                                  ? FileImage(File(_photoPath!))
                                  : null,
                              child: _photoPath == null
                                  ? Text(
                                      (user?.username ?? 'U')[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF6C63FF),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.username ?? 'User',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Level ${user?.currentLevel ?? 1} — Language Adventurer',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // XP Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'XP Progress',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      Text(
                        '$xpProgress / 1000',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: xpProgress / 1000,
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Akun ──────────────────────────────────
                _SectionLabel('Akun'),
                _ProfileCard(
                  children: [
                    _ProfileRow(
                      icon: Icons.photo_camera_rounded,
                      iconBg: const Color(0xFF6C63FF),
                      title: 'Foto Profil',
                      subtitle: 'Kamera / Galeri',
                      onTap: _showPhotoOptions,
                    ),
                    _ProfileRow(
                      icon: Icons.lock_reset_rounded,
                      iconBg: const Color(0xFF1D9E75),
                      title: 'Ganti Password',
                      subtitle: 'Perbarui keamanan akun',
                      onTap: _showChangePasswordDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Keamanan ───────────────────────────────
                _SectionLabel('Keamanan'),
                _ProfileCard(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF378ADD).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.fingerprint_rounded,
                              color: Color(0xFF378ADD),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Login Sidik Jari',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Login tanpa password',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _biometricEnabled,
                            onChanged: _toggleBiometric,
                            activeColor: const Color(0xFF6C63FF),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Progress ───────────────────────────────
                _SectionLabel('Progress Belajar'),
                _ProfileCard(
                  children: [
                    _ProfileRow(
                      icon: Icons.emoji_events_rounded,
                      iconBg: Colors.amber.shade600,
                      title: 'Level Saat Ini',
                      subtitle: 'Main Quest progress',
                      trailing: _Chip('Lv. ${user?.currentLevel ?? 1}'),
                    ),
                    _ProfileRow(
                      icon: Icons.menu_book_rounded,
                      iconBg: const Color(0xFF1D9E75),
                      title: 'Word Bank',
                      subtitle: 'Koleksi kata kamu',
                      trailing: const _Chip('Lihat'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── TPM ────────────────────────────────────
                _SectionLabel('Mata Kuliah TPM'),
                _ProfileCard(
                  children: [
                    _ProfileRow(
                      icon: Icons.rate_review_rounded,
                      iconBg: const Color(0xFFD4537E),
                      title: 'Kesan & Saran',
                      subtitle: 'Feedback matakuliah TPM',
                      onTap: _showSuggestionSheet,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Logout ─────────────────────────────────
                OutlinedButton.icon(
                  onPressed: _confirmLogout,
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ──────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: Colors.grey.shade500,
      ),
    ),
  );
}

class _ProfileCard extends StatelessWidget {
  final List<Widget> children;
  const _ProfileCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: children
          .asMap()
          .entries
          .map(
            (e) => Column(
              children: [
                e.value,
                if (e.key < children.length - 1)
                  Divider(height: 1, color: Colors.grey.shade100),
              ],
            ),
          )
          .toList(),
    ),
  );
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ProfileRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconBg, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          trailing ??
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 20,
              ),
        ],
      ),
    ),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF6C63FF).withOpacity(0.1),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF6C63FF),
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
