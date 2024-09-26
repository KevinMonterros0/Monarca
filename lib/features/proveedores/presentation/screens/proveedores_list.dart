import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

double globalTotalAmount = 0.0;
List<Map<String, dynamic>> cart = [];

class ProductListScreen extends StatefulWidget {
  final List<dynamic> products;
  final String supplierName;
  final int supplierId;

  const ProductListScreen({
    Key? key,
    required this.products,
    required this.supplierName,
    required this.supplierId,
  }) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<int> quantities = [];
  double productTotal = 0.0;

  @override
  void initState() {
    super.initState();
    quantities = List<int>.filled(widget.products.length, 0);
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
        'id_proveedor': widget.supplierId,
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
                                subtitle: Text('Cantidad: ${product['quantity']} | Precio: Q${product['precio']}'),
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
                        _sendPurchaseRequest(context);
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
      globalTotalAmount -= product['precio'] * product['quantity'];
      cart.removeAt(index);
    });
  }

  void _sendPurchaseRequest(BuildContext context) async {
    try {
      final int noFactura = Random().nextInt(900000) + 100000;

      final purchaseResponse = await http.post(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/compras/crear'),
        headers: {
          'Authorization': 'Bearer your_token_here',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'No_factura': noFactura,
          'Total_Compra': globalTotalAmount,
          'Id_proveedor': cart.first['id_proveedor'],
        }),
      );

      if (purchaseResponse.statusCode == 201) {
        final purchaseData = json.decode(purchaseResponse.body);
        final int idCompra = purchaseData['id_compra'];

        for (var product in cart) {
          double productTotal = (product['precio'] as num).toDouble() * product['quantity'].toDouble();

          final detailResponse = await http.post(
            Uri.parse('https://apiproyectomonarca.fly.dev/api/detalleCompras/crear'),
            headers: {
              'Authorization': 'Bearer your_token_here',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'Id_Compra': idCompra,
              'Id_Producto': product['id'],
              'Cantidad': product['quantity'],
              'Precio_Compra': productTotal,
            }),
          );

          if (detailResponse.statusCode != 201) {
            throw Exception('Error al enviar el detalle del producto ${product['nombre']}.');
          }
        }

        setState(() {
          cart.clear();
          globalTotalAmount = 0.0;
        });

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compra realizada exitosamente.')),
        );
      } else {
        throw Exception('Error al realizar la compra.');
      }
    } catch (e) {
      print('Error: $e');
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un error al realizar la compra.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Productos de ${widget.supplierName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              _showCartSummary(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.products.isEmpty
                ? const Center(child: Text('No hay productos para este proveedor.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: widget.products.length,
                    itemBuilder: (context, index) {
                      final product = widget.products[index];

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
                                      productTotal -= product['precio_compra'].toDouble();
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
                                    productTotal += product['precio_compra'].toDouble();
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
                    for (var product in widget.products) {
                      _updateCart(product, 0);
                    }
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
  }
}
