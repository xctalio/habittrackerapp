import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ← TAMBAH INI
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/habit_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _themeService = ThemeService();
  final _habitService = HabitService();
  bool _notificationsEnabled = true;

  void _showProfileDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final username = _authService.currentUsername ?? 'Unknown';
    final userId = _authService.currentUserId ?? 'N/A';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        title: Text(
          'Profile',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.cyan[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.cyan[400],
                        child: Text(
                          username.isNotEmpty ? username[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: $userId',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Total Habits: ${_habitService.getTotalCount()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.cyan[400])),
          ),
        ],
      ),
    );
  }

  void _showResetDataDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        title: Text(
          'Reset Semua Data',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          'PERINGATAN: Tindakan ini akan menghapus SEMUA habits dan journal entries Anda.\n\nData akan hilang permanen dan tidak dapat dipulihkan. Lanjutkan?',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                final userId = _authService.getCurrentUserId();
                if (userId != null) {
                  await Supabase.instance.client
                      .from('habits')
                      .delete()
                      .eq('user_id', userId.toString());

                  await Supabase.instance.client
                      .from('journal_entries')
                      .delete()
                      .eq('user_id', userId.toString());

                  _habitService.resetInitialization();
                }

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Semua data berhasil dihapus'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  setState(() {});
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Hapus Semua',
              style: TextStyle(color: Colors.red[400]),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        title: Text(
          'Logout',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          'Apakah Anda yakin ingin logout?',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _authService.logoutAsync();
                _habitService.resetInitialization();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text('Logout', style: TextStyle(color: Colors.red[400])),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final username = _authService.currentUsername ?? 'User';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.cyan[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.cyan[400],
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your account',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Account'),
            _buildListTile(
              context,
              icon: Icons.person_outline,
              title: 'View Profile',
              onTap: _showProfileDialog,
            ),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: 12),

            _buildSectionTitle('Preferences'),
            ListTile(
              leading: Icon(
                Icons.dark_mode_outlined,
                color: isDark ? Colors.white : Colors.black,
              ),
              title: Text(
                'Dark Mode',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              trailing: Switch(
                value: _themeService.isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _themeService.toggleTheme();
                  });
                },
                activeColor: Colors.cyan[400],
              ),
            ),
            Divider(color: Theme.of(context).dividerColor),
            ListTile(
              leading: Icon(
                Icons.notifications_outlined,
                color: isDark ? Colors.white : Colors.black,
              ),
              title: Text(
                'Notifications',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
                activeColor: Colors.cyan[400],
              ),
            ),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: 12),

            _buildSectionTitle('Data & Privacy'),
            _buildListTile(
              context,
              icon: Icons.delete_outline,
              title: 'Reset Semua Data',
              subtitle: 'Hapus semua habits dan journal',
              onTap: _showResetDataDialog,
              isDestructive: true,
            ),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: 12),

            _buildSectionTitle('Help & Support'),
            _buildListTile(
              context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: isDark
                        ? const Color(0xFF2C2C2C)
                        : Colors.white,
                    title: Text(
                      'Help & Support',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    content: Text(
                      'Untuk bantuan lebih lanjut, hubungi:\n\nEmail: support@habittracker.com\n\nFollow social media kami untuk tips dan trik menggunakan aplikasi.',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Close',
                          style: TextStyle(color: Colors.cyan[400]),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Divider(color: Theme.of(context).dividerColor),
            _buildListTile(
              context,
              icon: Icons.info_outline,
              title: 'About',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: isDark
                        ? const Color(0xFF2C2C2C)
                        : Colors.white,
                    title: Text(
                      'About Habit Tracker',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    content: Text(
                      'Habit Tracker v1.0\n\nA simple and effective app to build better habits with Supabase backend.\n\n© 2024 Habit Tracker. All rights reserved.',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Close',
                          style: TextStyle(color: Colors.cyan[400]),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: 24),

            ListTile(
              leading: Icon(Icons.logout, color: Colors.red[400]),
              title: Text('Logout', style: TextStyle(color: Colors.red[400])),
              onTap: _showLogoutDialog,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.cyan[400] : Colors.cyan[700],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? Colors.red[400]
            : (isDark ? Colors.white : Colors.black),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive
              ? Colors.red[400]
              : (isDark ? Colors.white : Colors.black),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            )
          : null,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDark ? Colors.white54 : Colors.black54,
      ),
      onTap: onTap,
    );
  }
}
