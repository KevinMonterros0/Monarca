class UserSession {
  static final UserSession _instance = UserSession._internal();
  UserSession._internal();

  factory UserSession() {
    return _instance;
  }
  String? username;
}