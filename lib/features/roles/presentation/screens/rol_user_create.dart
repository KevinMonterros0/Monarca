import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:monarca/features/auth/presentation/providers/users_provider.dart';
import 'dart:convert';
import 'package:monarca/features/shared/widgets/custom_filled_button.dart';
import 'package:monarca/features/shared/widgets/geometrical_background.dart';

class RolUserCreate extends ConsumerStatefulWidget {
  const RolUserCreate({super.key});

  @override
  _RolUserCreateState createState() => _RolUserCreateState();
}

class _RolUserCreateState extends ConsumerState<RolUserCreate> {
  List<dynamic> users = [];
  List<dynamic> roles = [];
  dynamic selectedUser;
  dynamic selectedRole;
  bool isLoadingUsers = true;
  bool isLoadingRoles = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
    fetchRoles();
  }

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
        setState(() {
          users = json.decode(response.body);
          isLoadingUsers = false;
        });
      } else {
        throw Exception('Error al obtener los usuarios.');
      }
    } catch (e) {
      setState(() {
        isLoadingUsers = false;
      });
      print('Error al obtener los usuarios: $e');
    }
  }

  Future<void> fetchRoles() async {
    final token = await keyValueStorageService.getValue<String>('token');
    try {
      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/roles/obtener'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          roles = json.decode(response.body);
          isLoadingRoles = false;
        });
      } else {
        throw Exception('Error al obtener los roles.');
      }
    } catch (e) {
      setState(() {
        isLoadingRoles = false;
      });
      print('Error al obtener los roles: $e');
    }
  }

  Future<void> assignRoleToUser(int userId, int roleId) async {
    try {
      final token = await keyValueStorageService.getValue<String>('token');
      final response = await http.post(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/rolUsuarios/crear'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'Id_Usuario': userId,
          'Id_Rol': roleId,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rol asignado correctamente a Usuario ID: $userId')),
        );
      } else {
        throw Exception('Error al asignar el rol.');
      }
    } catch (e) {
      print('Error al asignar el rol: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al asignar el rol al usuario.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: GeometricalBackground(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, size: 40, color: Colors.white),
                    ),
                    const Spacer(flex: 1),
                    const Text(
                      'Asignar Rol a Usuario',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
                const SizedBox(height: 50),
                Container(
                  height: size.height - 260,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scaffoldBackgroundColor,
                    borderRadius:
                        const BorderRadius.only(topLeft: Radius.circular(100)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 150),
                        isLoadingUsers
                            ? const CircularProgressIndicator()
                            : DropdownButton<dynamic>(
                                hint: const Text('Selecciona un usuario'),
                                value: selectedUser,
                                onChanged: (dynamic newValue) {
                                  setState(() {
                                    selectedUser = newValue;
                                  });
                                },
                                items: users
                                    .map<DropdownMenuItem<dynamic>>((user) {
                                  return DropdownMenuItem<dynamic>(
                                    value: user,
                                    child: Text(user['username']),
                                  );
                                }).toList(),
                              ),
                        const SizedBox(height: 50),
                        isLoadingRoles
                            ? const CircularProgressIndicator()
                            : DropdownButton<dynamic>(
                                hint: const Text('Selecciona un rol'),
                                value: selectedRole,
                                onChanged: (dynamic newValue) {
                                  setState(() {
                                    selectedRole = newValue;
                                  });
                                },
                                items: roles
                                    .map<DropdownMenuItem<dynamic>>((role) {
                                  return DropdownMenuItem<dynamic>(
                                    value: role,
                                    child: Text(role['nombre']),
                                  );
                                }).toList(),
                              ),
                        const SizedBox(height: 60),
                        // Botón de acción
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: CustomFilledButton(
                            text: 'Confirmar',
                            onPressed: () {
                              if (selectedUser != null &&
                                  selectedRole != null) {
                                final int userId = selectedUser['id_usuario'];
                                final int roleId = selectedRole['id_rol'];

                                // Asignar rol a usuario llamando a la API
                                assignRoleToUser(userId, roleId);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Selecciona un usuario y un rol.'),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
