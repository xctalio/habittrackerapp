import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'journal_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  
  late final List<Widget> _screens = [
    const HomeScreen(),
    const StatsScreen(),
    const CalendarScreen(),
    const JournalScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: isDark ? Colors.cyan[400] : Colors.black,
        unselectedItemColor: Colors.grey,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            label: 'Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_outlined),
            label: 'Journal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
        onTap: _onItemTapped,
      ),
    );
  }
}