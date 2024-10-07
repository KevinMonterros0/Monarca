import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  _OrdersListScreenState createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  List<dynamic> allOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final keyValueStorageService = KeyValueStorageServiceImpl();
      final token = await keyValueStorageService.getValue<String>('token');

      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/pedidos/obtener'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          allOrders = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener los pedidos.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  Future<void> changeOrderStatus(int idPedido, bool newStatus) async {
    try {
      final keyValueStorageService = KeyValueStorageServiceImpl();
      final token = await keyValueStorageService.getValue<String>('token');

      final response = await http.put(
        Uri.parse(
            'https://apiproyectomonarca.fly.dev/api/pedidos/cambiarEstado/$idPedido'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'estado': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estado del pedido actualizado exitosamente')),
        );
        fetchOrders();
      } else {
        throw Exception('Error al cambiar el estado del pedido.');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ocurrió un error al cambiar el estado del pedido.')),
      );
    }
  }

  Color getOrderCardColor(DateTime fechaEntrega, bool estadoPedido) {
    final now = DateTime.now().toUtc().add(const Duration(hours: -6));
    final durationToDelivery = fechaEntrega.difference(now);

    if (!estadoPedido) {
      return Colors.grey;
    } else if (durationToDelivery.inHours >= 2) {
      return const Color(0xFF99FF99);
    } else if (durationToDelivery.inHours == 1) {
      return const Color(0xFFFFEB99);
    } else if (durationToDelivery.inMinutes > 0 &&
        durationToDelivery.inMinutes < 60) {
      return const Color(0xFFFFEB99);
    } else if (now.isAfter(fechaEntrega) &&
        now.difference(fechaEntrega).inMinutes >= 20) {
      return const Color(0xFFFF9999);
    } else {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Pedidos'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: allOrders.length,
              itemBuilder: (context, index) {
                final order = allOrders[index];
                final DateTime fechaEntrega =
                    DateTime.parse(order['fecha_entrega']);
                final bool estadoPedido = order['estado_pedido'];

                return Dismissible(
                  key: Key(order['id_pedido'].toString()),
                  background: Container(
                    color: const Color(0x99FF99),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child:
                        const Icon(Icons.check, color: Colors.white, size: 40),
                  ),
                  secondaryBackground: Container(
                    color: const Color(0xFFFF6A6A),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child:
                        const Icon(Icons.cancel, color: Colors.white, size: 40),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      await changeOrderStatus(order['id_pedido'], false);
                    } else if (direction == DismissDirection.startToEnd) {
                      if (DateTime.now().isBefore(fechaEntrega)) {
                        await changeOrderStatus(order['id_pedido'], true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'No se puede activar un pedido cuya fecha de entrega ya ha pasado.')),
                        );
                      }
                    }
                    return false;
                  },
                  child: Card(
                    color: getOrderCardColor(fechaEntrega, estadoPedido),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Text(
                        'Pedido #${order['id_pedido']}',
                        style: const TextStyle(
                            fontWeight:
                                FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cliente: ${order['cliente']}',
                            style: const TextStyle(color: Colors.black),
                          ),
                          Text(
                            'Empleado: ${order['empleado']}',
                            style: const TextStyle(color: Colors.black),
                          ),
                          Text(
                            'Fecha de Entrega: ${DateFormat('yyyy-MM-dd hh:mm a').format(fechaEntrega)}',
                            style: const TextStyle(color: Colors.black),
                          ),
                          Text(
                            'Total: Q${order['totalpedido']}',
                            style: const TextStyle(color: Colors.black),
                          ),
                          Text(
                              'Estado del Pedido: ${estadoPedido ? 'Activo' : 'Inactivo'}',
                              style: const TextStyle(color: Colors.black))
                        ],
                      ),
                      onTap: () {
                        showRouteDetails(order['id_pedido']);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> showRouteDetails(int idPedido) async {
    try {
      final keyValueStorageService = KeyValueStorageServiceImpl();
      final token = await keyValueStorageService.getValue<String>('token');

      final response = await http.get(
        Uri.parse(
            'https://apiproyectomonarca.fly.dev/api/rutas/obtenerporPedido/$idPedido'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final routeDetails = json.decode(response.body);
        _showRouteDialog(context, routeDetails['direccion']);
      } else {
        throw Exception('Error al obtener la ruta del pedido.');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un error al obtener la ruta.')),
      );
    }
  }

  void _showRouteDialog(BuildContext context, String direccion) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Detalles de la Ruta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Dirección: $direccion'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: direccion));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Dirección copiada al portapapeles.')),
                  );
                },
                child: const Text('Copiar dirección'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
