import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'journal_screen.dart';
import '../widgets/notification_widgets.dart';
import '../services/in_app_notification_service.dart';
import '../services/habit_service.dart';
import '../services/notification_settings_service.dart';
import '../services/notification_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final _habitService = HabitService();
  final _notificationSettings = NotificationSettingsService();
  final _notificationService = NotificationService();
  final _inAppNotification = InAppNotificationService();
  bool _hasCheckedIncomplete = false;

  late final List<Widget> _screens = [
    const HomeScreen(),
    const StatsScreen(),
    const CalendarScreen(),
    const JournalScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIncompleteHabits();
      _scheduleWeeklySummary();
      _showWeeklySummaryIfSunday();
    });
  }

  Future<void> _checkIncompleteHabits() async {
    if (_hasCheckedIncomplete) return;
    _hasCheckedIncomplete = true;

    await Future.delayed(const Duration(milliseconds: 500));

    if (_notificationSettings.notificationsEnabled &&
        _notificationSettings.incompleteReminderEnabled) {
      final incompleteHabits = _habitService.getIncompletedHabitsForDate(
        DateTime.now(),
      );

      if (incompleteHabits.isNotEmpty) {
        _inAppNotification.showIncompleteReminder(
          incompleteHabits.map((h) => h.title).toList(),
        );
      }
    }
  }

  Future<void> _scheduleWeeklySummary() async {
    if (_notificationSettings.notificationsEnabled &&
        _notificationSettings.weeklySummaryEnabled) {
      await _notificationService.scheduleWeeklySummary(
        time: const TimeOfDay(hour: 10, minute: 0), // Sunday 10:00 AM
      );
    }
  }

  Future<void> _showWeeklySummaryIfSunday() async {
  Future<void> _showWeeklySummaryIfSunday() async {
    final now = DateTime.now();

    if (now.weekday == DateTime.sunday &&
        now.hour >= 8 &&
        now.hour <= 12 &&
        _notificationSettings.weeklySummaryEnabled) {
      final weekAgo = now.subtract(const Duration(days: 7));
      int totalHabits = 0;

      for (int i = 0; i < 7; i++) {
        final date = weekAgo.add(Duration(days: i));
        final activeHabits = _habitService.getActiveHabitsForDate(date);
        final completedHabits = _habitService.getCompletedHabitsForDate(date);
        totalHabits += activeHabits.length;
        totalCompleted += completedHabits.length;
      }

      if (totalHabits > 0) {
        _inAppNotification.showWeeklySummary(totalCompleted, totalHabits);
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NotificationBanner(
      child: Scaffold(
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
              label: 'Calendar',
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
      ),
    );
  }
}
