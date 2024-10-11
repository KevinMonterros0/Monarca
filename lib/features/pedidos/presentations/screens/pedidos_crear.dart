import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

double globalTotalAmount = 0.0;
List<Map<String, dynamic>> cart = [];

class OrdersScreen extends ConsumerStatefulWidget {
  final int idRepartidor;
  final int idCliente;

  const OrdersScreen({super.key, required this.idRepartidor, required this.idCliente});

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  List<dynamic> allProducts = [];
  List<int> quantities = [];
  bool isLoading = true;
  DateTime? selectedDeliveryDate;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final keyValueStorageService = KeyValueStorageServiceImpl();
      final token = await keyValueStorageService.getValue<String>('token');

      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/productos/vista'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          allProducts = json.decode(response.body);
          quantities = List<int>.filled(allProducts.length, 0);
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener los productos.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  String normalizeText(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u');
  }

  Future<void> _selectDeliveryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (timePicked != null) {
        setState(() {
          selectedDeliveryDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  Future<void> _createOrder() async {
    if (selectedDeliveryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor selecciona una fecha y hora de entrega.')),
      );
      return;
    }

    try {
      final keyValueStorageService = KeyValueStorageServiceImpl();
      final token = await keyValueStorageService.getValue<String>('token');

      final body = {
        "Id_Cliente": widget.idCliente,
        "id_empleado": widget.idRepartidor,
        "Fecha_Entrega": selectedDeliveryDate!.toUtc().toIso8601String(),
        "TotalPedido": globalTotalAmount,
      };

      final response = await http.post(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/pedidos/crear'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        _clearCart();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pedido creado exitosamente')),
        );
        context.push('/');
      } else {
        throw Exception('Error al crear el pedido.');
      }
    } catch (e) {
      print('Error al crear el pedido: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear el pedido: $e')),
      );
    }
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView(
          padding: const EdgeInsets.all(10),
          children: [
            Text('Carrito de compras', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ...cart.map((item) {
              return ListTile(
                title: Text(item['nombre']),
                subtitle: Text('Cantidad: ${item['quantity']} - Total: Q${item['precio'] * item['quantity']}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      globalTotalAmount -= item['precio'] * item['quantity'];
                      final productIndex = allProducts.indexWhere((product) => product['nombre'] == item['nombre']);
                      quantities[productIndex] = 0;
                      cart.remove(item);
                    });
                    Navigator.pop(context);
                    _showCart();
                  },
                ),
              );
            }).toList(),
            const Divider(),
            ListTile(
              title: Text('Total del Carrito'),
              trailing: Text('Q$globalTotalAmount'),
            ),
            ElevatedButton(
              onPressed: _createOrder,
              child: const Text('Realizar Pedido'),
            )
          ],
        );
      },
    );
  }

  Future<void> _askIfGarrafonIsNew(BuildContext context, dynamic product, int index) async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¿Es un Garrafón nuevo?'),
          content: const Text('Por favor selecciona si el Garrafón es nuevo o no.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'No'),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'Si'),
              child: const Text('Si'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        quantities[index]++;
        globalTotalAmount += product['precio'];
        _updateCart(product, quantities[index], isNew: result == 'Si');
      });
    }
  }

  void _updateCart(dynamic product, int quantity, {bool isNew = false}) {
    final existingProductIndex = cart.indexWhere((item) => item['nombre'] == product['nombre']);

    if (existingProductIndex != -1) {
      if (quantity == 0) {
        cart.removeAt(existingProductIndex);
      } else {
        cart[existingProductIndex]['quantity'] = quantity;
      }
    } else if (quantity > 0) {
      cart.add({
        'nombre': product['nombre'],
        'precio': product['precio'],
        'quantity': quantity,
        'isNew': isNew,
      });
    }
  }

  void _clearCart() {
    setState(() {
      cart.clear();
      globalTotalAmount = 0.0;
      quantities = List<int>.filled(allProducts.length, 0);
    });
  }

  Future<bool> _showExitWarning() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salir de la página'),
        content: const Text('Si sales ahora, se perderán todos los datos del carrito. ¿Deseas continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              _clearCart();
              context.push('/');
            },
            child: const Text('Sí'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _showExitWarning,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Productos'),
          actions: [
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: _showCart,
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: allProducts.length,
                itemBuilder: (context, index) {
                  final product = allProducts[index];

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/${product['imagen']}',
                          fit: BoxFit.cover,
                          width: 150,
                          height: 150,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            product['nombre'],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'Q${product['precio']}',
                            style: const TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (quantities[index] > 0) {
                                  setState(() {
                                    quantities[index]--;
                                    globalTotalAmount -= product['precio'];
                                    _updateCart(product, quantities[index]);
                                  });
                                }
                              },
                            ),
                            Text('${quantities[index]}', style: const TextStyle(fontSize: 18)),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                if (normalizeText(product['nombre']) == 'garrafon') {
                                  _askIfGarrafonIsNew(context, product, index);
                                } else {
                                  setState(() {
                                    quantities[index]++;
                                    globalTotalAmount += product['precio'];
                                    _updateCart(product, quantities[index]);
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _selectDeliveryDate(context),
          label: const Text('Seleccionar Fecha de Entrega'),
          icon: const Icon(Icons.calendar_today),
        ),
      ),
    );
  }
}
