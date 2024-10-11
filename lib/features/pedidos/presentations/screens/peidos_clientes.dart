import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

// Provider que gestiona el estado de los clientes activos
final activeClientsProvider = StateNotifierProvider<ActiveClientsNotifier, ActiveClientsState>((ref) {
  return ActiveClientsNotifier();
});

// Notifier que maneja la lógica de obtener y filtrar clientes activos
class ActiveClientsNotifier extends StateNotifier<ActiveClientsState> {
  List<dynamic> allClients = [];

  ActiveClientsNotifier() : super(ActiveClientsState());

  // Función para obtener clientes activos desde la API
  Future<void> fetchActiveClients() async {
    try {
      final token = await KeyValueStorageServiceImpl().getValue<String>('token');
      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/clientes/obtenerActivos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> clientsList = json.decode(response.body);
        allClients = clientsList;
        state = state.copyWith(clients: clientsList);
      } else {
        throw Exception('Error al obtener la lista de clientes activos.');
      }
    } catch (e) {
      print('Error al obtener la lista de clientes activos: $e');
    }
  }

  // Función para filtrar clientes activos por nombre o teléfono
  void filterClientsByName(String query) {
    if (query.isEmpty) {
      state = state.copyWith(clients: allClients);
    } else {
      final filteredClients = allClients.where((client) {
        return client['nombre'].toLowerCase().contains(query.toLowerCase()) ||
               client['telefono'].toString().toLowerCase().contains(query.toLowerCase());
      }).toList();
      state = state.copyWith(clients: filteredClients);
    }
  }
}

// Estado de los clientes activos
class ActiveClientsState {
  final List<dynamic> clients;

  ActiveClientsState({this.clients = const []});

  ActiveClientsState copyWith({List<dynamic>? clients}) {
    return ActiveClientsState(
      clients: clients ?? this.clients,
    );
  }
}

// Pantalla de búsqueda de clientes activos
class ActiveClientsScreen extends ConsumerStatefulWidget {
  const ActiveClientsScreen({super.key});

  @override
  _ActiveClientsScreenState createState() => _ActiveClientsScreenState();
}

class _ActiveClientsScreenState extends ConsumerState<ActiveClientsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Obtener la lista de clientes activos cuando se inicializa la pantalla
    ref.read(activeClientsProvider.notifier).fetchActiveClients();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = (width / 200).floor(); // Ajuste dinámico del número de columnas

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 30),
          onPressed: () {
            context.pop();
          },
        ),
        title: const Text('Clientes Activos'),
      ),
      body: Column(
        children: [
          // Campo de búsqueda
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
                ref.read(activeClientsProvider.notifier).filterClientsByName(value); // Filtrar clientes
              },
            ),
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final clientsState = ref.watch(activeClientsProvider);

                if (clientsState.clients.isEmpty) {
                  return const Center(child: CircularProgressIndicator()); // Mostrar indicador de carga
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: clientsState.clients.length,
                  itemBuilder: (context, index) {
                    final client = clientsState.clients[index];

                    return GestureDetector(
                      onTap: () {
                        _selectClient(context, client['id_cliente']); // Seleccionar cliente
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
                              Icons.person,
                              size: 60,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              client['nombre'],
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

  void _selectClient(BuildContext context, int idCliente) {
  context.push('/pedidosRepartidor', extra: idCliente);
}

}
