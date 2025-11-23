import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _client = Supabase.instance.client;

  // Auth Methods
  Future<bool> register(String username, String password) async {
    try {
      // Cek apakah username sudah ada
      final existingUsers = await _client
          .from('users')
          .select()
          .eq('username', username);

      if (existingUsers.isNotEmpty) {
        print('Username already exists');
        return false;
      }

      final response = await _client.auth.signUp(
        email: '$username@habit-tracker.local',
        password: password,
      );

      if (response.user != null) {
        // Insert user data ke tabel users
        await _client.from('users').insert({
          'id': response.user!.id,
          'username': username,
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: '$username@habit-tracker.local',
        password: password,
      );
      return response.user != null;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  // Habit Methods
  Future<List<Map<String, dynamic>>> getHabits() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return [];

      final response = await _client
          .from('habits')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get habits error: $e');
      return [];
    }
  }

  Future<bool> addHabit(String id, String title, String? color) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return false;

      await _client.from('habits').insert({
        'id': id,
        'user_id': userId,
        'title': title,
        'color': color ?? 'cyan',
      });
      return true;
    } catch (e) {
      print('Add habit error: $e');
      return false;
    }
  }

  Future<bool> updateHabit(String id, String title) async {
    try {
      await _client
          .from('habits')
          .update({
            'title': title,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', id);
      return true;
    } catch (e) {
      print('Update habit error: $e');
      return false;
    }
  }

  Future<bool> deleteHabit(String id) async {
    try {
      await _client.from('habits').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Delete habit error: $e');
      return false;
    }
  }

  // Habit Completion Methods
  Future<bool> toggleHabitCompletion(String habitId, String dateKey, bool isCompleted) async {
    try {
      final existing = await _client
          .from('habit_completions')
          .select()
          .eq('habit_id', habitId)
          .eq('completed_date', dateKey);

      if (existing.isNotEmpty) {
        await _client
            .from('habit_completions')
            .delete()
            .eq('habit_id', habitId)
            .eq('completed_date', dateKey);
      } else {
        await _client.from('habit_completions').insert({
          'habit_id': habitId,
          'completed_date': dateKey,
          'is_completed': true,
        });
      }
      return true;
    } catch (e) {
      print('Toggle completion error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getHabitCompletions(String habitId) async {
    try {
      final response = await _client
          .from('habit_completions')
          .select()
          .eq('habit_id', habitId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get completions error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCompletionsForDate(String dateKey) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return [];

      final response = await _client
          .from('habit_completions')
          .select('habit_id')
          .eq('completed_date', dateKey);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get completions for date error: $e');
      return [];
    }
  }

  // Journal Methods
  Future<bool> addJournalEntry(String id, String content, String dateEntry) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return false;

      await _client.from('journal_entries').insert({
        'id': id,
        'user_id': userId,
        'content': content,
        'entry_date': dateEntry,
      });
      return true;
    } catch (e) {
      print('Add journal entry error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getJournalEntries() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return [];

      final response = await _client
          .from('journal_entries')
          .select()
          .eq('user_id', userId)
          .order('entry_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get journal entries error: $e');
      return [];
    }
  }

  Future<bool> deleteJournalEntry(String id) async {
    try {
      await _client.from('journal_entries').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Delete journal entry error: $e');
      return false;
    }
  }
}