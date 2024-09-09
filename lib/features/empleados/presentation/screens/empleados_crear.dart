import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';
import 'dart:convert';
import 'package:monarca/features/shared/widgets/geometrical_background.dart';
import 'package:monarca/features/shared/widgets/custom_filled_button.dart';
import 'package:monarca/features/shared/widgets/custom_text_form_field.dart';

class CreateEmployeeScreen extends StatelessWidget {
  const CreateEmployeeScreen({super.key});

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
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 40, color: Colors.white),
                    ),
                    const Spacer(flex: 1),
                    Text('Crear empleado', style: textStyles.titleLarge?.copyWith(color: Colors.white)),
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
                  child: const _CreateEmployeeForm(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateEmployeeForm extends ConsumerStatefulWidget {
  const _CreateEmployeeForm();

  @override
  _CreateEmployeeFormState createState() => _CreateEmployeeFormState();
}

class _CreateEmployeeFormState extends ConsumerState<_CreateEmployeeForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dpiController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  
  
  final TextEditingController _fechaNacimientoController = TextEditingController();

  DateTime? _fechaNacimiento;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _fechaNacimiento) {
      setState(() {
        _fechaNacimiento = picked;
    
        _fechaNacimientoController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> createEmployee() async {
    if (_nameController.text.isEmpty || _dpiController.text.isEmpty || _telefonoController.text.isEmpty ||
        _direccionController.text.isEmpty || _correoController.text.isEmpty || _fechaNacimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos')),
      );
      return;
    }

    final Map<String, dynamic> employeeData = {
      'nombre': _nameController.text,
      'dpi': _dpiController.text,
      'telefono': _telefonoController.text,
      'direccion': _direccionController.text,
      'correo': _correoController.text,
      'fec_nacimiento': _fechaNacimiento!.toIso8601String(),
    };
    final token =
          await KeyValueStorageServiceImpl().getValue<String>('token');
    final response = await http.post(
      Uri.parse('https://apiproyectomonarca.fly.dev/api/empleados/crear'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(employeeData),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Empleado creado exitosamente')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al crear el empleado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        children: [
          const SizedBox(height: 50),
          Text('Nuevo empleado', style: textStyles.titleMedium),
          const SizedBox(height: 50),

          CustomTextFormField(
            label: 'Nombre',
            controller: _nameController,
          ),
          const SizedBox(height: 30),

          CustomTextFormField(
            label: 'DPI',
            controller: _dpiController,
          ),
          const SizedBox(height: 30),

          CustomTextFormField(
            label: 'Teléfono',
            controller: _telefonoController,
          ),
          const SizedBox(height: 30),

          CustomTextFormField(
            label: 'Dirección',
            controller: _direccionController,
          ),
          const SizedBox(height: 30),

          CustomTextFormField(
            label: 'Correo',
            keyboardType: TextInputType.emailAddress,
            controller: _correoController,
          ),
          const SizedBox(height: 30),

          GestureDetector(
            onTap: () => _selectDate(context),
            child: AbsorbPointer(
              child: CustomTextFormField(
                label: 'Fecha de Nacimiento',
                controller: _fechaNacimientoController, 
                hint: 'Selecciona una fecha',
              ),
            ),
          ),
          const SizedBox(height: 50),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: CustomFilledButton(
              text: 'Crear',
              buttonColor: const Color(0xFF283B71),
              onPressed: createEmployee,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
