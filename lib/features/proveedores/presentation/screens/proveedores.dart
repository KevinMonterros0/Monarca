import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

class SupplierProductScreen extends ConsumerStatefulWidget {
  const SupplierProductScreen({Key? key}) : super(key: key);

  @override
  _SupplierProductScreenState createState() => _SupplierProductScreenState();
}

class _SupplierProductScreenState extends ConsumerState<SupplierProductScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> suppliers = [];
  List<dynamic> filteredSuppliers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSuppliers();
  }

  Future<void> fetchSuppliers() async {
    try {
      final token = await KeyValueStorageServiceImpl().getValue<String>('token');
      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/proveedores/obtener'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          suppliers = json.decode(response.body);
          filteredSuppliers = suppliers;
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener la lista de proveedores.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  void filterSuppliers(String query) {
    setState(() {
      filteredSuppliers = suppliers.where((supplier) {
        final nameLower = supplier['nombre'].toLowerCase();
        final phoneLower = supplier['telefono'].toString().toLowerCase();
        final queryLower = query.toLowerCase();
        return nameLower.contains(queryLower) || phoneLower.contains(queryLower);
      }).toList();
    });
  }

  Future<void> fetchProductsBySupplier(int supplierId, String supplierName) async {
    try {
      final token = await KeyValueStorageServiceImpl().getValue<String>('token');
      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/productos/obtenerPorProveedores/$supplierId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final products = json.decode(response.body);
        if (products.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Este proveedor no cuenta con productos.')),
          );
        } else {
          context.push('/productList', extra: {
            'products': products,
            'supplierName': supplierName,
            'supplierId': supplierId,
          });
        }
      } else if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este proveedor no cuenta con productos.')),
        );
      } else {
        throw Exception('Error al obtener la lista de productos.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 30),
          onPressed: () {
            context.push('/');
          },
        ),
        title: const Text('Proveedores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, size: 30),
            onPressed: () {
              context.push('/proveedoresCreate');
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
                filterSuppliers(value);
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredSuppliers.isEmpty
                    ? const Center(child: Text('No hay proveedores disponibles.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: filteredSuppliers.length,
                        itemBuilder: (context, index) {
                          final supplier = filteredSuppliers[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.business, size: 40),
                                  title: Text(
                                    supplier['nombre'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text('Teléfono: ${supplier['telefono']}'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Editar'),
                                        onPressed: () {
                                          context.push('/editSupplier', extra: supplier['id_proveedor']);
                                        },
                                      ),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.shopping_cart),
                                        label: const Text('Ver Productos'),
                                        onPressed: () {
                                          fetchProductsBySupplier(supplier['id_proveedor'], supplier['nombre']);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
