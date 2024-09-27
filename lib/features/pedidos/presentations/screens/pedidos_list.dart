import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
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
        fetchOrders(); // Refrescar la lista de pedidos
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

  DateTime getCurrentTimeInGuatemala() {
    return DateTime.now().toUtc().subtract(const Duration(hours: 6));
  }

  Color getOrderCardColor(DateTime fechaEntrega, bool estadoPedido) {
    final now = getCurrentTimeInGuatemala();
    final durationToDelivery = fechaEntrega.difference(now);

    if (!estadoPedido) {
      return Colors.grey;
    } else if (durationToDelivery.inHours >= 2) {
      return Colors.green; 
    } else if (durationToDelivery.inHours == 1) {
      return Colors.yellow; 
    } else if (durationToDelivery.inMinutes <= 60 &&
        durationToDelivery.inMinutes > 0) {
      return Colors.yellow;
    } else if (now.isAfter(fechaEntrega) &&
        now.difference(fechaEntrega).inMinutes <= 19) {
      return Colors.yellow;
    } else if (now.isAfter(fechaEntrega) &&
        now.difference(fechaEntrega).inMinutes >= 20) {
      return Colors.red;
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
                    color: Colors.green,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child:
                        const Icon(Icons.check, color: Colors.white, size: 40),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child:
                        const Icon(Icons.cancel, color: Colors.white, size: 40),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      // Desactivar el pedido (siempre permitido)
                      await changeOrderStatus(order['id_pedido'], false);
                    } else if (direction == DismissDirection.startToEnd) {
                      // Activar el pedido solo si la fecha actual no ha pasado de la fecha de entrega
                      final nowInGuatemala = getCurrentTimeInGuatemala();
                      if (nowInGuatemala.isBefore(fechaEntrega)) {
                        await changeOrderStatus(order['id_pedido'], true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'No se puede activar un pedido cuya fecha de entrega ya ha pasado.')),
                        );
                      }
                    }
                    return false; // No eliminar automáticamente
                  },
                  child: Card(
                    color: getOrderCardColor(fechaEntrega, estadoPedido),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Text('Pedido #${order['id_pedido']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cliente: ${order['cliente']}'),
                          Text('Empleado: ${order['empleado']}'),
                          Text(
                              'Fecha de Entrega: ${DateFormat('yyyy-MM-dd HH:mm').format(fechaEntrega)}'),
                          Text('Total: Q${order['totalpedido']}'),
                          Text(
                              'Estado del Pedido: ${estadoPedido ? 'Activo' : 'Inactivo'}'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
