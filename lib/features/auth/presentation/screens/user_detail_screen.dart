import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';
import 'package:monarca/features/shared/widgets/geometrical_background.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  final int userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  _UserDetailScreenState createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  Map<String, dynamic>? userDetails;
  bool isLoading = true;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    fetchUserDetails();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> fetchUserDetails() async {
    try {
      final token =
          await KeyValueStorageServiceImpl().getValue<String>('token');
      final response = await http.get(
        Uri.parse(
            'https://apiproyectomonarca.fly.dev/api/usuarios/obtenerPorId/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          userDetails = json.decode(response.body);
          _usernameController.text = userDetails!['username'];
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
    final size = MediaQuery.of(context).size;
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textStyles = Theme.of(context).textTheme;
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
                      onPressed: () => context.push('/'),
                      icon: const Icon(Icons.arrow_back_rounded,
                          size: 40, color: Colors.white),
                    ),
                    const Spacer(flex: 1),
                    const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 100,
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
                const SizedBox(height: 80),
                Container(
                  height: size.height - 260, // Ajuste del contenido interno
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(100),
                    ),
                  ),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : userDetails == null
                          ? const Center(
                              child: Text(
                                  'No se pudo cargar la información del usuario.'))
                          : Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Column(
                                children: [
                                  const SizedBox(height: 50),
                                  Text('Modificar',
                                      style: textStyles.titleMedium),
                                  const SizedBox(height: 50),
                                  TextField(
                                    controller: _usernameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Username',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  TextField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Contraseña',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 50),
                                  ElevatedButton(
                                    onPressed: () {},
                                    child: const Text('Actualizar'),
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
