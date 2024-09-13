import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:monarca/features/shared/widgets/custom_filled_button.dart';
import 'package:monarca/features/shared/widgets/geometrical_background.dart';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

class RoleMenuScreen extends ConsumerStatefulWidget {
  const RoleMenuScreen({super.key});

  @override
  _RoleMenuScreenState createState() => _RoleMenuScreenState();
}

class _RoleMenuScreenState extends ConsumerState<RoleMenuScreen> {
  List<dynamic> roles = [];
  List<dynamic> menus = [];
  dynamic selectedRole;
  dynamic selectedMenu;
  bool isLoadingRoles = true;
  bool isLoadingMenus = true;

  @override
  void initState() {
    super.initState();
    fetchRoles();
    fetchMenus();
  }

  Future<void> fetchRoles() async {
    try {
      final token = await KeyValueStorageServiceImpl().getValue<String>('token');
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

  Future<void> fetchMenus() async {
    try {
      final token = await KeyValueStorageServiceImpl().getValue<String>('token');
      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/menus/obtener'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          menus = json.decode(response.body);
          isLoadingMenus = false;
        });
      } else {
        throw Exception('Error al obtener los menús.');
      }
    } catch (e) {
      setState(() {
        isLoadingMenus = false;
      });
      print('Error al obtener los menús: $e');
    }
  }

  Future<void> assignMenuToRole(int roleId, int menuId) async {
    try {
      final token = await KeyValueStorageServiceImpl().getValue<String>('token');
      final response = await http.post(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/permisoRoles/crear'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_rol': roleId,
          'id_menu': menuId,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menú asignado correctamente al rol')),
        );
        context.go('/roles');
      } else {
        throw Exception('Error al asignar el menú al rol.');
      }
    } catch (e) {
      print('Error al asignar el menú al rol: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al asignar el menú al rol.')),
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
                      'Asignar Menú a Rol',
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
                        const SizedBox(height: 50),
                        isLoadingMenus
                            ? const CircularProgressIndicator()
                            : DropdownButton<dynamic>(
                                hint: const Text('Selecciona un menú'),
                                value: selectedMenu,
                                onChanged: (dynamic newValue) {
                                  setState(() {
                                    selectedMenu = newValue;
                                  });
                                },
                                items: menus
                                    .map<DropdownMenuItem<dynamic>>((menu) {
                                  return DropdownMenuItem<dynamic>(
                                    value: menu,
                                    child: Text(menu['nombre']),
                                  );
                                }).toList(),
                              ),
                        const SizedBox(height: 60),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: CustomFilledButton(
                            text: 'Asignar',
                            onPressed: () {
                              if (selectedRole != null && selectedMenu != null) {
                                final int roleId = selectedRole['id_rol'];
                                final int menuId = selectedMenu['id_menu'];

                                assignMenuToRole(roleId, menuId);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Selecciona un rol y un menú.'),
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
