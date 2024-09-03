import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  final int userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  _UserDetailScreenState createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  Map<String, dynamic>? userDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    try {
      final token = await KeyValueStorageServiceImpl().getValue<String>('token');
      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/usuarios/obtenerPorId/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );



      if (response.statusCode == 200) {
        setState(() {
          userDetails = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener los detalles del usuario');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Usuario'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userDetails == null
              ? const Center(child: Text('No se pudo cargar la información del usuario.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Username: ${userDetails!['username']}', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 10),
                      Text('URL: ${userDetails!['url']}', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 10),
                      Icon(Icons.person, size: 50),
                      // Puedes agregar más campos según la respuesta de la API
                    ],
                  ),
                ),
    );
  }
}
