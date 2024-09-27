import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  _InvoicesScreenState createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  List<dynamic> allInvoices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    try {
      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/facturas/obtener'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          allInvoices = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener las facturas.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  Color getInvoiceCardColor(bool status) {
    return status ? Colors.green : Colors.red; // Verde si la factura está activa, rojo si está inactiva
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Facturas'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: allInvoices.length,
              itemBuilder: (context, index) {
                final invoice = allInvoices[index];
                final DateTime fecha = DateTime.parse(invoice['fecha']);
                final bool status = invoice['status'];

                return Card(
                  color: getInvoiceCardColor(status),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text('Factura #${invoice['id_factura']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NIT: ${invoice['nit']}'),
                        Text('Fecha: ${DateFormat('yyyy-MM-dd hh:mm a').format(fecha)}'),
                        Text('Monto: Q${invoice['monto']}'),
                        Text('Pedido ID: ${invoice['id_pedido']}'),
                        Text('Estado: ${status ? 'Activo' : 'Inactivo'}'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
