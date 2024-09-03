import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monarca/features/auth/presentation/providers/users_provider.dart';
import 'package:go_router/go_router.dart';

class UserScreen extends ConsumerWidget {
  const UserScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    
    // Calcular el número de columnas en función del ancho de la pantalla
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = (width / 200).floor(); // Ajusta 200 para el tamaño de la columna deseada

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, size: 30), 
            onPressed: () {
              context.push('/registernew');
            },
          ),
        ],
      ),
      body: userState.users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1, 
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: userState.users.length,
              itemBuilder: (context, index) {
                final user = userState.users[index];
                return GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ID de usuario seleccionado: ${user.id}'),
                      ),
                    );
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
                          user.username,
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
            ),
    );
  }
}
