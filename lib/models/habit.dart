import 'dart:math';

class Habit {
  final String id;
  final String title;
  final DateTime createdAt;
  final String? color;
  final Map<String, bool> completionDates;
  final String recurrenceType; // 'daily', 'weekly', 'monthly'
  final List<int> recurrenceDays; // For weekly: [0-6] for days
  final int? recurrenceDate; // For monthly: 1-31

  Habit({
    required this.id,
    required this.title,
    required this.createdAt,
    this.color,
    Map<String, bool>? completionDates,
    this.recurrenceType = 'daily',
    List<int>? recurrenceDays,
    this.recurrenceDate,
  })  : completionDates = completionDates ?? {},
        recurrenceDays = recurrenceDays ?? [];

  bool isActiveOnDate(DateTime date) {
    switch (recurrenceType) {
      case 'daily':
        return true;
      case 'weekly':
        int dayOfWeek = date.weekday % 7;
        return recurrenceDays.contains(dayOfWeek);
      case 'monthly':
        return date.day == recurrenceDate;
      default:
        return true;
    }
  }

  bool isCompletedOnDate(DateTime date) {
    final dateKey = _formatDate(date);
    return completionDates[dateKey] ?? false;
  }

  void toggleCompletionOnDate(DateTime date) {
    final dateKey = _formatDate(date);
    completionDates[dateKey] = !(completionDates[dateKey] ?? false);
  }

  void markCompletedOnDate(DateTime date) {
    final dateKey = _formatDate(date);
    completionDates[dateKey] = true;
  }

  void markIncompleteOnDate(DateTime date) {
    final dateKey = _formatDate(date);
    completionDates[dateKey] = false;
  }

  int getTotalCompletedDays() {
    return completionDates.values.where((completed) => completed).length;
  }

  int getCurrentStreak() {
    if (completionDates.isEmpty) return 0;

    final today = DateTime.now();
    int streak = 0;
    DateTime currentDate = today;

    while (true) {
      if (!isActiveOnDate(currentDate)) {
        currentDate = currentDate.subtract(const Duration(days: 1));
        continue;
      }

      final dateKey = _formatDate(currentDate);
      if (completionDates[dateKey] == true) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  int getLongestStreak() {
    if (completionDates.isEmpty) return 0;

    final sortedDates = completionDates.entries
        .where((e) => e.value)
        .map((e) => DateTime.parse(e.key))
        .toList()
        ..sort();

    if (sortedDates.isEmpty) return 0;

    int longestStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final prevDate = sortedDates[i - 1];
      final currDate = sortedDates[i];

      if (!isActiveOnDate(prevDate) || !isActiveOnDate(currDate)) {
        currentStreak = 1;
        continue;
      }

      final difference = currDate.difference(prevDate).inDays;
      if (difference == 1) {
        currentStreak++;
        longestStreak = max(longestStreak, currentStreak);
      } else {
        currentStreak = 1;
      }
    }

    return longestStreak;
  }

  Habit copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    String? color,
    Map<String, bool>? completionDates,
    String? recurrenceType,
    List<int>? recurrenceDays,
    int? recurrenceDate,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      color: color ?? this.color,
      completionDates: completionDates ?? Map.from(this.completionDates),
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceDays: recurrenceDays ?? List.from(this.recurrenceDays),
      recurrenceDate: recurrenceDate ?? this.recurrenceDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'color': color,
      'completionDates': completionDates,
      'recurrenceType': recurrenceType,
      'recurrenceDays': recurrenceDays,
      'recurrenceDate': recurrenceDate,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      color: json['color'] as String?,
      completionDates: Map<String, bool>.from(json['completionDates'] as Map? ?? {}),
      recurrenceType: json['recurrenceType'] as String? ?? 'daily',
      recurrenceDays: List<int>.from(json['recurrenceDays'] as List? ?? []),
      recurrenceDate: json['recurrenceDate'] as int?,
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  String toString() =>
      'Habit(id: $id, title: $title, recurrence: $recurrenceType, createdAt: $createdAt)';
}