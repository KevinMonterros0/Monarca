import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:monarca/features/shared/widgets/custom_filled_button.dart';
import 'package:monarca/features/shared/widgets/custom_text_form_field.dart';
import 'package:monarca/features/shared/widgets/geometrical_background.dart';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

class ConnectAddressCustomerScreen extends ConsumerStatefulWidget {
  final int idCliente; 

  const ConnectAddressCustomerScreen({super.key, required this.idCliente});

  @override
  _ConnectAddressCustomerScreenState createState() =>
      _ConnectAddressCustomerScreenState();
}

class _ConnectAddressCustomerScreenState
    extends ConsumerState<ConnectAddressCustomerScreen> {
  final TextEditingController _addressController = TextEditingController();
  List<dynamic> departamentos = [];
  List<dynamic> municipios = [];
  List<dynamic> zonas = [];
  dynamic selectedDepartamento;
  dynamic selectedMunicipio;
  dynamic selectedZona;
  bool isLoadingDepartments = true;
  bool isLoadingZones = true;
  bool isLoadingMunicipios = true;

  @override
  void initState() {
    super.initState();
    fetchZonas(); 
    fetchDepartamentos(); 
  }

  Future<void> fetchDepartamentos() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://apiproyectomonarca.fly.dev/api/regiones/departamentos/obtener'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          departamentos = json.decode(response.body);
          isLoadingDepartments = false;
        });
      } else {
        throw Exception('Error al obtener los departamentos.');
      }
    } catch (e) {
      setState(() {
        isLoadingDepartments = false;
      });
      print('Error al obtener los departamentos: $e');
    }
  }

  // Función para obtener las zonas
  Future<void> fetchZonas() async {
    try {
      final token = await KeyValueStorageServiceImpl().getValue<String>('token');
      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/regiones/zonas/numeros'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          zonas = json.decode(response.body);
          isLoadingZones = false;
        });
      } else {
        throw Exception('Error al obtener las zonas.');
      }
    } catch (e) {
      setState(() {
        isLoadingZones = false;
      });
      print('Error al obtener las zonas: $e');
    }
  }

  Future<void> fetchMunicipios(int idDepartamento) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://apiproyectomonarca.fly.dev/api/regiones/municipios/obtenerPorDepartamento/$idDepartamento'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          municipios = json.decode(response.body);
          isLoadingMunicipios = false;
        });
      } else {
        throw Exception('Error al obtener los municipios.');
      }
    } catch (e) {
      setState(() {
        isLoadingMunicipios = false;
      });
      print('Error al obtener los municipios: $e');
    }
  }

  Future<void> assignAddressToCustomer() async {
    if (_addressController.text.isEmpty ||
        selectedDepartamento == null ||
        selectedMunicipio == null ||
        selectedZona == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    try {
      final token = await KeyValueStorageServiceImpl().getValue<String>('token');
      final response = await http.post(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/direcciones/asignarCliente'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_cliente': widget.idCliente,
          'direccion': _addressController.text,
          'departamento': selectedDepartamento['idDepartamento'],
          'municipio': selectedMunicipio,
          'zona': selectedZona,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dirección asignada correctamente al cliente')),
        );
      } else {
        throw Exception('Error al asignar la dirección.');
      }
    } catch (e) {
      print('Error al asignar la dirección: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al asignar la dirección al cliente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

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
                    Text(
                      'Asignar Dirección',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30 * textScaleFactor, 
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
                    child: Column(
                      children: [
                        const SizedBox(height: 60),
                        SizedBox(
                          width: double.infinity,
                          child: CustomTextFormField(
                            label: 'Dirección',
                            controller: _addressController,
                          ),
                        ),
                        const SizedBox(height: 30),
                        isLoadingZones
                            ? const CircularProgressIndicator()
                            : DropdownButton<dynamic>(
                                hint: Text('Elige una zona', style: TextStyle(fontSize: 16 * textScaleFactor)),
                                value: selectedZona,
                                onChanged: (dynamic newValue) {
                                  setState(() {
                                    selectedZona = newValue;
                                  });
                                },
                                items: zonas.map<DropdownMenuItem<dynamic>>((zona) {
                                  return DropdownMenuItem<dynamic>(
                                    value: zona['numero'],
                                    child: Text('Zona ${zona['numero']}', style: TextStyle(fontSize: 16 * textScaleFactor)),
                                  );
                                }).toList(),
                              ),
                        const SizedBox(height: 30),
                        isLoadingDepartments
                            ? const CircularProgressIndicator()
                            : DropdownButton<dynamic>(
                                hint: Text('Elige un departamento', style: TextStyle(fontSize: 16 * textScaleFactor)),
                                value: selectedDepartamento,
                                onChanged: (dynamic newValue) {
                                  setState(() {
                                    selectedDepartamento = newValue;
                                    selectedMunicipio = null; 
                                    fetchMunicipios(newValue['iddepartamento']); 
                                  });
                                },
                                items: departamentos.map<DropdownMenuItem<dynamic>>((departamento) {
                                  return DropdownMenuItem<dynamic>(
                                    value: departamento,
                                    child: Text(departamento['nombre'], style: TextStyle(fontSize: 16 * textScaleFactor)),
                                  );
                                }).toList(),
                              ),
                        const SizedBox(height: 30),
                        isLoadingMunicipios
                            ? const CircularProgressIndicator()
                            : DropdownButton<dynamic>(
                                hint: Text('Elige un municipio', style: TextStyle(fontSize: 16 * textScaleFactor)),
                                value: selectedMunicipio,
                                onChanged: (dynamic newValue) {
                                  setState(() {
                                    selectedMunicipio = newValue;
                                  });
                                },
                                items: municipios.map<DropdownMenuItem<dynamic>>((municipio) {
                                  return DropdownMenuItem<dynamic>(
                                    value: municipio['nombre'],
                                    child: Text(municipio['nombre'], style: TextStyle(fontSize: 16 * textScaleFactor)),
                                  );
                                }).toList(),
                              ),
                        const SizedBox(height: 60),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: CustomFilledButton(
                            text: 'Confirmar',
                            onPressed: assignAddressToCustomer,
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
