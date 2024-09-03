import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static final UserSession _instance = UserSession._internal();
  UserSession._internal();

  factory UserSession() {
    return _instance;
  }

  String? _username;

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

  Future<void> clearSession() async {
    _username = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
  }
}
