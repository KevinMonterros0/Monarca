import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:monarca/features/auth/presentation/providers/auth_provider.dart';
import 'dart:convert';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';
import 'package:monarca/features/shared/widgets/geometrical_background.dart';
import 'package:monarca/features/shared/widgets/custom_filled_button.dart';
import 'package:monarca/features/shared/widgets/custom_text_form_field.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  final int userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  _UserDetailScreenState createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  Map<String, dynamic>? userDetails;
  bool isLoading = true;
  String _username = '';
  String _password = '';
  bool isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
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
          _username = userDetails!['username'];
          isLoading = false;
        });
      }else if (response.statusCode == 403){
        ref.read(authProvider.notifier).logout();
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

  Future<void> updateUser() async {
    try {
      final token =
          await KeyValueStorageServiceImpl().getValue<String>('token');

      final Map<String, dynamic> body = {
        'username': _username,
      };

      if (_password.isNotEmpty) {
        body['password'] = _password;
      }

      final response = await http.put(
        Uri.parse(
            'https://apiproyectomonarca.fly.dev/api/usuarios/actualizar/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario actualizado exitosamente')),
        );
        context.push('/users');
      } else {
        throw Exception('Error al actualizar el usuario.');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ocurrió un error al actualizar el usuario.')),
      );
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
                      onPressed: () => context.push('/users'),
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
                  height: size.height - 260,
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
                                  CustomTextFormField(
                                    label: 'Username',
                                    initialValue: _username,
                                    onChanged: (value) {
                                      setState(() {
                                        _username = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 30),
                                  CustomTextFormField(
                                    label: 'Contraseña',
                                    obscureText: !isPasswordVisible,
                                    onChanged: (value) {
                                      setState(() {
                                        _password = value;
                                      });
                                    },
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        isPasswordVisible
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          isPasswordVisible =
                                              !isPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 50),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 60,
                                    child: CustomFilledButton(
                                      text: 'Actualizar',
                                      buttonColor: const Color(0xFF283B71),
                                      onPressed: updateUser,
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
