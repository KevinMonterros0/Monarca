import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static final UserSession _instance = UserSession._internal();
  UserSession._internal();

  factory UserSession() {
    return _instance;
  }

  String? _username;
  int? _userId;

  Future<void> setUsername(String username) async {
    _username = username;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  Future<String?> getUsername() async {
    if (_username != null) {
      return _username;
    }
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username');
    return _username;
  }

  Future<void> setUserId(int userId) async {
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);
  }

  Future<int?> getUserId() async {
    if (_userId != null) {
      return _userId;
    }
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId');
    return _userId;
  }

  Future<void> clearSession() async {
    _username = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('userId');
  }
}
