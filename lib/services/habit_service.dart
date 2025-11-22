import '../models/habit.dart';

class HabitService {
  static final HabitService _instance = HabitService._internal();
  factory HabitService() => _instance;
  HabitService._internal();

  final List<Habit> _habits = [];

  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<Habit> getAllHabits() => _habits;

  void toggleHabit(String id, DateTime date) {
    final habit = _habits.firstWhere((h) => h.id == id);
    habit.toggleCompletionOnDate(date);
  }

  void addHabit(Habit habit) {
    _habits.add(habit);
  }
  void updateHabit(String id, Habit updatedHabit) {
  final index = _habits.indexWhere((h) => h.id == id);
  if (index != -1) {
    _habits[index] = updatedHabit;
  }
}

  void deleteHabit(String id) {
    _habits.removeWhere((h) => h.id == id);
  }

  int getCompletedCountForDate(DateTime date) {
    return _habits.where((h) => h.isCompletedOnDate(date)).length;
  }

  int getTotalCount() {
    return _habits.length;
  }

  double getProgressForDate(DateTime date) {
    if (_habits.isEmpty) return 0.0;
    return getCompletedCountForDate(date) / getTotalCount();
  }

  bool hasCompletionOnDate(DateTime date) {
    return _habits.any((h) => h.isCompletedOnDate(date));
  }
}