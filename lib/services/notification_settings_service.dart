import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsService {
  static final NotificationSettingsService _instance =
      NotificationSettingsService._internal();
  factory NotificationSettingsService() => _instance;
  NotificationSettingsService._internal();

  SharedPreferences? _prefs;

  // Keys for SharedPreferences
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _dailyReminderEnabledKey = 'daily_reminder_enabled';
  static const String _dailyReminderHourKey = 'daily_reminder_hour';
  static const String _dailyReminderMinuteKey = 'daily_reminder_minute';
  static const String _incompleteReminderEnabledKey =
      'incomplete_reminder_enabled';
  static const String _incompleteReminderHourKey = 'incomplete_reminder_hour';
  static const String _incompleteReminderMinuteKey =
      'incomplete_reminder_minute';
  static const String _streakNotificationsEnabledKey =
      'streak_notifications_enabled';
  static const String _weeklySummaryEnabledKey = 'weekly_summary_enabled';

  // Default values
  static const TimeOfDay defaultDailyReminderTime = TimeOfDay(
    hour: 8,
    minute: 0,
  );
  static const TimeOfDay defaultIncompleteReminderTime = TimeOfDay(
    hour: 20,
    minute: 0,
  );

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Master toggle for all notifications
  bool get notificationsEnabled {
    return _prefs?.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs?.setBool(_notificationsEnabledKey, value);
  }

  // Daily reminder settings
  bool get dailyReminderEnabled {
    return _prefs?.getBool(_dailyReminderEnabledKey) ?? true;
  }

  Future<void> setDailyReminderEnabled(bool value) async {
    await _prefs?.setBool(_dailyReminderEnabledKey, value);
  }

  TimeOfDay get dailyReminderTime {
    final hour =
        _prefs?.getInt(_dailyReminderHourKey) ?? defaultDailyReminderTime.hour;
    final minute =
        _prefs?.getInt(_dailyReminderMinuteKey) ??
        defaultDailyReminderTime.minute;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setDailyReminderTime(TimeOfDay time) async {
    await _prefs?.setInt(_dailyReminderHourKey, time.hour);
    await _prefs?.setInt(_dailyReminderMinuteKey, time.minute);
  }

  // Incomplete reminder settings
  bool get incompleteReminderEnabled {
    return _prefs?.getBool(_incompleteReminderEnabledKey) ?? true;
  }

  Future<void> setIncompleteReminderEnabled(bool value) async {
    await _prefs?.setBool(_incompleteReminderEnabledKey, value);
  }

  TimeOfDay get incompleteReminderTime {
    final hour =
        _prefs?.getInt(_incompleteReminderHourKey) ??
        defaultIncompleteReminderTime.hour;
    final minute =
        _prefs?.getInt(_incompleteReminderMinuteKey) ??
        defaultIncompleteReminderTime.minute;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setIncompleteReminderTime(TimeOfDay time) async {
    await _prefs?.setInt(_incompleteReminderHourKey, time.hour);
    await _prefs?.setInt(_incompleteReminderMinuteKey, time.minute);
  }

  // Streak notifications
  bool get streakNotificationsEnabled {
    return _prefs?.getBool(_streakNotificationsEnabledKey) ?? true;
  }

  Future<void> setStreakNotificationsEnabled(bool value) async {
    await _prefs?.setBool(_streakNotificationsEnabledKey, value);
  }

  // Weekly summary
  bool get weeklySummaryEnabled {
    return _prefs?.getBool(_weeklySummaryEnabledKey) ?? true;
  }

  Future<void> setWeeklySummaryEnabled(bool value) async {
    await _prefs?.setBool(_weeklySummaryEnabledKey, value);
  }

  // Format time for display
  String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Reset all settings to default
  Future<void> resetToDefaults() async {
    await setNotificationsEnabled(true);
    await setDailyReminderEnabled(true);
    await setDailyReminderTime(defaultDailyReminderTime);
    await setIncompleteReminderEnabled(true);
    await setIncompleteReminderTime(defaultIncompleteReminderTime);
    await setStreakNotificationsEnabled(true);
    await setWeeklySummaryEnabled(true);
  }
}
