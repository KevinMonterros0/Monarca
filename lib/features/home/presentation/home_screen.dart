import 'package:flutter/material.dart';
import 'package:monarca/features/auth/infrastructure/mappers/user_sesion.dart';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';
import 'package:monarca/features/shared/shared.dart';
import 'package:dio/dio.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      appBar: AppBar(
        title: const Text('Inicio'),
      ),
      body: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  __HomeViewState createState() => __HomeViewState();
}

class __HomeViewState extends State<_HomeView> {
  String? ganancia; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    try {
      final userId = await UserSession().getUserId();

      final response = await Dio().get(
          'https://apiproyectomonarca.fly.dev/api/rolUsuarios/obtener-public/$userId');
      final List<dynamic> roles = response.data;

      if (_hasValidRole(roles)) {
        await _fetchGanancia();
      } else {
        setState(() {
          isLoading = false; 
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false; 
      });
      print(e);
    }
  }

  bool _hasValidRole(List<dynamic> roles) {
    for (var role in roles) {
      
      if (role['id_rol'] == 1 || role['id_rol'] == 6) {
        return true;
      }
    }
    return false;
  }

  Future<void> _fetchGanancia() async {
  try {
    final token = await KeyValueStorageServiceImpl().getValue<String>('token');

    final response = await Dio().get(
      'https://apiproyectomonarca.fly.dev/api/balance/obtener-ganancia',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final gananciaData = response.data[0]['sum']; 

    final gananciaValor = double.tryParse(gananciaData) ?? 0.0;

    setState(() {
      ganancia = gananciaValor.toStringAsFixed(2);
      isLoading = false;
    });
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    print(e); 
  }
}



  @override
Widget build(BuildContext context) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Bienvenido a Monarca',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        const Text(
          'Aquí puedes comenzar a explorar la aplicación.',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        if (isLoading)
          const CircularProgressIndicator()
        else if (ganancia != null)
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'La ganancia al día de hoy es: ',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black, 
                  ),
                ),
                TextSpan(
                  text: 'Q$ganancia',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF34965E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
      ],
    ),
  );
}

}
