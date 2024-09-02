import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monarca/features/auth/presentation/providers/register_form_notifier.dart';
import 'package:monarca/features/auth/presentation/providers/register_form_state.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

final registerFormProvider = StateNotifierProvider.autoDispose<RegisterFormNotifier, RegisterFormState>((ref) {
  final keyValueStorageService = KeyValueStorageServiceImpl();
  registerUserCallback(String username, String password, int employeeId) async {
    final token = await keyValueStorageService.getValue<String>('token');
    final response = await http.post(
      Uri.parse('https://apiproyectomonarca.fly.dev/api/usuarios/registrar'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
        'id_empleado': employeeId,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al registrar el usuario');
    }
  }

  return RegisterFormNotifier(registerUserCallback: registerUserCallback);
});
