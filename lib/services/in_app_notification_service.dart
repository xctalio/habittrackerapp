import 'package:flutter/material.dart';

class InAppNotification {
  final String id;
  final String title;
  final String message;
  final InAppNotificationType type;
  final DateTime createdAt;
  final VoidCallback? onTap;
  bool isRead;

  InAppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    DateTime? createdAt,
    this.onTap,
    this.isRead = false,
  }) : createdAt = createdAt ?? DateTime.now();
}

enum InAppNotificationType { reminder, streak, achievement, warning, info }

class InAppNotificationService extends ChangeNotifier {
  static final InAppNotificationService _instance =
      InAppNotificationService._internal();
  factory InAppNotificationService() => _instance;
  InAppNotificationService._internal();

  final List<InAppNotification> _notifications = [];
  bool _showBanner = false;
  InAppNotification? _currentBanner;

  List<InAppNotification> get notifications =>
      List.unmodifiable(_notifications);
  List<InAppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  bool get showBanner => _showBanner;
  InAppNotification? get currentBanner => _currentBanner;

  void addNotification({
    required String title,
    required String message,
    InAppNotificationType type = InAppNotificationType.info,
    VoidCallback? onTap,
    bool showBanner = true,
  }) {
    final notification = InAppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      onTap: onTap,
    );

    _notifications.insert(0, notification);

    if (_notifications.length > 50) {
      _notifications.removeLast();
    }

    if (showBanner) {
      _showBannerNotification(notification);
    }

    notifyListeners();
  }

  void showReminderNotification(String habitTitle, {VoidCallback? onTap}) {
    addNotification(
      title: 'Pengingat Habit',
      message: 'Jangan lupa selesaikan "$habitTitle" hari ini!',
      type: InAppNotificationType.reminder,
      onTap: onTap,
    );
  }

  void showIncompleteReminder(List<String> habitTitles, {VoidCallback? onTap}) {
    if (habitTitles.isEmpty) return;

    final count = habitTitles.length;
    final message = count == 1
        ? 'Masih ada habit "${habitTitles[0]}" yang belum selesai'
        : 'Masih ada $count habit yang belum selesai: ${habitTitles.take(3).join(", ")}${count > 3 ? "..." : ""}';

    addNotification(
      title: 'Habit Belum Selesai',
      message: message,
      type: InAppNotificationType.reminder,
      onTap: onTap,
    );
  }

  void showStreakNotification(
    String habitTitle,
    int streakCount, {
    VoidCallback? onTap,
  }) {
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

    addNotification(
      title: title,
      message: message,
      type: InAppNotificationType.streak,
      onTap: onTap,
    );
  }

  void showWeeklySummary(
    int completedCount,
    int totalCount, {
    VoidCallback? onTap,
  }) {
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

    addNotification(
      title: title,
      message: message,
      type: InAppNotificationType.achievement,
      onTap: onTap,
    );
  }

  void _showBannerNotification(InAppNotification notification) {
    _currentBanner = notification;
    _showBanner = true;
    notifyListeners();

    Future.delayed(const Duration(seconds: 4), () {
      if (_currentBanner?.id == notification.id) {
        hideBanner();
      }
    });
  }

  void hideBanner() {
    _showBanner = false;
    _currentBanner = null;
    notifyListeners();
  }

  void markAsRead(String id) {
    final notification = _notifications.firstWhere(
      (n) => n.id == id,
      orElse: () => throw Exception('Notification not found'),
    );
    notification.isRead = true;
    notifyListeners();
  }

  void markAllAsRead() {
    for (var notification in _notifications) {
      notification.isRead = true;
    }
    notifyListeners();
  }

  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  static IconData getIconForType(InAppNotificationType type) {
    switch (type) {
      case InAppNotificationType.reminder:
        return Icons.access_time;
      case InAppNotificationType.streak:
        return Icons.local_fire_department;
      case InAppNotificationType.achievement:
        return Icons.emoji_events;
      case InAppNotificationType.warning:
        return Icons.warning;
      case InAppNotificationType.info:
        return Icons.info;
    }
  }

  static Color getColorForType(InAppNotificationType type) {
    switch (type) {
      case InAppNotificationType.reminder:
        return Colors.blue;
      case InAppNotificationType.streak:
        return Colors.orange;
      case InAppNotificationType.achievement:
        return Colors.amber;
      case InAppNotificationType.warning:
        return Colors.red;
      case InAppNotificationType.info:
        return Colors.cyan;
    }
  }
}
