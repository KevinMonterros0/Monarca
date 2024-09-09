import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:monarca/features/auth/presentation/providers/users_provider.dart';
import 'dart:convert';
import 'package:monarca/features/shared/widgets/custom_filled_button.dart';
import 'package:monarca/features/shared/widgets/geometrical_background.dart';
import 'package:monarca/features/shared/widgets/custom_text_form_field.dart';

class RolCreate extends ConsumerStatefulWidget {
  const RolCreate({super.key});

  @override
  _RolCreateState createState() => _RolCreateState();
}

class _RolCreateState extends ConsumerState<RolCreate> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();

  Future<void> createRole() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String name = _nameController.text;
    final String description = _descriptionController.text;

    setState(() {
      isLoading = true;
    });

    try {
      final token = await keyValueStorageService.getValue<String>('token');
      final response = await http.post(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/roles/crear'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nombre': name,
          'detalle': description,
          'estado': true, 
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rol creado exitosamente')),
        );
        Navigator.pop(context); 
      } else {
        throw Exception('Error al crear el rol');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al crear el rol')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
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
                      'Crear Rol',
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
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(100)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 150),
                          CustomTextFormField(
                            label: 'Nombre del rol',
                            onChanged: (value) {},
                            controller: _nameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'El nombre del rol es obligatorio';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          CustomTextFormField(
                            label: 'Descripción del rol',
                            onChanged: (value) {},
                            controller: _descriptionController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'La descripción es obligatoria';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 60),
                          isLoading
                              ? const CircularProgressIndicator()
                              : SizedBox(
                                  width: double.infinity,
                                  height: 40,
                                  child: CustomFilledButton(
                                    text: 'Confirmar',
                                    onPressed: createRole,
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
