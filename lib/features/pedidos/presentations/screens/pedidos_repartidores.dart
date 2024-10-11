import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

final repartidoresProvider =
    StateNotifierProvider<RepartidoresNotifier, RepartidoresState>((ref) {
  return RepartidoresNotifier();
});

class RepartidoresNotifier extends StateNotifier<RepartidoresState> {
  List<dynamic> allRepartidores = [];

  RepartidoresNotifier() : super(RepartidoresState());

  Future<void> fetchRepartidores() async {
    try {
      final token =
          await KeyValueStorageServiceImpl().getValue<String>('token');
      final response = await http.get(
        Uri.parse(
            'https://apiproyectomonarca.fly.dev/api/empleados/obtenerRepartidores'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> repartidoresList = json.decode(response.body);
        allRepartidores = repartidoresList;
        state = state.copyWith(repartidores: repartidoresList);
      } else {
        throw Exception('Error al obtener la lista de repartidores.');
      }
    } catch (e) {
      print('Error al obtener la lista de repartidores: $e');
    }
  }

  void filterRepartidoresByName(String query) {
    if (query.isEmpty) {
      state = state.copyWith(repartidores: allRepartidores);
    } else {
      final filteredRepartidores = allRepartidores.where((repartidor) {
        return repartidor['nombre']
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            repartidor['telefono']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase());
      }).toList();
      state = state.copyWith(repartidores: filteredRepartidores);
    }
  }
}

class RepartidoresState {
  final List<dynamic> repartidores;

  RepartidoresState({this.repartidores = const []});

  RepartidoresState copyWith({List<dynamic>? repartidores}) {
    return RepartidoresState(
      repartidores: repartidores ?? this.repartidores,
    );
  }
}

class RepartidorSearchScreen extends ConsumerStatefulWidget {
  final int idCliente;

  const RepartidorSearchScreen({super.key, required this.idCliente});

  @override
  _RepartidorSearchScreenState createState() => _RepartidorSearchScreenState();
}

class _RepartidorSearchScreenState
    extends ConsumerState<RepartidorSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(repartidoresProvider.notifier).fetchRepartidores();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = (width / 200).floor();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 30),
          onPressed: () {
            context.pop();
          },
        ),
        title: const Text('Repartidores'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre o teléfono',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref
                    .read(repartidoresProvider.notifier)
                    .filterRepartidoresByName(value);
              },
            ),
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final repartidoresState = ref.watch(repartidoresProvider);

                if (repartidoresState.repartidores.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: repartidoresState.repartidores.length,
                  itemBuilder: (context, index) {
                    final repartidor = repartidoresState.repartidores[index];

                    return GestureDetector(
                      onTap: () {
                        _selectRepartidor(context, repartidor['id_empleado']);
                      },
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.delivery_dining,
                              size: 60,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              repartidor['nombre'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _selectRepartidor(BuildContext context, int idRepartidor) {
    context.push('/pedidosCrear',
        extra: {'id_cliente': widget.idCliente, 'id_repartidor': idRepartidor});
  }
}
