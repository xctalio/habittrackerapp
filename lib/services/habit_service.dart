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

  /// Initialize habits dari database
  Future<void> initializeHabits() async {
    if (_isInitialized) return;

    try {
      print('🔄 Initializing habits...');
      final userId = _authService.getCurrentUserId();
      
      if (userId == null) {
        print('❌ User not logged in');
        return;
      }

      print('📥 Loading habits for user: $userId');
      
      // Load habits dari Supabase
      final response = await _supabase
          .from('habits')
          .select()
          .eq('user_id', userId);

      print('📦 Response: $response');

      _habits.clear();
      
      for (var habitData in response) {
        final habit = Habit(
          id: habitData['id'] as String,
          title: habitData['title'] as String,
          createdAt: DateTime.parse(habitData['created_at'] as String),
          color: habitData['color'] as String?,
        );
        _habits.add(habit);
        print('✅ Loaded habit: ${habit.title}');
      }

      _isInitialized = true;
      print('✅ Habits initialized successfully (${_habits.length} habits)');
    } catch (e) {
      print('❌ Error initializing habits: $e');
      rethrow;
    }
  }

  /// Check if habits are initialized
  bool get isInitialized => _isInitialized;

  /// Reset initialization state
  void resetInitialization() {
    _isInitialized = false;
    _habits.clear();
  }

  List<Habit> getAllHabits() => _habits;

  /// Add habit ke database dan memory
  Future<void> addHabit(Habit habit) async {
    try {
      final userId = _authService.getCurrentUserId();
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Check duplicate
      if (_habits.any((h) => h.id == habit.id)) {
        throw Exception('Habit with id ${habit.id} already exists');
      }

      print('💾 Saving habit to database: ${habit.title}');

      // Insert ke Supabase
      await _supabase.from('habits').insert({
        'id': habit.id,
        'user_id': userId,
        'title': habit.title,
        'color': habit.color,
        'created_at': habit.createdAt.toIso8601String(),
      });

      // Add ke memory
      _habits.add(habit);
      print('✅ Habit saved successfully');
    } catch (e) {
      print('❌ Error adding habit: $e');
      rethrow;
    }
  }

  /// Update habit di database dan memory
  Future<void> updateHabit(String id, Habit updatedHabit) async {
    try {
      final index = _habits.indexWhere((h) => h.id == id);
      
      if (index == -1) {
        throw Exception('Habit with id $id not found');
      }

      print('📝 Updating habit: $id');

      // Update di Supabase
      await _supabase.from('habits').update({
        'title': updatedHabit.title,
        'color': updatedHabit.color,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);

      // Update di memory
      _habits[index] = updatedHabit;
      print('✅ Habit updated successfully');
    } catch (e) {
      print('❌ Error updating habit: $e');
      rethrow;
    }
  }

  /// Delete habit dari database dan memory
  Future<void> deleteHabit(String id) async {
    try {
      print('🗑️ Deleting habit: $id');

      // Delete dari Supabase (akan cascade delete habit_completions)
      await _supabase.from('habits').delete().eq('id', id);

      // Delete dari memory
      _habits.removeWhere((h) => h.id == id);
      print('✅ Habit deleted successfully');
    } catch (e) {
      print('❌ Error deleting habit: $e');
      rethrow;
    }
  }

  /// Toggle completion dan save ke database
  Future<void> toggleHabit(String id, DateTime date) async {
    try {
      final habit = _habits.firstWhere((h) => h.id == id);
      final dateKey = formatDate(date);
      final currentStatus = habit.isCompletedOnDate(date);
      final newStatus = !currentStatus;

      print('🔄 Toggling habit $id on $dateKey: $currentStatus -> $newStatus');

      // Update di Supabase
      if (newStatus) {
        // Mark as completed
        await _supabase.from('habit_completions').upsert({
          'habit_id': id,
          'completed_date': dateKey,
          'is_completed': true,
        }, onConflict: 'habit_id,completed_date');
        print('✅ Marked as completed');
      } else {
        // Mark as incomplete
        await _supabase.from('habit_completions').upsert({
          'habit_id': id,
          'completed_date': dateKey,
          'is_completed': false,
        }, onConflict: 'habit_id,completed_date');
        print('✅ Marked as incomplete');
      }

      // Toggle di memory
      habit.toggleCompletionOnDate(date);
    } catch (e) {
      print('❌ Error toggling habit: $e');
      rethrow;
    }
  }

  /// Load completion dates dari database
  Future<void> loadCompletionDates(String habitId) async {
    try {
      print('📥 Loading completion dates for habit: $habitId');

      final response = await _supabase
          .from('habit_completions')
          .select()
          .eq('habit_id', habitId);

      final habit = _habits.firstWhereIndexed((h) => h.id == habitId);
      
      if (habit != null) {
        habit.completionDates.clear();
        for (var item in response) {
          habit.completionDates[item['completed_date']] = 
              item['is_completed'] as bool;
        }
        print('✅ Loaded ${response.length} completion dates');
      }
    } catch (e) {
      print('⚠️ Error loading completion dates: $e');
    }
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

  List<Habit> getCompletedHabitsForDate(DateTime date) {
    return _habits.where((h) => h.isCompletedOnDate(date)).toList();
  }

  List<Habit> getIncompletedHabitsForDate(DateTime date) {
    return _habits.where((h) => !h.isCompletedOnDate(date)).toList();
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
    if (_habits.isEmpty) return 0;
    return ((getCompletedCountForDate(date) / getTotalCount()) * 100).toInt();
  }
}

extension on Iterable<Habit> {
  Habit? firstWhereIndexed(bool Function(Habit) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }
}