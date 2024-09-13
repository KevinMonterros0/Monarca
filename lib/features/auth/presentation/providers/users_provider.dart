// user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';
  final keyValueStorageService = KeyValueStorageServiceImpl();
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier() : super(UserState()) {
    fetchUsers();
  }

  List<User> allUsers = []; 

  Future<void> fetchUsers() async {
    try {
      final token = await keyValueStorageService.getValue<String>('token');
      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/usuarios/obtener'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<User> users = data.map((user) => User.fromJson(user)).toList();
        allUsers = users; 
        state = state.copyWith(users: users);
      } else {
        throw Exception('Error al obtener los usuarios');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void filterUsersByName(String query) {
    if (query.isEmpty) {
      state = state.copyWith(users: allUsers);
    } else {
      final filteredUsers = allUsers.where((user) {
        return user.username.toLowerCase().contains(query.toLowerCase());
      }).toList();
      state = state.copyWith(users: filteredUsers);
    }
  }
}


class UserState {
  final List<User> users;

  UserState({this.users = const []});

  UserState copyWith({List<User>? users}) {
    return UserState(
      users: users ?? this.users,
    );
  }
}

class User {
  final int id; 
  final String username;

  User({required this.id, required this.username});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id_usuario'], 
      username: json['username'],
    );
  }
}

