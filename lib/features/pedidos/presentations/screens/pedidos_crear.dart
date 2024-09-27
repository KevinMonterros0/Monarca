import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

double globalTotalAmount = 0.0;
List<Map<String, dynamic>> cart = [];

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  List<dynamic> allProducts = [];
  List<int> quantities = [];
  bool isLoading = true;
  List<dynamic> clients = [];
  List<dynamic> employees = [];
  String? selectedClientName;
  int? selectedClientId;
  String? selectedEmployeeName;
  int? selectedEmployeeId;
  DateTime? selectedDeliveryDate;
  String deliveryDateText = 'Seleccionar fecha y hora de entrega';

  @override
  void initState() {
    super.initState();
    fetchProducts();
    fetchClients();
    fetchEmployees();
  }

  Future<void> fetchProducts() async {
    try {
      final keyValueStorageService = KeyValueStorageServiceImpl();
      final token = await keyValueStorageService.getValue<String>('token');

      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/productos/obtener'),
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

  Future<void> fetchClients() async {
    try {
      final keyValueStorageService = KeyValueStorageServiceImpl();
      final token = await keyValueStorageService.getValue<String>('token');

      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/clientes/obtener'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          clients = json.decode(response.body);
        });
      } else {
        throw Exception('Error al obtener la lista de clientes.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> fetchEmployees() async {
    try {
      final keyValueStorageService = KeyValueStorageServiceImpl();
      final token = await keyValueStorageService.getValue<String>('token');

      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/empleados/obtener'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          employees = json.decode(response.body);
        });
      } else {
        throw Exception('Error al obtener la lista de empleados.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _updateCart(dynamic product, int quantity) {
    final existingProductIndex = cart.indexWhere((item) => item['id'] == product['id_producto']);

    if (existingProductIndex != -1) {
      if (quantity == 0) {
        cart.removeAt(existingProductIndex);
      } else {
        cart[existingProductIndex]['quantity'] = quantity;
      }
    } else if (quantity > 0) {
      cart.add({
        'id': product['id_producto'],
        'nombre': product['nombre'],
        'precio': product['precio_compra'],
        'quantity': quantity,
      });
    }
  }

  Future<void> _selectDeliveryDateTime(BuildContext context, Function setModalState) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final combinedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setModalState(() {
          selectedDeliveryDate = combinedDateTime;
          deliveryDateText =
              'Fecha y hora de entrega: ${DateFormat('yyyy-MM-dd HH:mm').format(selectedDeliveryDate!)}';
        });
      }
    }
  }

  Future<void> _submitOrder(BuildContext context) async {
    try {
      final keyValueStorageService = KeyValueStorageServiceImpl();
      final token = await keyValueStorageService.getValue<String>('token');

      final response = await http.post(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/pedidos/crear'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'Id_Cliente': selectedClientId,
          'id_empleado': selectedEmployeeId,
          'Fecha_Entrega': DateFormat('yyyy-MM-dd HH:mm').format(selectedDeliveryDate!), 
          'TotalPedido': globalTotalAmount,
        }),
      );

      if (response.statusCode == 201) {
        // Pedido exitoso
        setState(() {
          globalTotalAmount = 0.0;
          cart.clear();
          selectedClientId = null;
          selectedEmployeeId = null;
          selectedDeliveryDate = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido realizado exitosamente.')),
        );
        Navigator.pop(context);
        context.push('/');
      } else {
        throw Exception('Error al realizar el pedido.');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un error al realizar el pedido.')),
      );
    }
  }

  void _showCartSummary(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Resumen del Carrito',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  clients.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButton<String>(
                          value: selectedClientName,
                          hint: const Text('Seleccionar cliente'),
                          items: clients.map<DropdownMenuItem<String>>((client) {
                            return DropdownMenuItem<String>(
                              value: client['nombre'],
                              child: Text('${client['nombre']}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() {
                              selectedClientName = value!;
                              selectedClientId = clients.firstWhere(
                                  (client) => client['nombre'] == value)['id_cliente'];
                            });
                          },
                        ),
                  const SizedBox(height: 20),
                  employees.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButton<String>(
                          value: selectedEmployeeName,
                          hint: const Text('Seleccionar empleado'),
                          items: employees.map<DropdownMenuItem<String>>((employee) {
                            return DropdownMenuItem<String>(
                              value: employee['nombre'],
                              child: Text('${employee['nombre']}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() {
                              selectedEmployeeName = value!;
                              selectedEmployeeId = employees.firstWhere(
                                  (employee) => employee['nombre'] == value)['id_empleado'];
                            });
                          },
                        ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _selectDeliveryDateTime(context, setModalState),
                    child: Text(deliveryDateText),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      deliveryDateText,
                      style: const TextStyle(fontSize: 16),
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
                                  'Cantidad: ${product['quantity']} | Precio: Q${product['precio']}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    setModalState(() {
                                      globalTotalAmount -= product['precio'] * product['quantity'];
                                      cart.removeAt(index);
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
                    visible: cart.isNotEmpty && selectedClientId != null && selectedEmployeeId != null && selectedDeliveryDate != null,
                    child: ElevatedButton(
                      onPressed: () => _submitOrder(context),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await _showExitConfirmationDialog(context);
        return shouldExit;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Productos'),
          actions: [
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                _showCartSummary(context);
              },
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
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.shopping_cart, size: 40),
                      title: Text(
                        product['nombre'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                                  globalTotalAmount -= product['precio_compra'].toDouble();
                                  _updateCart(product, quantities[index]);
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
                                globalTotalAmount += product['precio_compra'].toDouble();
                                _updateCart(product, quantities[index]);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar salida'),
            content: const Text('¿Deseas cancelar el pedido? Todos los valores serán restablecidos.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    globalTotalAmount = 0.0;
                    cart.clear();
                    selectedClientId = null;
                    selectedEmployeeId = null;
                    selectedDeliveryDate = null;
                  });
                  Navigator.of(context).pop(true); 
                },
                child: const Text('Sí'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
