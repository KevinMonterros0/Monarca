import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:monarca/features/auth/presentation/providers/users_provider.dart';

final employeeProvider =
    StateNotifierProvider<EmployeeNotifier, EmployeeState>((ref) {
  return EmployeeNotifier();
});

class EmployeeNotifier extends StateNotifier<EmployeeState> {
  EmployeeNotifier() : super(EmployeeState());

  Future<void> fetchEmployees() async {
    try {
      final token = await keyValueStorageService.getValue<String>('token');
      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/empleados/obtener'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> employeeList = json.decode(response.body);
        state = state.copyWith(employees: employeeList, filteredEmployees: employeeList);
      } else {
        throw Exception('Error al obtener la lista de empleados.');
      }
    } catch (e) {
      print('Error al obtener la lista de empleados: $e');
    }
  }

  void filterEmployeesByName(String query) {
    final filtered = state.employees.where((employee) {
      final nameLower = employee['nombre'].toLowerCase();
      final searchLower = query.toLowerCase();
      return nameLower.contains(searchLower);
    }).toList();

    state = state.copyWith(filteredEmployees: filtered);
  }
}

class EmployeeState {
  final List<dynamic> employees;
  final List<dynamic> filteredEmployees;

  EmployeeState({
    this.employees = const [],
    this.filteredEmployees = const [],
  });

  EmployeeState copyWith({List<dynamic>? employees, List<dynamic>? filteredEmployees}) {
    return EmployeeState(
      employees: employees ?? this.employees,
      filteredEmployees: filteredEmployees ?? this.filteredEmployees,
    );
  }
}

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  _EmployeesScreenState createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(employeeProvider.notifier).fetchEmployees();
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
            context.push('/');
          },
        ),
        title: const Text('Empleados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, size: 30),
            onPressed: () {
              context.push('/empleadosCreate');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref.read(employeeProvider.notifier).filterEmployeesByName(value);
              },
            ),
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final employeeState = ref.watch(employeeProvider);

                if (employeeState.filteredEmployees.isEmpty) {
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
                  itemCount: employeeState.filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = employeeState.filteredEmployees[index];

                    return GestureDetector(
                      onTap: () {
                        _showEditDeleteOptions(
                            context, employee['id_empleado'], employee['nombre']);
                      },
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/user.png',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              employee['nombre'],
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

  void _showEditDeleteOptions(BuildContext context, int employeeId, String employeeName) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/empleadosDetail', extra: employeeId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Eliminar'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(context, employeeId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, int employeeId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text('¿Estás seguro de que deseas eliminar este empleado?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteEmployee(employeeId);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEmployee(int employeeId) async {
    try {
      final token = await keyValueStorageService.getValue<String>('token');
      final response = await http.delete(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/empleados/eliminar/$employeeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Empleado con ID $employeeId eliminado correctamente.'),
          ),
        );

        ref.read(employeeProvider.notifier).fetchEmployees();
      } else if (response.statusCode == 400) {
        final responseBody = json.decode(response.body);
        final errorMessage = responseBody['error'] ?? 'Error al eliminar el empleado.';

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
          ),
        );
      } else {
        throw Exception('Error al eliminar el empleado.');
      }
    } catch (e) {
      print('Error: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error al eliminar el empleado.'),
        ),
      );
    }
  }
}
