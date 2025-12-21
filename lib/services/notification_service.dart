import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _permissionGranted = false;
  bool _exactAlarmGranted = false;
  SharedPreferences? _prefs;

  static const String _keyDailyReminderHour = 'notification_daily_hour';
  static const String _keyDailyReminderMinute = 'notification_daily_minute';
  static const String _keyIncompleteReminderHour =
      'notification_incomplete_hour';
  static const String _keyIncompleteReminderMinute =
      'notification_incomplete_minute';
  static const String _keyNotificationsEnabled = 'notification_enabled';
  static const String _keyDailyReminderEnabled = 'notification_daily_enabled';
  static const String _keyIncompleteReminderEnabled =
      'notification_incomplete_enabled';

  static const int dailyReminderId = 1;
  static const int incompleteReminderId = 2;
  static const int streakNotificationId = 100;
  static const int weeklySummaryId = 200;
  static const int weeklySummaryScheduleId = 201;
  static const int testNotificationId = 999;

  static const String channelId = 'habit_tracker_channel';
  static const String channelName = 'Habit Tracker';
  static const String channelDesc = 'Notifications for habit reminders';

  bool get isInitialized => _isInitialized;
  bool get permissionGranted => _permissionGranted;
  bool get exactAlarmGranted => _exactAlarmGranted;

  Future<void> initialize({bool requestPermission = false}) async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();

      tz_data.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

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

      await _checkPermissionStatus();
      await _checkExactAlarmPermission();

      if (requestPermission && !_permissionGranted) {
        await this.requestPermission();
      }

      await _rescheduleSavedNotifications();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _checkExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 31) {
        final android = _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (android != null) {
          _exactAlarmGranted =
              await android.canScheduleExactNotifications() ?? false;

          if (!_exactAlarmGranted) {
            await android.requestExactAlarmsPermission();
            _exactAlarmGranted =
                await android.canScheduleExactNotifications() ?? false;
          }
        }
      } else {
        _exactAlarmGranted = true;
      }
    } else {
      _exactAlarmGranted = true;
    }
  }

  Future<void> _rescheduleSavedNotifications() async {
    if (_prefs == null) return;

    final notificationsEnabled =
        _prefs?.getBool(_keyNotificationsEnabled) ?? false;
    if (!notificationsEnabled) return;

    final dailyEnabled = _prefs?.getBool(_keyDailyReminderEnabled) ?? false;
    if (dailyEnabled) {
      final hour = _prefs?.getInt(_keyDailyReminderHour);
      final minute = _prefs?.getInt(_keyDailyReminderMinute);
      if (hour != null && minute != null) {
        await scheduleDailyReminder(
          TimeOfDay(hour: hour, minute: minute),
          savePrefs: false,
        );
      }
    }

    final incompleteEnabled =
        _prefs?.getBool(_keyIncompleteReminderEnabled) ?? false;
    if (incompleteEnabled) {
      final hour = _prefs?.getInt(_keyIncompleteReminderHour);
      final minute = _prefs?.getInt(_keyIncompleteReminderMinute);
      if (hour != null && minute != null) {
        await scheduleIncompleteReminder(
          TimeOfDay(hour: hour, minute: minute),
          [],
          savePrefs: false,
        );
      }
    }
  }

  Future<void> _saveSchedule({
    int? dailyHour,
    int? dailyMinute,
    int? incompleteHour,
    int? incompleteMinute,
  }) async {
    if (dailyHour != null)
      await _prefs?.setInt(_keyDailyReminderHour, dailyHour);
    if (dailyMinute != null)
      await _prefs?.setInt(_keyDailyReminderMinute, dailyMinute);
    if (incompleteHour != null)
      await _prefs?.setInt(_keyIncompleteReminderHour, incompleteHour);
    if (incompleteMinute != null)
      await _prefs?.setInt(_keyIncompleteReminderMinute, incompleteMinute);
  }

  Future<void> _checkPermissionStatus() async {
    if (Platform.isAndroid) {
      _permissionGranted = await Permission.notification.isGranted;
    } else if (Platform.isIOS) {
      _permissionGranted = true;
    }
  }

  Future<Map<String, dynamic>> getNotificationStatus() async {
    await _checkPermissionStatus();
    final pendingNotifications = await _notifications
        .pendingNotificationRequests();

    return {
      'isInitialized': _isInitialized,
      'permissionGranted': _permissionGranted,
      'pendingNotifications': pendingNotifications.length,
      'pendingNotificationIds': pendingNotifications.map((n) => n.id).toList(),
      'platform': Platform.operatingSystem,
    };
  }

  Future<void> printDebugInfo() async {
    final status = await getNotificationStatus();
    print('NOTIFICATION DEBUG INFO');
    print('Initialized: ${status['isInitialized']}');
    print('Permission Granted: ${status['permissionGranted']}');
    print('Platform: ${status['platform']}');
    print('Pending Notifications: ${status['pendingNotifications']}');
  }

  Future<bool> showTestNotification() async {
    if (!_isInitialized) return false;
    if (!_permissionGranted) return false;

    try {
      await _notifications.show(
        testNotificationId,
        'Test Notification',
        'Notifikasi berfungsi dengan baik! Waktu: ${DateTime.now().toString().substring(11, 19)}',
        _getNotificationDetails(),
        payload: 'test_notification',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
  }

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

  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    }
    return true;
  }

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

  Future<void> scheduleDailyReminder(
    TimeOfDay time, {
    bool savePrefs = true,
  }) async {
    await _cancelNotification(dailyReminderId);

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      dailyReminderId,
      'Waktunya Habit!',
      'Jangan lupa selesaikan habit hari ini!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      _getNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );

    if (savePrefs) {
      await _saveSchedule(dailyHour: time.hour, dailyMinute: time.minute);
    }
  }

  Future<void> scheduleIncompleteReminder(
    TimeOfDay time,
    List<String> habitTitles, {
    bool savePrefs = true,
  }) async {
    await _cancelNotification(incompleteReminderId);

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    String body;
    if (habitTitles.isEmpty) {
      body = 'Cek habit yang belum selesai hari ini!';
    } else {
      final habitCount = habitTitles.length;
      body = habitCount == 1
          ? 'Masih ada habit "${habitTitles[0]}" yang belum selesai'
          : 'Masih ada $habitCount habit yang belum selesai: ${habitTitles.take(3).join(", ")}${habitCount > 3 ? "..." : ""}';
    }

    await _notifications.zonedSchedule(
      incompleteReminderId,
      'Pengingat Habit',
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      _getNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'incomplete_reminder',
    );

    if (savePrefs) {
      await _saveSchedule(
        incompleteHour: time.hour,
        incompleteMinute: time.minute,
      );
    }
  }

  Future<void> showStreakNotification(
    String habitTitle,
    int streakCount,
  ) async {
    String title;
    String message;

    if (streakCount >= 30) {
      title = 'Streak Luar Biasa!';
      message = 'WOW! $streakCount hari berturut-turut untuk "$habitTitle"!';
    } else if (streakCount >= 14) {
      title = 'Streak Hebat!';
      message = 'Luar biasa! $streakCount hari streak "$habitTitle"!';
    } else if (streakCount >= 7) {
      title = 'Streak Milestone!';
      message = 'Hebat! Sudah $streakCount hari "$habitTitle"!';
    } else {
      title = 'Streak!';
      message = '$streakCount hari streak "$habitTitle"! Lanjutkan!';
    }

    await _notifications.show(
      streakNotificationId + streakCount,
      title,
      message,
      _getNotificationDetails(),
      payload: 'streak_$streakCount',
    );
  }

  Future<void> showWeeklySummary(int completedCount, int totalCount) async {
    final percentage = totalCount > 0
        ? ((completedCount / totalCount) * 100).toInt()
        : 0;

    String title;
    String message;

    if (percentage >= 90) {
      title = 'Ringkasan Mingguan - Luar Biasa!';
      message =
          'Minggu yang luar biasa! $completedCount/$totalCount habit selesai ($percentage%)';
    } else if (percentage >= 70) {
      title = 'Ringkasan Mingguan - Bagus!';
      message =
          'Minggu yang baik! $completedCount/$totalCount habit selesai ($percentage%)';
    } else if (percentage >= 50) {
      title = 'Ringkasan Mingguan';
      message =
          'Terus semangat! $completedCount/$totalCount habit minggu ini ($percentage%)';
    } else {
      title = 'Ringkasan Mingguan';
      message =
          'Minggu depan pasti lebih baik! $completedCount/$totalCount habit ($percentage%)';
    }

    await _notifications.show(
      weeklySummaryId,
      title,
      message,
      _getNotificationDetails(),
      payload: 'weekly_summary',
    );
  }

  Future<void> scheduleWeeklySummary({
    TimeOfDay time = const TimeOfDay(hour: 10, minute: 0),
  }) async {
    await _cancelNotification(weeklySummaryScheduleId);

    final now = DateTime.now();
    var nextSunday = now;

    while (nextSunday.weekday != DateTime.sunday) {
      nextSunday = nextSunday.add(const Duration(days: 1));
    }

    var scheduledDate = DateTime(
      nextSunday.year,
      nextSunday.month,
      nextSunday.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    await _notifications.zonedSchedule(
      weeklySummaryScheduleId,
      'Ringkasan Mingguan',
      'Cek progress habit kamu minggu ini!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      _getNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_summary_scheduled',
    );
  }

  Future<void> cancelWeeklySummary() async {
    await _cancelNotification(weeklySummaryScheduleId);
  }

  Future<void> _cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelDailyReminder() async {
    await _cancelNotification(dailyReminderId);
  }

  Future<void> cancelIncompleteReminder() async {
    await _cancelNotification(incompleteReminderId);
  }
}
