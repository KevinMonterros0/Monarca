import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monarca/features/auth/infrastructure/mappers/user_sesion.dart';
import 'package:monarca/features/auth/presentation/providers/auth_provider.dart';
import 'package:monarca/features/auth/presentation/providers/users_provider.dart';
import 'package:monarca/features/shared/shared.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SideMenu extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const SideMenu({super.key, required this.scaffoldKey});

  @override
  SideMenuState createState() => SideMenuState();
}

class SideMenuState extends ConsumerState<SideMenu> {
  int navDrawerIndex = 0;
  List<Menu> menuItems = [];

  @override
  void initState() {
    super.initState();
    _fetchMenus();
  }

  Future<void> _fetchMenus() async {
    final userId = await UserSession().getUserId();
    final token = await keyValueStorageService.getValue<String>('token');
    if (userId != null) {
      final response = await http.get(
        Uri.parse('https://apiproyectomonarca.fly.dev/api/menus/obtenerPorUsuario/$userId'),
        headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          menuItems = data.map((item) => Menu.fromJson(item)).toList();
        });
      } else {
        print('Error al obtener los menús: ${response.statusCode}');
      }
    }
  }

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

        final selectedItem = menuItems[value].url;
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
          future: UserSession().getUsername(),
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
        ...menuItems.map((menu) => NavigationDrawerDestination(
          icon: Icon(_getIconData(menu.icon)),
          label: Text(menu.nombre),
        )),
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

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'person':
        return Icons.person;
      case 'inventory':
        return Icons.inventory;
      case 'sell':
        return Icons.sell;
      case 'supervisor_account':
        return Icons.supervisor_account;
      case 'badge':
        return Icons.badge;
      case 'av_timer':
        return Icons.av_timer;
      case 'face':
        return Icons.face;    
      case 'shopping_cart_checkout':
        return Icons.shopping_cart_checkout;
      case 'list_alt':
        return Icons.list_alt;
      case 'local_shipping':
        return Icons.local_shipping;
      default:
        return Icons.help_outline;
    }
  }
}

class Menu {
  final String nombre;
  final String url;
  final String icon;

  Menu({required this.nombre, required this.url, required this.icon});

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      nombre: json['nombre'],
      url: json['url'],
      icon: json['icon'],
    );
  }
}
