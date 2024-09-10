import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

class RolePermissionsScreen extends ConsumerStatefulWidget {
  final int roleId;

  const RolePermissionsScreen({super.key, required this.roleId});

  @override
  _RolePermissionsScreenState createState() => _RolePermissionsScreenState();
}

class _RolePermissionsScreenState extends ConsumerState<RolePermissionsScreen> {
  List<dynamic> permissions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRolePermissions();
  }

  Future<void> fetchRolePermissions() async {
    try {
      final keyValueStorageService = KeyValueStorageServiceImpl();
      final token = await keyValueStorageService.getValue<String>('token');

      final response = await http.get(
        Uri.parse(
            'https://apiproyectomonarca.fly.dev/api/permisoRoles/obtenerPorId/${widget.roleId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          permissions = json.decode(response.body);
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          permissions = [];
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener los permisos del rol.');
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
        title: const Text('Permisos del Rol'),
        actions: [
          IconButton(
            icon: const Icon(Icons.security, size: 30),
            onPressed: () {
              context.push('/rolePermissionsCreate');
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : permissions.isEmpty
              ? const Center(child: Text('Este rol no tiene permisos asignados.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: permissions.length,
                  itemBuilder: (context, index) {
                    final permission = permissions[index];

                    return GestureDetector(
                      onTap: () {
                        _showDeletePermissionOptions(
                            context, permission['id_perm_rol']);
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
                              Icons.menu_open,
                              size: 60,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              permission['menu'],
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

  void _showDeletePermissionOptions(BuildContext context, int permId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Eliminar Permiso'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(context, permId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, int permId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content:
              const Text('¿Estás seguro de que deseas eliminar este permiso?'),
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
                _deletePermission(permId);
                await fetchRolePermissions();
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePermission(int permId) async {
    try {
      final keyValueStorageService = KeyValueStorageServiceImpl();
      final token = await keyValueStorageService.getValue<String>('token');

      final response = await http.delete(
        Uri.parse(
            'https://apiproyectomonarca.fly.dev/api/permisoRoles/eliminar/$permId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permiso con ID $permId eliminado correctamente.'),
          ),
        );
        await fetchRolePermissions();
      } else {
        throw Exception('Error al eliminar el permiso.');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error al eliminar el permiso.'),
        ),
      );
    }
  }
}
