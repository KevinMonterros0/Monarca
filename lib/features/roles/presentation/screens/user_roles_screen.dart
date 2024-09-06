import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

class UserRolesScreen extends ConsumerStatefulWidget {
  final int userId;

  const UserRolesScreen({super.key, required this.userId});

  @override
  _UserRolesScreenState createState() => _UserRolesScreenState();
}

class _UserRolesScreenState extends ConsumerState<UserRolesScreen> {
  List<dynamic> roles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserRoles();
  }

  Future<void> fetchUserRoles() async {
    try {
      final keyValueStorageService = KeyValueStorageServiceImpl();
      final token = await keyValueStorageService.getValue<String>('token');

      final response = await http.get(
        Uri.parse(
            'https://apiproyectomonarca.fly.dev/api/rolUsuarios/obtenerPorId/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          roles = json.decode(response.body);
          isLoading = false;
        });
      }else if (response.statusCode == 404){
        setState(() {
          roles = [];
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener los roles del usuario.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
    }
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
            context.pop();
          },
        ),
        title: const Text('Roles del Usuario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, size: 30),
            onPressed: () {
              context.push('/registerusers');
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : roles.isEmpty
              ? const Center(child: Text('Este usuario no tiene roles asignados.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: roles.length,
                  itemBuilder: (context, index) {
                    final role = roles[index];

                    return GestureDetector(
                      onTap: () {
                        _showDeleteRoleOptions(context, role['id_rol_usuario']);
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
                ),
    );
  }

  void _showDeleteRoleOptions(BuildContext context, int roleId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Eliminar Rol'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(context, roleId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, int roleId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text('¿Estás seguro de que deseas eliminar este rol?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); 
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); 
                _deleteRole(roleId);
                await fetchUserRoles();
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRole(int roleId) async {
    try {
      final keyValueStorageService = KeyValueStorageServiceImpl();
      final token = await keyValueStorageService.getValue<String>('token');

      final response = await http.delete(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/rolUsuarios/eliminar/$roleId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rol con ID $roleId eliminado correctamente.'),
          ),
        );
        await fetchUserRoles();
      } else {
        throw Exception('Error al eliminar el rol.');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error al eliminar el rol.'),
        ),
      );
    }
  }
}
