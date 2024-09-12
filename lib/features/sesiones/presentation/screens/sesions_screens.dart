import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  _SessionsScreenState createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  List<dynamic> allSessions = [];
  List<dynamic> filteredSessions = [];
  bool isLoading = true;
  String selectedFilter = 'Hoy';

  @override
  void initState() {
    super.initState();
    fetchSessions();
  }

  Future<void> fetchSessions() async {
    try {
      final keyValueStorageService = KeyValueStorageServiceImpl();
      final token = await keyValueStorageService.getValue<String>('token');

      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/sesiones/obtener'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          allSessions = json.decode(response.body);
          isLoading = false;
          filterSessions(); 
        });
      } else if (response.statusCode == 404) {
        setState(() {
          allSessions = [];
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener las sesiones.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  void filterSessions() {
    DateTime now = DateTime.now();
    DateTime startDate;

    switch (selectedFilter) {
      case 'Hoy':
        startDate = DateTime(now.year, now.month, now.day);
        print(now);
        break;
      case 'Ayer':
        startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 1));
        break;
      case 'Esta semana':
        int weekday = now.weekday;
        startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
        break;
      case 'Este mes':
        startDate = DateTime(now.year, now.month, -1);
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
    }

    setState(() {
      filteredSessions = allSessions.where((session) {
        DateTime sessionDate = DateTime.parse(session['fec_hora_ini']);
        return sessionDate.isAfter(startDate);
      }).toList();
    });
  }

  String formatDate(String dateString) {
    final DateTime dateTime = DateTime.parse(dateString);
    final DateFormat formatter = DateFormat('yyyy-MM-dd hh:mm:ss a'); // Formato con AM/PM
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
        title: const Text('Sesiones'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedFilter,
              items: <String>['Hoy', 'Ayer', 'Esta semana', 'Este mes']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedFilter = newValue!;
                  filterSessions(); // Filtrar cuando se cambia la selección
                });
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredSessions.isEmpty
                    ? const Center(child: Text('No hay sesiones disponibles.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: filteredSessions.length,
                        itemBuilder: (context, index) {
                          final session = filteredSessions[index];

                          return GestureDetector(
                            onTap: () {
                              _showSessionDetails(context, session['id_sesion']);
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
                                      'Usuario: ${session['username']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Inicio: ${formatDate(session['fec_hora_ini'])}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Fin: ${formatDate(session['fec_hora_fin'])}',
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

  void _showSessionDetails(BuildContext context, int sessionId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Detalles de la sesión'),
                onTap: () {
                  Navigator.pop(context);
                  _showSessionInfoDialog(context, sessionId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSessionInfoDialog(BuildContext context, int sessionId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Detalles de la sesión'),
          content: Text('Información detallada de la sesión ID: $sessionId.'),
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
