import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  _InvoicesScreenState createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  List<dynamic> allInvoices = [];
  List<dynamic> filteredInvoices = [];
  bool isLoading = true;
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    try {
      final keyValueStorageService = KeyValueStorageServiceImpl();
      final token = await keyValueStorageService.getValue<String>('token');

      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/facturas/obtener'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          allInvoices = json.decode(response.body);
          filteredInvoices = allInvoices; 
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

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
    );

    if (picked != null && picked != selectedDateRange) {
      setState(() {
        selectedDateRange = picked;
        filterInvoicesByDateRange();
      });
    }
  }

  void filterInvoicesByDateRange() {
    if (selectedDateRange == null) return;

    setState(() {
      filteredInvoices = allInvoices.where((invoice) {
        DateTime invoiceDate = DateTime.parse(invoice['fecha']);
        return invoiceDate.isAfter(selectedDateRange!.start) &&
            invoiceDate.isBefore(selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    });
  }

  Color getInvoiceCardColor(String status) {
    switch (status) {
      case 'A':
        return const Color(0xFFC8E6C9);
      case 'E':
        return const Color(0xFFBBDEFB);
      case 'N':
        return const Color(0xFFFFCDD2);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Facturas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDateRange == null
                      ? 'Seleccione un rango de fechas'
                      : 'Desde: ${DateFormat('yyyy-MM-dd').format(selectedDateRange!.start)} - Hasta: ${DateFormat('yyyy-MM-dd').format(selectedDateRange!.end)}',
                  style: const TextStyle(fontSize: 16),
                ),
                ElevatedButton(
                  onPressed: () => _selectDateRange(context),
                  child: const Icon(Icons.calendar_today),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredInvoices.isEmpty
                    ? const Center(child: Text('No hay facturas disponibles.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: filteredInvoices.length,
                        itemBuilder: (context, index) {
                          final invoice = filteredInvoices[index];
                          final DateTime fecha = DateTime.parse(invoice['fecha']);
                          final String status = invoice['status'];

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
                                  Text('Pedido # ${invoice['id_pedido']}'),
                                  Text('Estado: ${status == 'A' ? 'Activo' : status == 'E' ? 'Entregado' : 'Cancelado'}'),
                                ],
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
}
