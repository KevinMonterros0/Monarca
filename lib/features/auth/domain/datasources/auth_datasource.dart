import '../entities/user.dart';

abstract class AuthDatasource{

  Future<User> login(String username,String password);
  Future<User> checkAuthStatus(String token);
}