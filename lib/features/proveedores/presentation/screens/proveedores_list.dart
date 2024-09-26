import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

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
  final TextEditingController _invoiceNumberController = TextEditingController();
  String? _invoiceError;

  @override
  void initState() {
    super.initState();
    quantities = List<int>.filled(widget.products.length, 0);
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar salida'),
        content: const Text('¿Deseas salir? Todos los valores totales serán restablecidos a 0 y el carrito será limpiado.'),
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
              });
              Navigator.of(context).pop(true); 
            },
            child: const Text('Sí'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await _showExitConfirmationDialog(context);
    return shouldExit;
  }

  String? _validateInvoiceNumber(String invoiceNumber) {
    final RegExp regex = RegExp(r'^\d{6,20}$');
    if (invoiceNumber.isEmpty) {
      return 'El número de factura es obligatorio';
    } else if (!regex.hasMatch(invoiceNumber)) {
      return 'Debe contener entre 6 y 20 dígitos';
    }
    return null;
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

  void _removeFromCart(Map<String, dynamic> product, int index) {
    setState(() {
      globalTotalAmount -= product['precio'] * product['quantity'];
      cart.removeAt(index);
    });
  }

  void _sendPurchaseRequest(BuildContext context, String noFactura) async {
    final localContext = context; 

    try {
      final token = await KeyValueStorageServiceImpl().getValue<String>('token');
      final purchaseResponse = await http.post(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/compras/crear'),
        headers: {
          'Authorization': 'Bearer $token',
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
              'Authorization': 'Bearer $token',
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

        if (mounted) {
          setState(() {
            cart.clear();
            globalTotalAmount = 0.0;
          });

          Navigator.of(context).pop();
          context.push('/proveedores');
          ScaffoldMessenger.of(localContext).showSnackBar(
            const SnackBar(content: Text('Compra realizada exitosamente.')),
          );
        }
      } else {
        throw Exception('Error al realizar la compra.');
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(localContext).showSnackBar(
          const SnackBar(content: Text('Ocurrió un error al realizar la compra.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
                      globalTotalAmount = 0.0;
                      cart.clear();
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Producto agregado exitosamente.')),
                    );
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showCartSummary(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Resumen de Productos Comprados',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextField(
                      controller: _invoiceNumberController,
                      decoration: InputDecoration(
                        labelText: 'Número de Factura',
                        errorText: _invoiceError,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 20,
                      style: const TextStyle(fontSize: 16),
                      onChanged: (value) {
                        setState(() {
                          _invoiceError = _validateInvoiceNumber(value);
                        });
                      },
                    ),
                    cart.isEmpty
                        ? const Center(child: Text('No hay productos en el carrito.'))
                        : ListView.builder(
                            shrinkWrap: true,
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
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Total: Q$globalTotalAmount', style: const TextStyle(fontSize: 20)),
                    ),
                    Visibility(
                      visible: cart.isNotEmpty,
                      child: ElevatedButton(
                        onPressed: () {
                          final noFactura = _invoiceNumberController.text;
                          final error = _validateInvoiceNumber(noFactura);
                          if (error == null) {
                            _sendPurchaseRequest(context, noFactura);
                          } else {
                            setState(() {
                              _invoiceError = error;
                            });
                          }
                        },
                        child: const Text('Comprar'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
