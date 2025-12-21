import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _supabase = Supabase.instance.client;
  User? _currentUser;
  String? _currentUsername;
  String? _currentUserId;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  static const String _keyUserId = 'auth_user_id';
  static const String _keyUsername = 'auth_username';
  static const String _keyIsLoggedIn = 'auth_is_logged_in';

  User? get currentUser => _currentUser;
  String? get currentUsername => _currentUsername;
  String? get currentUserId => _currentUserId;
  bool get isInitialized => _isInitialized;

  static String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _restoreSession();
      _isInitialized = true;
      print('AuthService initialized');
    } catch (e) {
      print('AuthService initialization error: $e');
    }
  }

  Future<bool> _restoreSession() async {
    try {
      final isLoggedIn = _prefs?.getBool(_keyIsLoggedIn) ?? false;

      if (isLoggedIn) {
        final userId = _prefs?.getString(_keyUserId);
        final username = _prefs?.getString(_keyUsername);

        if (userId != null && username != null) {
          final userData = await _supabase
              .from('users')
              .select('id, username')
              .eq('id', int.parse(userId))
              .maybeSingle();

          if (userData != null) {
            _currentUserId = userId;
            _currentUsername = username;
            _currentUser = User(
              id: userId,
              username: username,
              password: '', // Password not stored for security
            );
            print('Session restored for user: $username');
            return true;
            return true;
          } else {
            await _clearSession(); - user not found in database');
          }
        }
      }

      print('No active session found');
      return false;
    } catch (e) {
      print('Session restore error: $e');
      return false;
    }
    }
  }

  Future<void> _saveSession() async {
      await _prefs?.setBool(_keyIsLoggedIn, true);
      await _prefs?.setString(_keyUserId, _currentUserId ?? '');
      await _prefs?.setString(_keyUsername, _currentUsername ?? '');
      print('Session saved');
    } catch (e) {
      print('Session save error: $e');
    }
  }
    }
  }

  Future<void> _clearSession() async {dIn);
      await _prefs?.remove(_keyUserId);
      await _prefs?.remove(_keyUsername);
      print('Session cleared');
    } catch (e) {
      print('Session clear error: $e');
    }
  }
    }
  }

  Future<bool> hasActiveSession() async {
    }
    return _currentUser != null;
  }

  bool register(String username, String password, String confirmPassword) {
    if (username.isEmpty || password.isEmpty) {
      return false;
    }

    if (password != confirmPassword) {
      return false;
    }

    if (password.length < 6) {
      return false;
    }

    return true;
  }

  Future<bool> registerAsync(
    String username,
    String password,
    String confirmPassword,
  ) async {
    try {
      print('=== REGISTER ASYNC START ===');

      if (username.isEmpty || password.isEmpty) {
        print('Username or password is empty');
        return false;
      }

      if (password != confirmPassword) {
        print('Passwords do not match');
        return false;
      }

      if (password.length < 6) {
        print('Password too short');
        return false;
      }

      print('Checking if username already exists...');
      try {
        final existingUsers = await _supabase
            .from('users')
            .select('id, username')
            .eq('username', username);

        print('Existing users result: $existingUsers');

        if (existingUsers.isNotEmpty) {
          print('Username already exists in database');
          return false;
        }
        print('Username is available');
      } catch (checkError) {
        print('Error checking username: $checkError');
        if (checkError.toString().contains('column') ||
            checkError.toString().contains('relation')) {
          print('Database table error: $checkError');
          return false;
        }
      }

      final hashedPassword = _hashPassword(password);

      print('Inserting user to database...');
      final response = await _supabase.from('users').insert({
        'username': username,
        'password_hash': hashedPassword,
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (response.isNotEmpty) {
        print('User registered successfully');
        final userId = response[0]['id'].toString();
        _currentUser = User(id: userId, username: username, password: password);
        _currentUsername = username;
        _currentUserId = userId;

        _currentUserId = userId;

        await _saveSession();Id');
        print('=== REGISTER ASYNC SUCCESS ===');
        return true;
      }

      print('User registration returned empty');
      return false;
    } catch (e) {
      print('Register async error: $e');
      return false;
    }
  }

  Future<bool> loginAsync(String username, String password) async {
    try {
      print('=== LOGIN ASYNC START ===');

      if (username.isEmpty || password.isEmpty) {
        print('Username or password is empty');
        return false;
      }

      final hashedPassword = _hashPassword(password);

      print('Searching for user: $username');
      final userData = await _supabase
          .from('users')
          .select('id, username, password_hash')
          .eq('username', username);

      if (userData.isEmpty) {
        print('User not found');
        return false;
      }

      final user = userData[0];
      final storedPasswordHash = user['password_hash'] as String;

      if (storedPasswordHash != hashedPassword) {
        print('Invalid password');
        return false;
      }

      print('Login successful for user: ${user['username']}');
      final userId = user['id'].toString();
      _currentUser = User(
        id: userId,
        username: user['username'] as String,
        password: password,
      );
      _currentUsername = user['username'] as String;
      _currentUserId = userId;

      // Save session
      _currentUserId = userId;

      await _saveSession();C SUCCESS ===');
      return true;
    } catch (e) {
      print('Login async error: $e');
      return false;
    }
  }

  bool login(String username, String password) {
    try {
      if (username.isEmpty || password.isEmpty) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logoutAsync() async {
    try {
      _currentUser = null;
      _currentUsername = null;
      _currentUserId = null;

      // Clear session
      _currentUserId = null;

      await _clearSession();
      print('Logout error: $e');
    }
  }

  void logout() {
    _currentUser = null;
    _currentUsername = null;
    _currentUserId = null;
    _clearSession();
  }

  String? getCurrentUserId() {
    return _currentUserId;
  }

  bool isLoggedIn() {
    return _currentUser != null;
  }

  Future<void> clearAuthData() async {
    try {
      await logoutAsync();
      print('Auth data cleared');
    } catch (e) {
      print('Error clearing auth data: $e');
    }
  }
}

class User {
  final String? id;
  final String username;
  final String password;

  User({this.id, required this.username, required this.password});
}
