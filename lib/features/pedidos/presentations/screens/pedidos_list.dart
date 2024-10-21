import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:monarca/features/auth/infrastructure/mappers/user_sesion.dart';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  _OrdersListScreenState createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  List<dynamic> allOrders = [];
  List<dynamic> filteredOrders = [];
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate ?? DateTime.now();
        print(selectedDate);
        filterOrdersByDate(selectedDate!);
      });
    }
  }

  void filterOrdersByDate(DateTime date) {
    final String formattedDate = DateFormat('yyyy-MM-dd').format(date);

    setState(() {
      filteredOrders = allOrders.where((order) {
        final String fechaEntrega = DateFormat('yyyy-MM-dd')
            .format(DateTime.parse(order['fecha_entrega']));
        return fechaEntrega == formattedDate;
      }).toList();
    });
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
          filterOrdersByDate(selectedDate);
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

  Future<void> fetchOrdersByRepartidor() async {
    try {
      final keyValueStorageService = KeyValueStorageServiceImpl();
      final token = await keyValueStorageService.getValue<String>('token');
      final userId = await UserSession().getUserId();

      final response = await http.get(
        Uri.parse(
            'https://apiproyectomonarca.fly.dev/api/pedidos/obtener-por-repartidor/$userId'),
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

  Future<void> _fetchUserRole() async {
    try {
      final userId = await UserSession().getUserId();

      final response = await Dio().get(
          'https://apiproyectomonarca.fly.dev/api/rolUsuarios/obtener-public/$userId');
      final List<dynamic> roles = response.data;

      if (_hasValidRole(roles)) {
        await fetchOrders();
      } else {
        await fetchOrdersByRepartidor();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
    }
  }

  bool _hasValidRole(List<dynamic> roles) {
    for (var role in roles) {
      if (role['id_rol'] != 2) {
        return true;
      }
    }
    return false;
  }

  Future<void> changeOrderStatus(int idPedido, String newStatus) async {
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
          const SnackBar(
              content: Text('Estado del pedido actualizado exitosamente')),
        );
        await fetchOrders();
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

  Color getOrderCardColor(DateTime fechaEntrega, String estadoPedido) {
    final now = DateTime.now();
    final durationToDelivery = fechaEntrega.difference(now);

    if (estadoPedido == 'N') {
      return Colors.grey;
    } else if (estadoPedido == 'E') {
      return const Color(0xFFA7C7E7);
    } else if (durationToDelivery.inHours >= 2) {
      return const Color(0xFF99FF99);
    } else if (durationToDelivery.inHours == 1) {
      return const Color(0xFFFFEB99);
    } else if (durationToDelivery.inMinutes > 0 &&
        durationToDelivery.inMinutes < 60) {
      return const Color(0xFFFFEB99);
    } else if (now.isAfter(fechaEntrega)) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              _selectDate(context);
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                final DateTime fechaEntrega =
                    DateTime.parse(order['fecha_entrega']);
                final String estadoPedido = order['estado_pedido'];

                return Dismissible(
                  key: Key(order['id_pedido'].toString()),
                  background: Container(
                    color: const Color(0xFF99FF99),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.check, color: Colors.white, size: 40),
                  ),
                  secondaryBackground: Container(
                    color: const Color(0xFFFF6A6A),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.cancel, color: Colors.white, size: 40),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      await changeOrderStatus(order['id_pedido'], 'N');
                    } else if (direction == DismissDirection.startToEnd) {
                      await changeOrderStatus(order['id_pedido'], 'E');
                    }
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
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cliente: ${order['cliente']}'),
                          Text('Repartidor: ${order['empleado']}'),
                          Text('Fecha de Entrega: ${DateFormat('yyyy-MM-dd').format(fechaEntrega)}'),
                          Text('Total: Q${order['totalpedido']}'),
                          Text('Estado: ${estadoPedido == 'A' ? 'Activo' : estadoPedido == 'E' ? 'Entregado' : 'Cancelado'}'),
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
