import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({Key? key}) : super(key: key);

  @override
  _ProductosScreenState createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  List<dynamic> productos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProductos();
  }

  Future<void> fetchProductos() async {
    try {
      final token = await KeyValueStorageServiceImpl().getValue<String>('token');

      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/productos/obtener'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          productos = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener los productos');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Color getColor(String nombre, int cantidad) {
    if (nombre.toLowerCase() == 'agua') {
      if (cantidad >= 8000) {
        return Colors.green;
      } else if (cantidad >= 1000 && cantidad < 4000) {
        return const Color(0xFFB58900); 
      } else {
        return Colors.red;
      }
    } else {
      if (cantidad >= 10) {
        return Colors.green;
      } else if (cantidad >= 5 && cantidad < 10) {
        return const Color(0xFFB58900); 
      } else {
        return Colors.red;
      }
    }
  }

  Icon getIcon(String nombre, int cantidad) {
    final color = getColor(nombre, cantidad);
    if (color == Colors.green) {
      return const Icon(Icons.check_circle, color: Colors.green);
    } else if (color == const Color(0xFFB58900)) {
      return const Icon(Icons.warning, color: Color(0xFFB58900)); 
    } else {
      return const Icon(Icons.error, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: productos.length,
              itemBuilder: (context, index) {
                final producto = productos[index];
                final nombre = producto['nombre'];
                final cantidad = producto['cantidad_inventario'];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: getIcon(nombre, cantidad),
                    title: Text(
                      nombre,
                      style: const TextStyle(fontSize: 18),
                    ),
                    subtitle: Text(
                      'Inventario: $cantidad',
                      style: TextStyle(
                        color: getColor(nombre, cantidad),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
