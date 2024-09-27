import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';
import 'package:monarca/features/shared/widgets/geometrical_background.dart';
import 'package:monarca/features/shared/widgets/custom_filled_button.dart';
import 'package:monarca/features/shared/widgets/custom_text_form_field.dart';

class SupplierDetailScreen extends ConsumerStatefulWidget {
  final int supplierId;

  const SupplierDetailScreen({super.key, required this.supplierId});

  @override
  _SupplierDetailScreenState createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends ConsumerState<SupplierDetailScreen> {
  Map<String, dynamic>? supplierDetails;
  bool isLoading = true;
  String _supplierName = '';
  String _supplierPhone = '';
  String _supplierAddress = '';

  @override
  void initState() {
    super.initState();
    fetchSupplierDetails();
  }

  Future<void> fetchSupplierDetails() async {
    try {
      final token =
          await KeyValueStorageServiceImpl().getValue<String>('token');
      final response = await http.get(
        Uri.parse(
            'https://apiproyectomonarca.fly.dev/api/proveedores/obtenerPorId/${widget.supplierId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          supplierDetails = json.decode(response.body);
          _supplierName = supplierDetails!['nombre'];
          _supplierPhone = supplierDetails!['telefono'];
          _supplierAddress = supplierDetails!['direccion'];
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener los detalles del proveedor');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  Future<void> updateSupplier() async {
    try {
      final token =
          await KeyValueStorageServiceImpl().getValue<String>('token');

      final Map<String, dynamic> body = {
        'nombre': _supplierName,
        'telefono': _supplierPhone,
        'direccion': _supplierAddress,
      };

      final response = await http.put(
        Uri.parse(
            'https://apiproyectomonarca.fly.dev/api/proveedores/actualizar/${widget.supplierId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proveedor actualizado exitosamente')),
        );
        context.push('/proveedores');
      } else {
        throw Exception('Error al actualizar el proveedor.');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ocurrió un error al actualizar el proveedor.')),
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
                      onPressed: () => context.push('/proveedores'),
                      icon: const Icon(Icons.arrow_back_rounded,
                          size: 40, color: Colors.white),
                    ),
                    const Spacer(flex: 1),
                    const Icon(
                      Icons.storefront,
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
                      : supplierDetails == null
                          ? const Center(
                              child: Text(
                                  'No se pudo cargar la información del proveedor.'))
                          : Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Column(
                                children: [
                                  const SizedBox(height: 50),
                                  Text('Modificar Proveedor',
                                      style: textStyles.titleMedium),
                                  const SizedBox(height: 50),
                                  CustomTextFormField(
                                    label: 'Nombre del Proveedor',
                                    initialValue: _supplierName,
                                    onChanged: (value) {
                                      setState(() {
                                        _supplierName = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 30),
                                  CustomTextFormField(
                                    label: 'Teléfono',
                                    initialValue: _supplierPhone,
                                    onChanged: (value) {
                                      setState(() {
                                        _supplierPhone = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 30),
                                  CustomTextFormField(
                                    label: 'Dirección',
                                    initialValue: _supplierAddress,
                                    onChanged: (value) {
                                      setState(() {
                                        _supplierAddress = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 50),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 60,
                                    child: CustomFilledButton(
                                      text: 'Actualizar',
                                      buttonColor: const Color(0xFF283B71),
                                      onPressed: updateSupplier,
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
