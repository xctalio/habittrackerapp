import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _supabase = Supabase.instance.client;
  User? _currentUser;
  String? _currentUsername;
  String? _currentUserId;

  User? get currentUser => _currentUser;
  String? get currentUsername => _currentUsername;
  String? get currentUserId => _currentUserId;

  /// Hash password untuk keamanan
  static String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
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

      // Cek apakah username sudah ada di tabel users
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

      // Hash password
      final hashedPassword = _hashPassword(password);

      // Insert ke tabel users
      print('Inserting user to database...');
      final response = await _supabase.from('users').insert({
        'username': username,
        'password_hash': hashedPassword,
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (response.isNotEmpty) {
        print('User registered successfully');
        final userId = response[0]['id'].toString(); // Convert to String
        _currentUser = User(id: userId, username: username, password: password);
        _currentUsername = username;
        _currentUserId = userId;
        print('User ID: $userId');
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

      // Hash password untuk compare
      final hashedPassword = _hashPassword(password);

      // Cari user di database
      print('Searching for user: $username');
      final userData = await _supabase
          .from('users')
          .select('id, username, password_hash')
          .eq('username', username);

      if (userData.isEmpty) {
        print('User not found');
        return false;
      }

      // Verify password
      final user = userData[0];
      final storedPasswordHash = user['password_hash'] as String;

      if (storedPasswordHash != hashedPassword) {
        print('Invalid password');
        return false;
      }

      print('Login successful for user: ${user['username']}');
      final userId = user['id'].toString(); // Convert to String
      _currentUser = User(
        id: userId,
        username: user['username'] as String,
        password: password,
      );
      _currentUsername = user['username'] as String;
      _currentUserId = userId;
      print('User ID: $userId');
      print('=== LOGIN ASYNC SUCCESS ===');
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
      print('Logout successful');
    } catch (e) {
      print('Logout error: $e');
    }
  }

  void logout() {
    _currentUser = null;
    _currentUsername = null;
    _currentUserId = null;
  }

  String? getCurrentUserId() {
    return _currentUserId;
  }

  bool isLoggedIn() {
    return _currentUser != null;
  }

  /// Clear all auth data (untuk testing/debugging)
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
