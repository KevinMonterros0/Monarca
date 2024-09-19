import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

class DireccionesScreen extends ConsumerStatefulWidget {
  final int idCliente;

  const DireccionesScreen({super.key, required this.idCliente});

  @override
  _DireccionesScreenState createState() => _DireccionesScreenState();
}

class _DireccionesScreenState extends ConsumerState<DireccionesScreen> {
  List<dynamic> direcciones = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDirecciones();
  }

  Future<void> fetchDirecciones() async {
    try {
      final token = await KeyValueStorageServiceImpl().getValue<String>('token');
      final response = await http.get(
        Uri.parse(
            'https://apiproyectomonarca.fly.dev/api/direcciones/obtenerDireccionCliente/${widget.idCliente}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          direcciones = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener las direcciones del cliente.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  Future<void> _toggleDireccionState(int direccionId) async {
    try {
      final token = await KeyValueStorageServiceImpl().getValue<String>('token');

      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/direcciones/obtenerEstado/$direccionId'),
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
          Uri.parse('https://apiproyectomonarca.fly.dev/api/direcciones/cambiarEstado/$direccionId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'estado': newState}),
        );

        if (changeResponse.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('El estado de la dirección se ha actualizado a $newState')),
          );
          fetchDirecciones();
        } else {
          throw Exception('Error al cambiar el estado de la dirección.');
        }
      } else {
        throw Exception('Error al obtener el estado de la dirección.');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un error al cambiar el estado de la dirección.')),
      );
    }
  }

  void _showDireccionOptions(BuildContext context, int direccionId) {
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
                  _toggleDireccionState(direccionId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Direcciones del Cliente'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 30),
          onPressed: () {
            context.pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.directions_sharp, size: 30),
            onPressed: () {
              context.push('/direccionesClienteCreate', extra: widget.idCliente);
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : direcciones.isEmpty
              ? const Center(child: Text('No hay direcciones disponibles para este cliente.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: direcciones.length,
                  itemBuilder: (context, index) {
                    final direccion = direcciones[index];
                    final bool isActive = direccion['estado'] ?? true;
                    return Card(
                      color: isActive ? Colors.white : Colors.grey[300],
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(direccion['direccion']),
                        trailing: IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () => _showDireccionOptions(context, direccion['id_direccion']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
