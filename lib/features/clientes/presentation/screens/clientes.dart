import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

final customersProvider = StateNotifierProvider<CustomersNotifier, CustomersState>((ref) {
  return CustomersNotifier();
});

class CustomersNotifier extends StateNotifier<CustomersState> {
  List<dynamic> allCustomers = [];

  CustomersNotifier() : super(CustomersState());

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
        final List<dynamic> customersList = json.decode(response.body);
        allCustomers = customersList;
        state = state.copyWith(customers: customersList);
      } else {
        throw Exception('Error al obtener la lista de clientes.');
      }
    } catch (e) {
      print('Error al obtener la lista de clientes: $e');
    }
  }

  void filterCustomersByName(String query) {
    if (query.isEmpty) {
      state = state.copyWith(customers: allCustomers);
    } else {
      final filteredCustomers = allCustomers.where((customer) {
        return customer['nombre'].toLowerCase().contains(query.toLowerCase()) ||
               customer['telefono'].toString().toLowerCase().contains(query.toLowerCase());
      }).toList();
      state = state.copyWith(customers: filteredCustomers);
    }
  }
}

class CustomersState {
  final List<dynamic> customers;

  CustomersState({this.customers = const []});

  CustomersState copyWith({List<dynamic>? customers}) {
    return CustomersState(
      customers: customers ?? this.customers,
    );
  }
}

class CustomerScreen extends ConsumerStatefulWidget {
  const CustomerScreen({super.key});

  @override
  _CustomerScreenState createState() => _CustomerScreenState();
}

class _CustomerScreenState extends ConsumerState<CustomerScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(customersProvider.notifier).fetchCustomers();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = (width / 200).floor();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 30),
          onPressed: () {
            context.pop('/');
          },
        ),
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, size: 30),
            onPressed: () {
              context.push('/clientesCreate');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre o teléfono',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref.read(customersProvider.notifier).filterCustomersByName(value);
              },
            ),
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final customersState = ref.watch(customersProvider);

                if (customersState.customers.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: customersState.customers.length,
                  itemBuilder: (context, index) {
                    final customer = customersState.customers[index];

                    return GestureDetector(
                      onTap: () {
                        _showCustomerOptions(context, customer['id_cliente'], customer['nombre']);
                      },
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.blueAccent,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              customer['nombre'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerOptions(BuildContext context, int customerId, String customerName) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/clientesDetail', extra: customerId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.toggle_on),
                title: const Text('Activar / Inactivar'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleCustomerState(customerId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleCustomerState(int customerId) async {
    try {
      final token = await KeyValueStorageServiceImpl().getValue<String>('token');

      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/clientes/obtenerEstados/$customerId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> estadoList = json.decode(response.body);
        final bool currentState = estadoList.first['estado'];

        final newState = !currentState;

        final changeResponse = await http.put(
          Uri.parse('https://apiproyectomonarca.fly.dev/api/clientes/cambiarEstado/$customerId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'estado': newState}),
        );

        if (changeResponse.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('El estado del cliente se ha actualizado a $newState')),
          );

          ref.read(customersProvider.notifier).fetchCustomers();
        } else {
          throw Exception('Error al cambiar el estado del cliente');
        }
      } else {
        throw Exception('Error al obtener el estado del cliente');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un error al cambiar el estado del cliente.')),
      );
    }
  }


}
