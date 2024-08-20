import 'package:monarca/features/auth/domain/domain.dart';

class UserMapper{
  static User userJsonToEntity(Map<String,dynamic> json) => 
  User(
  message:json['message'],
  token: json['token']);
}