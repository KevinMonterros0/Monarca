import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';
import 'package:monarca/features/shared/widgets/geometrical_background.dart';
import 'package:monarca/features/shared/widgets/custom_filled_button.dart';
import 'package:monarca/features/shared/widgets/custom_text_form_field.dart';

class CreateClienteScreen extends ConsumerStatefulWidget {
  const CreateClienteScreen({super.key});

  @override
  _CreateClienteScreenState createState() => _CreateClienteScreenState();
}

class _CreateClienteScreenState extends ConsumerState<CreateClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _nitController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  Future<void> createCliente() async {
    if (_formKey.currentState!.validate()) {
      try {
        final token = await KeyValueStorageServiceImpl().getValue<String>('token');
        final Map<String, dynamic> clienteData = {
          'Nombre': _nombreController.text,
          'Nit': _nitController.text,
          'Telefono': _telefonoController.text,
        };

        final response = await http.post(
          Uri.parse('https://apiproyectomonarca.fly.dev/api/clientes/crear'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(clienteData),
        );

        if (response.statusCode == 201) {
          final responseData = json.decode(response.body);
          final int idCliente = responseData['id_cliente'];

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cliente creado exitosamente')),
          );

          context.push('/direccionesClienteCreate', extra: idCliente);
        } else {
          throw Exception('Error al crear el cliente.');
        }
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocurrió un error al crear el cliente.')),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 40, color: Colors.white),
                  ),
                  const Spacer(flex: 1),
                  Text('Crear Cliente', style: textStyles.titleLarge?.copyWith(color: Colors.white)),
                  const Spacer(flex: 2),
                ],
              ),
              const SizedBox(height: 50),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(100)),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(40.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 50),
                            Text('Nuevo Cliente', style: textStyles.titleMedium),
                            const SizedBox(height: 50),
                            CustomTextFormField(
                              label: 'Nombre',
                              controller: _nombreController,
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
                              controller: _nitController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El NIT es obligatorio';
                                } else if (value.length < 5) {
                                  return 'El NIT debe tener al menos 5 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 30),
                            CustomTextFormField(
                              label: 'Teléfono',
                              controller: _telefonoController,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El teléfono es obligatorio';
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
                                text: 'Crear',
                                buttonColor: const Color(0xFF283B71),
                                onPressed: createCliente,
                              ),
                            ),
                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
