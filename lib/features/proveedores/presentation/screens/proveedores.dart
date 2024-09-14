import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

class SupplierScreen extends ConsumerStatefulWidget {
  const SupplierScreen({super.key});

  @override
  _SupplierScreenState createState() => _SupplierScreenState();
}

class _SupplierScreenState extends ConsumerState<SupplierScreen> {
  List<dynamic> suppliers = [];
  List<dynamic> filteredSuppliers = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

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

  Future<void> _navigateAndRefresh(BuildContext context) async {
    final result = await context.push('/proveedoresCreate');
    if (result == true) {
      fetchSuppliers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, size: 30),
            onPressed: () => _navigateAndRefresh(context),
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
              onChanged: filterSuppliers,
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
                            child: ListTile(
                              leading: const Icon(Icons.business),
                              title: Text(supplier['nombre']),
                              subtitle: Text('Teléfono: ${supplier['telefono']}'),
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
