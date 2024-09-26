import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key});

  @override
  _PurchasesScreenState createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
  List<dynamic> allPurchases = [];
  List<dynamic> filteredPurchases = [];
  bool isLoading = true;
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    fetchPurchases();
  }

  Future<void> fetchPurchases() async {
    try {
      final keyValueStorageService = KeyValueStorageServiceImpl();
      final token = await keyValueStorageService.getValue<String>('token');

      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/compras/obtener'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          allPurchases = json.decode(response.body);
          isLoading = false;
          filteredPurchases = allPurchases;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          allPurchases = [];
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener las compras.');
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
        filterPurchasesByDateRange();
      });
    }
  }

  void filterPurchasesByDateRange() {
    if (selectedDateRange == null) return;

    setState(() {
      filteredPurchases = allPurchases.where((purchase) {
        DateTime purchaseDate = DateTime.parse(purchase['fecha_compra']);
        return purchaseDate.isAfter(selectedDateRange!.start) &&
            purchaseDate.isBefore(selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    });
  }

  String formatDate(String dateString) {
    final DateTime dateTime = DateTime.parse(dateString);
    final DateFormat formatter = DateFormat('yyyy-MM-dd hh:mm:ss a');
    return formatter.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 30),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Compras'),
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
                  child: const Icon(Icons.calendar_month),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPurchases.isEmpty
                    ? const Center(child: Text('No hay compras disponibles.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: filteredPurchases.length,
                        itemBuilder: (context, index) {
                          final purchase = filteredPurchases[index];

                          return GestureDetector(
                            onTap: () {
                              _showPurchaseDetails(context, purchase['id_compra']);
                            },
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Proveedor: ${purchase['nombre']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Fecha de Compra: ${formatDate(purchase['fecha_compra'])}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Total: Q${purchase['total_compra']}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
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

  Future<void> _showPurchaseDetails(BuildContext context, int purchaseId) async {
    try {
      final keyValueStorageService = KeyValueStorageServiceImpl();
      final token = await keyValueStorageService.getValue<String>('token');

      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/detalleCompras/obtenerPorId/$purchaseId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final purchaseDetails = json.decode(response.body);
        _showPurchaseDialog(context, purchaseDetails);
      } else {
        throw Exception('Error al obtener los detalles de la compra.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _showPurchaseDialog(BuildContext context, Map<String, dynamic> purchaseDetails) {
    print(purchaseDetails);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Detalles'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Compra #:${purchaseDetails['id_compra']}', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                ListTile(
                  title: Text('Producto: ${purchaseDetails['producto']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cantidad: ${purchaseDetails['cantidad']}'),
                      Text('Precio Compra: Q${purchaseDetails['precio_compra']}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
