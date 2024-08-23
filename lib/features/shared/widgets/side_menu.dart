import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monarca/features/auth/infrastructure/mappers/user_sesion.dart';
import 'package:monarca/features/auth/presentation/providers/auth_provider.dart';
import 'package:monarca/features/shared/shared.dart';

class SideMenu extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String? globalUsername = UserSession().username;

  SideMenu({super.key, required this.scaffoldKey});

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

          // final menuItem = appMenuItems[value];
          // context.push( menuItem.link );
          widget.scaffoldKey.currentState?.closeDrawer();
        },
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, hasNotch ? 0 : 20, 16, 0),
            child: Text('Saludos', style: textStyles.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 10),
            child: Text(UserSession().username.toString(),
                style: textStyles.titleSmall),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.home_outlined),
            label: Text('Productos'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.home_outlined),
            label: Text('PROVEEDOR'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.home_outlined),
            label: Text('VENTA'),
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
        ]);
  }
}
