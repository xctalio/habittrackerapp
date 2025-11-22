import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/theme_service.dart';

void main() {
  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatefulWidget {
  const HabitTrackerApp({Key? key}) : super(key: key);

  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  final _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.cyan,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'SF Pro',
        cardColor: Colors.white,
        dividerColor: Colors.grey[300],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.cyan,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'SF Pro',
        cardColor: const Color(0xFF1E1E1E),
        dividerColor: Colors.grey[800],
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      themeMode: _themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const LoginScreen(),
    );
  }
}