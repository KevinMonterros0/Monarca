import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; 
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';
import 'package:monarca/features/shared/widgets/geometrical_background.dart';
import 'package:monarca/features/shared/widgets/custom_filled_button.dart';
import 'package:monarca/features/shared/widgets/custom_text_form_field.dart';

class EmployeeDetailScreen extends ConsumerStatefulWidget {
  final int employeeId;

  const EmployeeDetailScreen({super.key, required this.employeeId});

  @override
  _EmployeeDetailScreenState createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends ConsumerState<EmployeeDetailScreen> {
  Map<String, dynamic>? employeeDetails;
  bool isLoading = true;
  String _nombre = '';
  String _dpi = '';
  String _telefono = '';
  String _direccion = '';
  String _correo = '';
  DateTime? _fecNacimiento;


  final TextEditingController _dateController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchEmployeeDetails();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> fetchEmployeeDetails() async {
    try {
      final token =
          await KeyValueStorageServiceImpl().getValue<String>('token');
      final response = await http.get(
        Uri.parse(
            'https://apiproyectomonarca.fly.dev/api/empleados/obtenerPorId/${widget.employeeId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          employeeDetails = json.decode(response.body);
          _nombre = employeeDetails!['nombre'];
          _dpi = employeeDetails!['dpi'];
          _telefono = employeeDetails!['telefono'];
          _direccion = employeeDetails!['direccion'];
          _correo = employeeDetails!['correo'];
          _fecNacimiento = DateTime.parse(employeeDetails!['fec_nacimiento']);
          _dateController.text = _formatDate(
              _fecNacimiento); 
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener los detalles del empleado');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  Future<void> updateEmployee() async {
    // Verificar si el formulario es válido
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos')),
      );
      return;
    }

    try {
      final token =
          await KeyValueStorageServiceImpl().getValue<String>('token');

      final Map<String, dynamic> body = {
        'Nombre': _nombre,
        'DPI': _dpi,
        'Telefono': _telefono,
        'Direccion': _direccion,
        'Correo': _correo,
        'Fec_nacimiento': _fecNacimiento?.toIso8601String(),
      };

      final response = await http.put(
        Uri.parse(
            'https://apiproyectomonarca.fly.dev/api/empleados/actualizar/${widget.employeeId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Empleado actualizado exitosamente')),
        );
        context.push('/empleados');
      } else {
        throw Exception('Error al actualizar el empleado.');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ocurrió un error al actualizar el empleado.')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fecNacimiento ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _fecNacimiento) {
      setState(() {
        _fecNacimiento = picked;
        _dateController.text = _formatDate(
            _fecNacimiento); 
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd').format(date); // Formato de fecha deseado
  }

  @override
  Widget build(BuildContext context) {
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
                    onPressed: () => context.push('/empleados'),
                    icon: const Icon(Icons.arrow_back_rounded,
                        size: 40, color: Colors.white),
                  ),
                  const Spacer(flex: 1),
                  const Icon(
                    Icons.badge,
                    color: Colors.white,
                    size: 100,
                  ),
                  const Spacer(flex: 2),
                ],
              ),
              const SizedBox(height: 80),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(100),
                    ),
                  ),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : employeeDetails == null
                          ? const Center(
                              child: Text(
                                  'No se pudo cargar la información del empleado.'))
                          : Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(40.0),
                                physics: const ClampingScrollPhysics(),
                                child: Form(
                                  // Añadir un formulario para validación
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 50),
                                      Text('Modificar Empleado',
                                          style: textStyles.titleMedium),
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
                                        label: 'DPI',
                                        initialValue: _dpi,
                                        onChanged: (value) {
                                          setState(() {
                                            _dpi = value;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'El DPI es obligatorio';
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
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'El teléfono es obligatorio';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 30),
                                      CustomTextFormField(
                                        label: 'Dirección',
                                        initialValue: _direccion,
                                        onChanged: (value) {
                                          setState(() {
                                            _direccion = value;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'La dirección es obligatoria';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 30),
                                      CustomTextFormField(
                                        label: 'Correo',
                                        initialValue: _correo,
                                        onChanged: (value) {
                                          setState(() {
                                            _correo = value;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'El correo es obligatorio';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 30),
                                      GestureDetector(
                                        onTap: () => _selectDate(context),
                                        child: AbsorbPointer(
                                          child: CustomTextFormField(
                                            label: 'Fecha de Nacimiento',
                                            controller: _dateController,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'La fecha de nacimiento es obligatoria';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 50),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 60,
                                        child: CustomFilledButton(
                                          text: 'Actualizar',
                                          buttonColor: const Color(0xFF283B71),
                                          onPressed: updateEmployee,
                                        ),
                                      ),
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
