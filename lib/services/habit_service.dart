import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/habit.dart';
import 'auth_service.dart';

class HabitService {
  static final HabitService _instance = HabitService._internal();
  factory HabitService() => _instance;
  HabitService._internal();

  final _supabase = Supabase.instance.client;
  final _authService = AuthService();
  final List<Habit> _habits = [];
  bool _isInitialized = false;

  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> initializeHabits() async {
    if (_isInitialized) return;

    try {
      print('Initializing habits...');
      final userId = _authService.getCurrentUserId();

      if (userId == null) {
        print('User not logged in');
        return;
      }

      print('Loading habits for user: $userId');

      final habitsResponse = await _supabase
          .from('habits')
          .select()
          .eq('user_id', userId.toString());

      print('Habits Response: $habitsResponse');

      _habits.clear();

      for (var habitData in habitsResponse) {
        final habitId = habitData['id'] as String;

        final recurrenceDays = <int>[];
        if (habitData['recurrence_days'] != null) {
          final days = habitData['recurrence_days'] as List;
          recurrenceDays.addAll(days.map((d) => d as int));
        }

        final habit = Habit(
          id: habitId,
          title: habitData['title'] as String,
          createdAt: DateTime.parse(habitData['created_at'] as String),
          color: habitData['color'] as String?,
          recurrenceType: habitData['recurrence_type'] as String? ?? 'daily',
          recurrenceDays: recurrenceDays,
          recurrenceDate: habitData['recurrence_date'] as int?,
        );
        _habits.add(habit);
        print('Loaded habit: ${habit.title} (${habit.recurrenceType})');

        await _loadCompletionDatesForHabit(habitId);
      }

      _isInitialized = true;
      print('Habits initialized successfully (${_habits.length} habits total)');
    } catch (e) {
      print('Error initializing habits: $e');
      rethrow;
    }
  }

  Future<void> _loadCompletionDatesForHabit(String habitId) async {
    try {
      print('Loading completion dates for habit: $habitId');

      final response = await _supabase
          .from('habit_completions')
          .select()
          .eq('habit_id', habitId);

      final habitIndex = _habits.indexWhere((h) => h.id == habitId);

      if (habitIndex != -1) {
        final habit = _habits[habitIndex];
        habit.completionDates.clear();

        for (var item in response) {
          final dateKey = item['completed_date'] as String;
          final isCompleted = item['is_completed'] as bool;
          habit.completionDates[dateKey] = isCompleted;
        }

        print('Loaded ${response.length} completion dates for habit: $habitId');
      }
    } catch (e) {
      print('Error loading completion dates for $habitId: $e');
    }
  }

  bool get isInitialized => _isInitialized;

  void resetInitialization() {
    _isInitialized = false;
    _habits.clear();
  }

  List<Habit> getAllHabits() => _habits;

  Future<void> addHabit(Habit habit) async {
    try {
      final userId = _authService.getCurrentUserId();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      if (_habits.any((h) => h.id == habit.id)) {
        throw Exception('Habit with id ${habit.id} already exists');
      }

      print('Saving habit to database: ${habit.title}');

      await _supabase.from('habits').insert({
        'id': habit.id,
        'user_id': userId.toString(),
        'title': habit.title,
        'color': habit.color,
        'created_at': habit.createdAt.toIso8601String(),
        'recurrence_type': habit.recurrenceType,
        'recurrence_days': habit.recurrenceDays.isEmpty
            ? null
            : habit.recurrenceDays,
        'recurrence_date': habit.recurrenceDate,
      });

      _habits.add(habit);
      print('Habit saved successfully (1 habit created)');
    } catch (e) {
      print('Error adding habit: $e');
      rethrow;
    }
  }

  Future<void> updateHabit(String id, Habit updatedHabit) async {
    try {
      final index = _habits.indexWhere((h) => h.id == id);

      if (index == -1) {
        throw Exception('Habit with id $id not found');
      }

      print('Updating habit: $id');

      await _supabase
          .from('habits')
          .update({
            'title': updatedHabit.title,
            'color': updatedHabit.color,
            'recurrence_type': updatedHabit.recurrenceType,
            'recurrence_days': updatedHabit.recurrenceDays.isEmpty
                ? null
                : updatedHabit.recurrenceDays,
            'recurrence_date': updatedHabit.recurrenceDate,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      _habits[index] = updatedHabit;
      print('Habit updated successfully');
    } catch (e) {
      print('Error updating habit: $e');
      rethrow;
    }
  }

  Future<void> deleteHabit(String id) async {
    try {
      print('Deleting habit: $id');

      await _supabase.from('habits').delete().eq('id', id);

      _habits.removeWhere((h) => h.id == id);
      print('Habit deleted successfully');
    } catch (e) {
      print('Error deleting habit: $e');
      rethrow;
    }
  }

  Future<void> toggleHabit(String id, DateTime date) async {
    try {
      final habit = _habits.firstWhere((h) => h.id == id);

      if (!habit.isActiveOnDate(date)) {
        print(
          'Habit tidak active di tanggal ini (recurrence: ${habit.recurrenceType})',
        );
        throw Exception('Habit tidak tersedia di tanggal ini');
      }

      final dateKey = formatDate(date);
      final currentStatus = habit.isCompletedOnDate(date);
      final newStatus = !currentStatus;

      print('Toggling habit $id on $dateKey: $currentStatus → $newStatus');

      await _supabase.from('habit_completions').upsert({
        'habit_id': id,
        'completed_date': dateKey,
        'is_completed': newStatus,
      }, onConflict: 'habit_id,completed_date');

      print('Toggled in database');

      habit.toggleCompletionOnDate(date);
      print('Toggled in memory');
    } catch (e) {
      print('Error toggling habit: $e');
      rethrow;
    }
  }

  Future<void> reloadAllCompletionDates() async {
    try {
      print('Reloading all completion dates...');
      for (var habit in _habits) {
        await _loadCompletionDatesForHabit(habit.id);
      }
      print('All completion dates reloaded');
    } catch (e) {
      print('Error reloading completion dates: $e');
    }
  }

  List<Habit> getActiveHabitsForDate(DateTime date) {
    return _habits.where((h) => h.isActiveOnDate(date)).toList();
  }

  int getCompletedCountForDate(DateTime date) {
    return getActiveHabitsForDate(
      date,
    ).where((h) => h.isCompletedOnDate(date)).length;
  }

  int getTotalCount() {
    return _habits.length;
  }

  double getProgressForDate(DateTime date) {
    final active = getActiveHabitsForDate(date);
    if (active.isEmpty) return 0.0;
    final completed = active.where((h) => h.isCompletedOnDate(date)).length;
    return completed / active.length;
  }

  bool hasCompletionOnDate(DateTime date) {
    return getActiveHabitsForDate(date).any((h) => h.isCompletedOnDate(date));
  }

  List<Habit> getCompletedHabitsForDate(DateTime date) {
    return getActiveHabitsForDate(
      date,
    ).where((h) => h.isCompletedOnDate(date)).toList();
  }

  List<Habit> getIncompletedHabitsForDate(DateTime date) {
    return getActiveHabitsForDate(
      date,
    ).where((h) => !h.isCompletedOnDate(date)).toList();
  }

  Habit? getHabitById(String id) {
    try {
      return _habits.firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Habit> searchHabits(String query) {
    return _habits
        .where((h) => h.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  int getCompletionPercentageForDate(DateTime date) {
    final active = getActiveHabitsForDate(date);
    if (active.isEmpty) return 0;
    final completed = active.where((h) => h.isCompletedOnDate(date)).length;
    return ((completed / active.length) * 100).toInt();
  }
}
