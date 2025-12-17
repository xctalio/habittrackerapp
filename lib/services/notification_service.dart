import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Notification IDs
  static const int dailyReminderId = 1;
  static const int incompleteReminderId = 2;
  static const int streakNotificationId = 100; // 100+ for streak notifications
  static const int weeklySummaryId = 200;

  // Channel IDs
  static const String channelId = 'habit_tracker_channel';
  static const String channelName = 'Habit Tracker';
  static const String channelDesc = 'Notifications for habit reminders';

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    print('NotificationService initialized');
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle notification tap - can navigate to specific screen
  }

  // Request notification permissions
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    return false;
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    }
    return true;
  }

  // Get notification details
  NotificationDetails _getNotificationDetails({bool isOngoing = false}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        ongoing: isOngoing,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // Schedule daily reminder
  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await _cancelNotification(dailyReminderId);

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      dailyReminderId,
      '🎯 Waktunya Habit!',
      'Jangan lupa selesaikan habit hari ini!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      _getNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );

    print('Daily reminder scheduled for ${time.hour}:${time.minute}');
  }

  // Schedule incomplete habits reminder
  Future<void> scheduleIncompleteReminder(
    TimeOfDay time,
    List<String> habitTitles,
  ) async {
    await _cancelNotification(incompleteReminderId);

    if (habitTitles.isEmpty) return;

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final habitCount = habitTitles.length;
    final body = habitCount == 1
        ? 'Masih ada habit "${habitTitles[0]}" yang belum selesai'
        : 'Masih ada $habitCount habit yang belum selesai: ${habitTitles.take(3).join(", ")}${habitCount > 3 ? "..." : ""}';

    await _notifications.zonedSchedule(
      incompleteReminderId,
      '⏰ Pengingat Habit',
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      _getNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'incomplete_reminder',
    );

    print('Incomplete reminder scheduled for ${time.hour}:${time.minute}');
  }

  // Show immediate streak notification
  Future<void> showStreakNotification(
    String habitTitle,
    int streakCount,
  ) async {
    String emoji;
    String message;

    if (streakCount >= 30) {
      emoji = '🏆';
      message = 'WOW! $streakCount hari berturut-turut untuk "$habitTitle"!';
    } else if (streakCount >= 14) {
      emoji = '🔥';
      message = 'Luar biasa! $streakCount hari streak "$habitTitle"!';
    } else if (streakCount >= 7) {
      emoji = '⭐';
      message = 'Hebat! Sudah $streakCount hari "$habitTitle"!';
    } else {
      emoji = '💪';
      message = '$streakCount hari streak "$habitTitle"! Lanjutkan!';
    }

    await _notifications.show(
      streakNotificationId + streakCount,
      '$emoji Streak Milestone!',
      message,
      _getNotificationDetails(),
      payload: 'streak_$streakCount',
    );

    print('Streak notification shown: $streakCount days');
  }

  // Show weekly summary notification
  Future<void> showWeeklySummary(int completedCount, int totalCount) async {
    final percentage = totalCount > 0
        ? ((completedCount / totalCount) * 100).toInt()
        : 0;

    String emoji;
    String message;

    if (percentage >= 90) {
      emoji = '🏆';
      message =
          'Minggu yang luar biasa! $completedCount/$totalCount habit selesai ($percentage%)';
    } else if (percentage >= 70) {
      emoji = '👍';
      message =
          'Minggu yang baik! $completedCount/$totalCount habit selesai ($percentage%)';
    } else if (percentage >= 50) {
      emoji = '💪';
      message =
          'Terus semangat! $completedCount/$totalCount habit minggu ini ($percentage%)';
    } else {
      emoji = '🎯';
      message =
          'Minggu depan pasti lebih baik! $completedCount/$totalCount habit ($percentage%)';
    }

    await _notifications.show(
      weeklySummaryId,
      '$emoji Ringkasan Mingguan',
      message,
      _getNotificationDetails(),
      payload: 'weekly_summary',
    );

    print('Weekly summary shown: $completedCount/$totalCount');
  }

  // Cancel specific notification
  Future<void> _cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    print('All notifications cancelled');
  }

  // Cancel daily reminder
  Future<void> cancelDailyReminder() async {
    await _cancelNotification(dailyReminderId);
    print('Daily reminder cancelled');
  }

  // Cancel incomplete reminder
  Future<void> cancelIncompleteReminder() async {
    await _cancelNotification(incompleteReminderId);
    print('Incomplete reminder cancelled');
  }
}
