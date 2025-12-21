import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsService {
  static final NotificationSettingsService _instance =
      NotificationSettingsService._internal();
  factory NotificationSettingsService() => _instance;
  NotificationSettingsService._internal();

  SharedPreferences? _prefs;

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
    _prefs = await SharedPreferences.getInstance();
  }

  bool get notificationsEnabled {icationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs?.setBool(_notificationsEnabledKey, value);
  }
    await _prefs?.setBool(_notificationsEnabledKey, value);
  }

  bool get dailyReminderEnabled {

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
    await _prefs?.setInt(_dailyReminderMinuteKey, time.minute);
  }

  bool get incompleteReminderEnabled {

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

    await _prefs?.setInt(_incompleteReminderMinuteKey, time.minute);
  }

  bool get streakNotificationsEnabled {
  Future<void> setStreakNotificationsEnabled(bool value) async {
    await _prefs?.setBool(_streakNotificationsEnabledKey, value);
  }

  // Weekly summary
    await _prefs?.setBool(_streakNotificationsEnabledKey, value);
  }

  bool get weeklySummaryEnabled {abled(bool value) async {
    await _prefs?.setBool(_weeklySummaryEnabledKey, value);
  }

  // Format time for display
    await _prefs?.setBool(_weeklySummaryEnabledKey, value);
  }

  String formatTime(TimeOfDay time) {

  // Reset all settings to default
  Future<void> resetToDefaults() async {
    return '$hour:$minute';
  }

  Future<void> resetToDefaults() async {ultIncompleteReminderTime);
    await setStreakNotificationsEnabled(true);
    await setWeeklySummaryEnabled(true);
  }
}
