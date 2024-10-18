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

class ClienteDetailScreen extends ConsumerStatefulWidget {
  final int clienteId;

  const ClienteDetailScreen({super.key, required this.clienteId});

  @override
  _ClienteDetailScreenState createState() => _ClienteDetailScreenState();
}

class _ClienteDetailScreenState extends ConsumerState<ClienteDetailScreen> {
  Map<String, dynamic>? clienteDetails;
  bool isLoading = true;
  String _nombre = '';
  String _nit = '';
  String _telefono = '';

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchClienteDetails();
  }

  Future<void> fetchClienteDetails() async {
    try {
      final token = await KeyValueStorageServiceImpl().getValue<String>('token');
      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/clientes/obtenerPorId/${widget.clienteId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          clienteDetails = json.decode(response.body);
          _nombre = clienteDetails!['nombre'];
          _nit = clienteDetails!['nit'];
          _telefono = clienteDetails!['telefono'];
          isLoading = false;
        });
      }else if (response.statusCode == 403){
        ref.read(authProvider.notifier).logout();
      }  else {
        throw Exception('Error al obtener los detalles del cliente');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  Future<void> updateCliente() async {
    if (_formKey.currentState!.validate()) {
      try {
        final token = await KeyValueStorageServiceImpl().getValue<String>('token');

        final Map<String, dynamic> body = {
          'Nombre': _nombre,
          'Nit': _nit,
          'Telefono': _telefono,
        };

        final response = await http.put(
          Uri.parse('https://apiproyectomonarca.fly.dev/api/clientes/actualizar/${widget.clienteId}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cliente actualizado exitosamente')),
          );
          context.push('/clientes');
        } else {
          throw Exception('Error al actualizar el cliente.');
        }
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocurrió un error al actualizar el cliente.')),
        );
      }
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
                      onPressed: () => context.push('/clientes'),
                      icon: const Icon(Icons.arrow_back_rounded, size: 40, color: Colors.white),
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
                      : clienteDetails == null
                          ? const Center(child: Text('No se pudo cargar la información del cliente.'))
                          : Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    const SizedBox(height: 50),
                                    Text('Modificar Cliente', style: textStyles.titleMedium),
                                    const SizedBox(height: 50),
                                    CustomTextFormField(
                                      label: 'Nombre',
                                      initialValue: _nombre,
                                      onChanged: (value) {
                                        setState(() {
                                          _nombre = value;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'El nombre es obligatorio';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 30),
                                    CustomTextFormField(
                                      label: 'NIT',
                                      initialValue: _nit,
                                      onChanged: (value) {
                                        setState(() {
                                          _nit = value;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'El NIT es requerido';
                                        } else if (value.length < 5) {
                                          return 'El NIT debe tener al menos 5 caracteres';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 30),
                                    CustomTextFormField(
                                      label: 'Teléfono',
                                      initialValue: _telefono,
                                      onChanged: (value) {
                                        setState(() {
                                          _telefono = value;
                                        });
                                      },
                                      keyboardType: TextInputType.phone,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'El teléfono es requerido';
                                        } else if (value.length < 8) {
                                          return 'El teléfono debe tener al menos 8 dígitos';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 50),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 60,
                                      child: CustomFilledButton(
                                        text: 'Actualizar',
                                        buttonColor: const Color(0xFF283B71),
                                        onPressed: updateCliente,
                                      ),
                                    ),
                                  ],
                                ),
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
