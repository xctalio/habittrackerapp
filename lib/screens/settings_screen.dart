import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _themeService = ThemeService();

  @override
  Widget build(BuildContext context) {
    final username = _authService.currentUser?.username ?? 'User';
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                      username[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
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
                        'Habit Tracker User',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildListTile(
              context,
              icon: Icons.person_outline,
              title: 'Account Preferences',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur dalam pengembangan')),
                );
              },
            ),
            Divider(color: Theme.of(context).dividerColor),
            _buildListTile(
              context,
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur dalam pengembangan')),
                );
              },
            ),
            Divider(color: Theme.of(context).dividerColor),
            ListTile(
              leading: Icon(
                Icons.dark_mode_outlined,
                color: isDark ? Colors.white : Colors.black,
              ),
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
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
            _buildListTile(
              context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur dalam pengembangan')),
                );
              },
            ),
            Divider(color: Theme.of(context).dividerColor),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red[400]),
              title: Text(
                'Logout',
                style: TextStyle(color: Colors.red[400]),
              ),
              onTap: () {
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
                        onPressed: () {
                          _authService.logout();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        child: Text(
                          'Logout',
                          style: TextStyle(color: Colors.red[400]),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? Colors.white : Colors.black,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDark ? Colors.white54 : Colors.black54,
      ),
      onTap: onTap,
    );
  }
}