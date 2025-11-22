class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final List<User> _users = [];
  User? _currentUser;

  User? get currentUser => _currentUser;

  bool register(String username, String password, String confirmPassword) {
    if (username.isEmpty || password.isEmpty) {
      return false;
    }

    if (password != confirmPassword) {
      return false;
    }

    if (_users.any((u) => u.username == username)) {
      return false;
    }

    _users.add(User(username: username, password: password));
    return true;
  }

  bool login(String username, String password) {
    try {
      final user = _users.firstWhere(
        (u) => u.username == username && u.password == password,
      );
      _currentUser = user;
      return true;
    } catch (e) {
      return false;
    }
  }

  void logout() {
    _currentUser = null;
  }
}

class User {
  final String username;
  final String password;

  User({
    required this.username,
    required this.password,
  });
}