import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';
import 'package:monarca/features/shared/widgets/geometrical_background.dart';
import 'package:monarca/features/shared/widgets/custom_filled_button.dart';
import 'package:monarca/features/shared/widgets/custom_text_form_field.dart';

class CreateSupplierScreen extends StatelessWidget {
  const CreateSupplierScreen({super.key});

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
                  Text('Crear proveedor', style: textStyles.titleLarge?.copyWith(color: Colors.white)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                      child: const _CreateSupplierForm(),
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

class _CreateSupplierForm extends ConsumerStatefulWidget {
  const _CreateSupplierForm();

  @override
  _CreateSupplierFormState createState() => _CreateSupplierFormState();
}

class _CreateSupplierFormState extends ConsumerState<_CreateSupplierForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  Future<void> createSupplier() async {
    if (_nameController.text.isEmpty || _addressController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos')),
      );
      return;
    }

    final Map<String, dynamic> supplierData = {
      'nombre': _nameController.text,
      'direccion': _addressController.text,
      'telefono': _phoneController.text,
    };

    final token = await KeyValueStorageServiceImpl().getValue<String>('token');
    final response = await http.post(
      Uri.parse('https://apiproyectomonarca.fly.dev/api/proveedores/guardar'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(supplierData),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proveedor creado exitosamente')),
      );
      Navigator.pop(context, true); // Regresa con el valor true
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al crear el proveedor')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(height: 50),
        Text('Nuevo proveedor', style: textStyles.titleMedium),
        const SizedBox(height: 50),

        CustomTextFormField(
          label: 'Nombre',
          controller: _nameController,
        ),
        const SizedBox(height: 30),

        CustomTextFormField(
          label: 'Dirección',
          controller: _addressController,
        ),
        const SizedBox(height: 30),

        CustomTextFormField(
          label: 'Teléfono',
          controller: _phoneController,
        ),
        const SizedBox(height: 50),

        SizedBox(
          width: double.infinity,
          height: 60,
          child: CustomFilledButton(
            text: 'Crear',
            buttonColor: const Color(0xFF283B71),
            onPressed: createSupplier,
          ),
        ),
        const SizedBox(height: 50),
      ],
    );
  }
}
