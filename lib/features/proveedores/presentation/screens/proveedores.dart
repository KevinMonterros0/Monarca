import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

double globalTotalAmount = 0.0;
List<Map<String, dynamic>> cart = [];

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

  Future<void> fetchProductsBySupplier(int supplierId) async {
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
        _showProductList(context, products);
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
            _showCancelConfirmationDialog(context);
          },
        ),
        title: const Text('Proveedores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, size: 30),
            onPressed: () {
              _showCartSummary(context);
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
                          return GestureDetector(
                            onTap: () {
                              _showOptions(context, supplier['id_proveedor'], supplier['nombre']);
                            },
                            child: Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.business, size: 40),
                                title: Text(
                                  supplier['nombre'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text('Teléfono: ${supplier['telefono']}'),
                                trailing: const Icon(Icons.more_vert),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancelar compra'),
          content: const Text('¿Estás seguro de que deseas cancelar la compra? '),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  globalTotalAmount = 0.0;
                  cart.clear();
                });
                Navigator.pop(context);
                context.push('/');
              },
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );
  }

  void _showOptions(BuildContext context, int supplierId, String supplierName) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar Proveedor'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/editSupplier', extra: supplierId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Eliminar Proveedor'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(context, supplierId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart),
                title: const Text('Ver Productos'),
                onTap: () {
                  Navigator.pop(context);
                  fetchProductsBySupplier(supplierId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, int supplierId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text('¿Estás seguro de que deseas eliminar este proveedor?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  void _showProductList(BuildContext context, List<dynamic> products) {
    List<int> quantities = List<int>.filled(products.length, 0);
    double productTotal = 0.0;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: products.isEmpty
                        ? const Center(child: Text('No hay productos para este proveedor.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(10),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];

                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.shopping_cart, size: 40),
                                  title: Text(
                                    product['nombre'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text('Precio: Q${product['precio_compra']}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () {
                                          if (quantities[index] > 0) {
                                            setState(() {
                                              quantities[index]--;
                                              productTotal -= product['precio_compra'].toDouble();
                                              globalTotalAmount -= product['precio_compra'].toDouble();
                                            });
                                          }
                                        },
                                      ),
                                      Text('${quantities[index]}', style: const TextStyle(fontSize: 18)),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () {
                                          setState(() {
                                            quantities[index]++;
                                            productTotal += product['precio_compra'].toDouble();
                                            globalTotalAmount += product['precio_compra'].toDouble();
                                          });
                                          _updateCart(product, quantities[index]);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Total: Q$globalTotalAmount', style: const TextStyle(fontSize: 20)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            globalTotalAmount -= productTotal;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Aceptar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _updateCart(dynamic product, int quantity) {
    final existingProduct = cart.firstWhere(
        (item) => item['id'] == product['id_producto'],
        orElse: () => {});
    if (existingProduct.isNotEmpty) {
      setState(() {
        existingProduct['quantity'] = quantity;
      });
    } else {
      setState(() {
        cart.add({
          'id': product['id_producto'],
          'nombre': product['nombre'],
          'precio': product['precio_compra'],
          'quantity': quantity,
        });
      });
    }
  }

  void _showCartSummary(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Resumen de Productos Comprados',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: cart.isEmpty
                        ? const Center(child: Text('No hay productos en el carrito.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(10),
                            itemCount: cart.length,
                            itemBuilder: (context, index) {
                              final product = cart[index];
                              return ListTile(
                                title: Text(product['nombre']),
                                subtitle: Text(
                                    'Cantidad: ${product['quantity']} | Precio: Q${product['precio']}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    setState(() {
                                      _removeFromCart(product, index);
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Total: Q$globalTotalAmount', style: const TextStyle(fontSize: 20)),
                  ),
                  Visibility(
                    visible: cart.isNotEmpty,
                    child: ElevatedButton(
                      onPressed: () {
                      },
                      child: const Text('Comprar'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _removeFromCart(Map<String, dynamic> product, int index) {
    setState(() {
      cart.removeAt(index);
      globalTotalAmount -= product['precio'] * product['quantity'];
    });
  }
}
