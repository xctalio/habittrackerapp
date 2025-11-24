import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/journal_entry.dart';
import 'auth_service.dart';

class JournalService {
  static final JournalService _instance = JournalService._internal();
  factory JournalService() => _instance;
  JournalService._internal();

  final _supabase = Supabase.instance.client;
  final _authService = AuthService();
  final List<JournalEntry> _entries = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize journal entries dari database
  Future<void> initializeJournal() async {
    if (_isInitialized) return;

    try {
      print('Initializing journal...');
      final userId = _authService.getCurrentUserId();

      if (userId == null) {
        print('User not logged in');
        return;
      }

      print('Loading journal entries for user: $userId');

      // Load entries dari Supabase, sorted by newest first
      final response = await _supabase
          .from('journal_entries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      print('Journal Response: $response');

      _entries.clear();

      for (var entryData in response) {
        final entry = JournalEntry(
          id: entryData['id'] as String,
          content: entryData['content'] as String,
          createdAt: DateTime.parse(entryData['created_at'] as String),
          dateEntry: DateTime.parse(
            entryData['entry_date'] as String,
          ), // Parse ke DateTime
        );
        _entries.add(entry);
        print('Loaded entry: ${entry.id}');
      }

      _isInitialized = true;
      print('Journal initialized successfully (${_entries.length} entries)');
    } catch (e) {
      print('Error initializing journal: $e');
      rethrow;
    }
  }

  List<JournalEntry> getAllEntries() => _entries;

  /// Add entry ke database dan memory
  Future<void> addEntry(JournalEntry entry) async {
    try {
      final userId = _authService.getCurrentUserId();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      print('Saving journal entry to database: ${entry.id}');

      // Insert ke Supabase
      await _supabase.from('journal_entries').insert({
        'id': entry.id,
        'user_id': userId,
        'content': entry.content,
        'entry_date': entry.dateEntry
            .toIso8601String(), // Convert DateTime ke String untuk DB
        'created_at': entry.createdAt.toIso8601String(),
      });

      // Add ke memory (di awal karena newest first)
      _entries.insert(0, entry);
      print('Entry saved successfully');
    } catch (e) {
      print('Error adding entry: $e');
      rethrow;
    }
  }

  /// Update entry di database dan memory
  Future<void> updateEntry(String id, JournalEntry updatedEntry) async {
    try {
      final index = _entries.indexWhere((e) => e.id == id);

      if (index == -1) {
        throw Exception('Entry with id $id not found');
      }

      print('Updating journal entry: $id');

      // Update di Supabase
      await _supabase
          .from('journal_entries')
          .update({
            'content': updatedEntry.content,
            'entry_date': updatedEntry.dateEntry
                .toIso8601String(), // Convert ke String
            'created_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      // Update di memory
      _entries[index] = JournalEntry(
        id: updatedEntry.id,
        content: updatedEntry.content,
        createdAt: DateTime.now(),
        dateEntry: updatedEntry.dateEntry,
      );

      // Sort ulang untuk newest first
      _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('Entry updated successfully');
    } catch (e) {
      print('Error updating entry: $e');
      rethrow;
    }
  }

  /// Delete entry dari database dan memory
  Future<void> deleteEntry(String id) async {
    try {
      print('Deleting journal entry: $id');

      // Delete dari Supabase
      await _supabase.from('journal_entries').delete().eq('id', id);

      // Delete dari memory
      _entries.removeWhere((e) => e.id == id);
      print('Entry deleted successfully');
    } catch (e) {
      print('Error deleting entry: $e');
      rethrow;
    }
  }

  /// Search entries
  List<JournalEntry> searchEntries(String query) {
    if (query.isEmpty) {
      return _entries;
    }
    return _entries
        .where((e) => e.content.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Reset initialization state
  void resetInitialization() {
    _isInitialized = false;
    _entries.clear();
  }
}
