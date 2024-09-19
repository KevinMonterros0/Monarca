import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:monarca/features/shared/widgets/custom_filled_button.dart';
import 'package:monarca/features/shared/widgets/geometrical_background.dart';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

class ConnectAddressCustomerScreen extends ConsumerStatefulWidget {
  const ConnectAddressCustomerScreen({super.key});

  @override
  _ConnectAddressCustomerScreenState createState() => _ConnectAddressCustomerScreenState();
}

class _ConnectAddressCustomerScreenState extends ConsumerState<ConnectAddressCustomerScreen> {
  List<dynamic> customers = [];
  List<dynamic> addresses = [];
  int? selectedCustomerId;  
  int? selectedAddressId; 
  bool isLoadingCustomers = true;
  bool isLoadingAddresses = true;

  @override
  void initState() {
    super.initState();
    fetchCustomers();
    fetchAddresses();
  }

  Future<void> fetchCustomers() async {
    try {
      final token = await KeyValueStorageServiceImpl().getValue<String>('token');
      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/clientes/obtener'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          customers = json.decode(response.body);
          isLoadingCustomers = false;
        });
      } else {
        throw Exception('Error al obtener los clientes.');
      }
    } catch (e) {
      setState(() {
        isLoadingCustomers = false;
      });
      print('Error al obtener los clientes: $e');
    }
  }

  Future<void> fetchAddresses() async {
    try {
      final token = await KeyValueStorageServiceImpl().getValue<String>('token');
      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/direcciones/obtener'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          addresses = json.decode(response.body);
          isLoadingAddresses = false;
        });
      } else {
        throw Exception('Error al obtener las direcciones.');
      }
    } catch (e) {
      setState(() {
        isLoadingAddresses = false;
      });
      print('Error al obtener las direcciones: $e');
    }
  }

  Future<void> assignAddressToCustomer(int customerId, int addressId) async {
    try {
      final token = await KeyValueStorageServiceImpl().getValue<String>('token');
      final response = await http.post(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/direcciones/asignarCliente'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_cliente': customerId,
          'id_direccion': addressId,
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
                      'Asignar Dirección a Cliente',
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
                    child: Column(
                      children: [
                        const SizedBox(height: 50),
                        // Listado de Clientes
                        isLoadingCustomers
                            ? const CircularProgressIndicator()
                            : Expanded(
                                child: ListView.builder(
                                  itemCount: customers.length,
                                  itemBuilder: (context, index) {
                                    final customer = customers[index];
                                    return Card(
                                      elevation: 2,
                                      child: ListTile(
                                        title: Text(customer['nombre']),
                                        leading: Radio<int>(
                                          value: customer['id_cliente'],
                                          groupValue: selectedCustomerId,
                                          onChanged: (int? value) {
                                            setState(() {
                                              selectedCustomerId = value;
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                        const SizedBox(height: 30),
                        // Listado de Direcciones
                        isLoadingAddresses
                            ? const CircularProgressIndicator()
                            : Expanded(
                                child: ListView.builder(
                                  itemCount: addresses.length,
                                  itemBuilder: (context, index) {
                                    final address = addresses[index];
                                    return Card(
                                      elevation: 2,
                                      child: ListTile(
                                        title: Text(address['direccion']),
                                        leading: Radio<int>(
                                          value: address['id_direccion'],
                                          groupValue: selectedAddressId,
                                          onChanged: (int? value) {
                                            setState(() {
                                              selectedAddressId = value;
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                        const SizedBox(height: 30),
                        // Botón de Confirmar
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: CustomFilledButton(
                            text: 'Confirmar',
                            onPressed: () {
                              if (selectedCustomerId != null && selectedAddressId != null) {
                                assignAddressToCustomer(selectedCustomerId!, selectedAddressId!);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Selecciona un cliente y una dirección.'),
                                  ),
                                );
                              }
                            },
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
