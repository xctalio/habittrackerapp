import 'dart:math';

class Habit {
  final String id;
  final String title;
  final DateTime createdAt;
  final String? color;
  final Map<String, bool> completionDates;

  Habit({
    required this.id,
    required this.title,
    required this.createdAt,
    this.color,
    Map<String, bool>? completionDates,
  }) : completionDates = completionDates ?? {};

  /// Check if habit is completed on a specific date
  bool isCompletedOnDate(DateTime date) {
    final dateKey = _formatDate(date);
    return completionDates[dateKey] ?? false;
  }

  /// Toggle completion status for a specific date
  void toggleCompletionOnDate(DateTime date) {
    final dateKey = _formatDate(date);
    completionDates[dateKey] = !(completionDates[dateKey] ?? false);
  }

  /// Mark habit as completed on a specific date
  void markCompletedOnDate(DateTime date) {
    final dateKey = _formatDate(date);
    completionDates[dateKey] = true;
  }

  /// Mark habit as incomplete on a specific date
  void markIncompleteOnDate(DateTime date) {
    final dateKey = _formatDate(date);
    completionDates[dateKey] = false;
  }

  /// Get total days completed
  int getTotalCompletedDays() {
    return completionDates.values.where((completed) => completed).length;
  }

  /// Get current streak (consecutive days completed)
  int getCurrentStreak() {
    if (completionDates.isEmpty) return 0;

    final today = DateTime.now();
    int streak = 0;
    DateTime currentDate = today;

    while (true) {
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

  /// Get longest streak
  int getLongestStreak() {
    if (completionDates.isEmpty) return 0;

    final sortedDates =
        completionDates.entries
            .where((e) => e.value)
            .map((e) => DateTime.parse(e.key))
            .toList()
          ..sort();

    if (sortedDates.isEmpty) return 0;

    int longestStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final difference = sortedDates[i].difference(sortedDates[i - 1]).inDays;
      if (difference == 1) {
        currentStreak++;
        longestStreak = max(longestStreak, currentStreak);
      } else {
        currentStreak = 1;
      }
    }

    return longestStreak;
  }

  /// Create a copy of this habit with some fields replaced
  Habit copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    String? color,
    Map<String, bool>? completionDates,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      color: color ?? this.color,
      completionDates: completionDates ?? Map.from(this.completionDates),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'color': color,
      'completionDates': completionDates,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      color: json['color'] as String?,
      completionDates: Map<String, bool>.from(
        json['completionDates'] as Map? ?? {},
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => 'Habit(id: $id, title: $title, createdAt: $createdAt)';
}
