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

  bool isCompletedOnDate(DateTime date) {
    final dateKey = _formatDate(date);
    return completionDates[dateKey] ?? false;
  }

  void toggleCompletionOnDate(DateTime date) {
    final dateKey = _formatDate(date);
    completionDates[dateKey] = !(completionDates[dateKey] ?? false);
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}