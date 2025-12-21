import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'services/notification_settings_service.dart';
import 'services/auth_service.dart';
import 'services/habit_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('===================================');
  print('   STARTING APP INITIALIZATION');
  print('===================================');

  print('Supabase URL: ${SupabaseConfig.url}');
  print('Supabase Key: ${SupabaseConfig.anonKey.substring(0, 20)}...');

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    print('Supabase INITIALIZED SUCCESSFULLY');
  } catch (e) {
    print('SUPABASE INITIALIZATION FAILED: $e');
  }

  bool hasSession = false;
  try {
    await AuthService().initialize();
    hasSession = await AuthService().hasActiveSession();
    print('Auth Service INITIALIZED - Has session: $hasSession');
  } catch (e) {
    print('AUTH INITIALIZATION FAILED: $e');
    print('AUTH INITIALIZATION FAILED: $e');
  }

  try {it NotificationSettingsService().initialize();
    await NotificationService().initialize(requestPermission: true);
    await NotificationService().printDebugInfo();
    print('Notification Services INITIALIZED SUCCESSFULLY');
  } catch (e) {
    print('NOTIFICATION INITIALIZATION FAILED: $e');
  }

  print('===================================');

  runApp(HabitTrackerApp(hasActiveSession: hasSession));
}

class HabitTrackerApp extends StatefulWidget {
  final bool hasActiveSession;

  const HabitTrackerApp({super.key, this.hasActiveSession = false});

  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  final _themeService = ThemeService();
  bool _isLoading = true;
  bool _hasSession = false;

  @override
  void initState() {
    super.initState();
    _themeService.addListener(_onThemeChanged);
    _hasSession = widget.hasActiveSession;
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (_hasSession) {
      // Initialize habits for restored session
      try {
        await HabitService().initializeHabits();
        print('✓ Habits initialized for restored session');
      } catch (e) {
        print('✗ Failed to initialize habits: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
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
      home: _isLoading
          ? const _SplashScreen()
          : (_hasSession ? const MainNavigationScreen() : const LoginScreen()),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.cyan[400]),
            const SizedBox(height: 24),
            Text(
              'Habit Tracker',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan[400]!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
