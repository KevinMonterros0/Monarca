import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

final rolesProvider = StateNotifierProvider<RolesNotifier, RolesState>((ref) {
  return RolesNotifier();
});

class RolesNotifier extends StateNotifier<RolesState> {
  RolesNotifier() : super(RolesState());

  Future<void> fetchRoles() async {
    try {
      final token =
          await KeyValueStorageServiceImpl().getValue<String>('token');
      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/roles/obtener'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> rolesList = json.decode(response.body);
        state = state.copyWith(roles: rolesList);
      } else {
        throw Exception('Error al obtener la lista de roles.');
      }
    } catch (e) {
      print('Error al obtener la lista de roles: $e');
    }
  }
}

class RolesState {
  final List<dynamic> roles;

  RolesState({this.roles = const []});

  RolesState copyWith({List<dynamic>? roles}) {
    return RolesState(
      roles: roles ?? this.roles,
    );
  }
}

class RolesScreen extends ConsumerStatefulWidget {
  const RolesScreen({super.key});

  @override
  _RolesScreenState createState() => _RolesScreenState();
}

class _RolesScreenState extends ConsumerState<RolesScreen> {
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.read(rolesProvider.notifier).fetchRoles();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = (width / 200).floor();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 30),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Roles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, size: 30),
            onPressed: () {
              context.push('/rolesCreate');
            },
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final rolesState = ref.watch(rolesProvider);

          if (rolesState.roles.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: rolesState.roles.length,
            itemBuilder: (context, index) {
              final role = rolesState.roles[index];

              return GestureDetector(
                onTap: () {
                  _showRoleOptions(context, role['id_rol'], role['nombre']);
                },
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.security,
                        size: 60,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        role['nombre'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRoleOptions(BuildContext context, int roleId, String roleName) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.toggle_on),
                title: const Text('Activar / Inactivar'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleRoleState(roleId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleRoleState(int roleId) async {
    try {
      final token =
          await KeyValueStorageServiceImpl().getValue<String>('token');

      final response = await http.get(
        Uri.parse(
            'https://apiproyectomonarca.fly.dev/api/roles/obtenerEstados/$roleId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> estadoList = json.decode(response.body);
        final bool currentState = estadoList.first['estado'];

        final newState = !currentState;

        final changeResponse = await http.put(
          Uri.parse(
              'https://apiproyectomonarca.fly.dev/api/roles/cambiarEstado/$roleId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'estado': newState}),
        );

        if (changeResponse.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('El estado del rol se ha actualizado a $newState'),
            ),
          );

          ref.read(rolesProvider.notifier).fetchRoles();
        } else {
          throw Exception('Error al cambiar el estado del rol');
        }
      } else {
        throw Exception('Error al obtener el estado del rol');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error al cambiar el estado del rol.'),
        ),
      );
    }
  }
}
