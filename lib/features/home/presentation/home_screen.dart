import 'package:flutter/material.dart';
import 'package:monarca/features/auth/infrastructure/errors/auth_error.dart';
import 'package:monarca/features/auth/infrastructure/mappers/user_sesion.dart';
import 'package:monarca/features/auth/presentation/providers/users_provider.dart';
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
    _insertSesion(); 
  }

Future<void> _insertSesion() async {
  try {
    final token = await keyValueStorageService.getValue<String>('token');
    final userId = await UserSession().getUserId();

    final response = await Dio().post(
      'https://apiproyectomonarca.fly.dev/api/sesiones/crear',
      data: {
        'Id_usuario': userId,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode != 201) {
      throw CustomError('Error al crear la sesión: ${response.data}');
    }
  }catch(e){
    print(e);
  }
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

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Bienvenido a Monarca',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text(
            'Aquí puedes comenzar a explorar la aplicación.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
