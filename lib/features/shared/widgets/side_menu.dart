import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monarca/features/auth/infrastructure/mappers/user_sesion.dart';
import 'package:monarca/features/auth/presentation/providers/auth_provider.dart';
import 'package:monarca/features/shared/shared.dart';

class SideMenu extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const SideMenu({super.key, required this.scaffoldKey});

  @override
  SideMenuState createState() => SideMenuState();
}

class SideMenuState extends ConsumerState<SideMenu> {
  int navDrawerIndex = 0;

  @override
  Widget build(BuildContext context) {
    final hasNotch = MediaQuery.of(context).viewPadding.top > 35;
    final textStyles = Theme.of(context).textTheme;

    return NavigationDrawer(
      elevation: 1,
      selectedIndex: navDrawerIndex,
      onDestinationSelected: (value) {
        setState(() {
          navDrawerIndex = value;
        });

        final selectedItem = _handleNavigation(value, context);
        if (selectedItem != null) {
          context.push(selectedItem);
        }
        widget.scaffoldKey.currentState?.closeDrawer();
      },
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, hasNotch ? 0 : 20, 16, 0),
          child: Text('Saludos', style: textStyles.titleMedium),
        ),
        FutureBuilder<String?>(
          future: UserSession().getUsername(), // Obtiene el username
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 16, 10),
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 16, 10),
                child: Text('Error al cargar usuario', style: textStyles.titleSmall),
              );
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 16, 10),
              child: Text(snapshot.data ?? 'Usuario no encontrado', style: textStyles.titleSmall),
            );
          },
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.person),
          label: Text('Usuario'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.inventory),
          label: Text('Productos'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.sell),
          label: Text('Venta'),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
          child: Divider(),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 10, 16, 10),
          child: Text('Otras opciones'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomFilledButton(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
              },
              text: 'Cerrar sesión'),
        ),
      ],
    );
  }

  String? _handleNavigation(int index, BuildContext context) {
    switch (index) {
      case 0:
        return '/users';
      case 1:
        return '/productos';
      case 2:
        return '/venta';
      default:
        return null;
    }
  }
}
