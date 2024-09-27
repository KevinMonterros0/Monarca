import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monarca/config/router/auth_router.notifier.dart';
import 'package:monarca/features/auth/auth.dart';
import 'package:monarca/features/auth/presentation/providers/auth_provider.dart';
import 'package:monarca/features/auth/presentation/screens/user_detail_screen.dart';
import 'package:monarca/features/auth/presentation/screens/user_screen.dart';
import 'package:monarca/features/clientes/presentation/screens/clientes.dart';
import 'package:monarca/features/clientes/presentation/screens/clientes_create.dart';
import 'package:monarca/features/clientes/presentation/screens/clientes_detail_screen.dart';
import 'package:monarca/features/clientes/presentation/screens/clientes_directions_create.dart';
import 'package:monarca/features/clientes/presentation/screens/directions_client.dart';
import 'package:monarca/features/compras/compras.dart';
import 'package:monarca/features/empleados/presentation/screens/empleados.dart';
import 'package:monarca/features/empleados/presentation/screens/empleados_crear.dart';
import 'package:monarca/features/empleados/presentation/screens/empleados_detail.dart';
import 'package:monarca/features/home/presentation/home_screen.dart';
import 'package:monarca/features/proveedores/presentation/screens/proveedores_crear.dart';
import 'package:monarca/features/proveedores/presentation/screens/proveedores_edit.dart';
import 'package:monarca/features/proveedores/presentation/screens/proveedores_list.dart';
import 'package:monarca/features/roles/presentation/screens/pol_permission_create.dart';
import 'package:monarca/features/roles/presentation/screens/rol_create.dart';
import 'package:monarca/features/roles/presentation/screens/rol_user_create.dart';
import 'package:monarca/features/roles/presentation/screens/role_permison_screen.dart';
import 'package:monarca/features/roles/presentation/screens/roles.dart';
import 'package:monarca/features/roles/presentation/screens/user_roles_screen.dart';
import 'package:monarca/features/proveedores/presentation/screens/proveedores.dart';
import 'package:monarca/features/sesiones/presentation/screens/sesions_screens.dart';

final goRouterProvider = Provider((ref) {
  final goRouterNotifier = ref.read(goRouterNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: goRouterNotifier,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const CheckAuthStatusScreen(),
      ),

      ///* Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/registerusers',
        builder: (context, state) => RegisterScreen(),
      ),
      GoRoute(
        path: '/users',
        builder: (context, state) => const UserScreen(),
      ),

      GoRoute(
        path: '/userDetail',
        builder: (context, state) {
          final userId = state.extra as int;
          return UserDetailScreen(userId: userId);
        },
      ),

      GoRoute(
        path: '/userRoles',
        builder: (context, state) {
          final userId = state.extra as int;
          return UserRolesScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/userRolesCreate',
        builder: (context, state) {
          return const RolUserCreate();
        },
      ),
      GoRoute(
        path: '/empleados',
        builder: (context, state) {
          return const EmployeesScreen();
        },
      ),

      GoRoute(
        path: '/empleadosDetail',
        builder: (context, state) {
          final employeeId = state.extra as int;
          return EmployeeDetailScreen(employeeId: employeeId);
        },
      ),

      GoRoute(
        path: '/empleadosCreate',
        builder: (context, state) {
          return const CreateEmployeeScreen();
        },
      ),

      GoRoute(
        path: '/roles',
        builder: (context, state) {
          return const RolesScreen();
        },
      ),

      GoRoute(
        path: '/rolesCreate',
        builder: (context, state) {
          return const RolCreate();
        },
      ),

      GoRoute(
        path: '/rolesMenus',
        builder: (context, state) {
          final roleId = state.extra as int;
          return RolePermissionsScreen(roleId: roleId);
        },
      ),

      GoRoute(
        path: '/sesions',
        builder: (context, state) {
          return const SessionsScreen();
        },
      ),

      GoRoute(
        path: '/rolePermissionsCreate',
        builder: (context, state) {
          return const RoleMenuScreen();
        },
      ),

      GoRoute(
        path: '/proveedores',
        builder: (context, state) {
          return const SupplierProductScreen();
        },
      ),

      GoRoute(
        path: '/proveedoresCreate',
        builder: (context, state) {
          return const CreateSupplierScreen();
        },
      ),

      GoRoute(
        path: '/clientes',
        builder: (context, state) {
          return const CustomerScreen();
        },
      ),

      GoRoute(
        path: '/clientesDetail',
        builder: (context, state) {
          final clienteId = state.extra as int;
          return ClienteDetailScreen(clienteId: clienteId);
        },
      ),

      GoRoute(
        path: '/clientesCreate',
        builder: (context, state) {
          return const CreateClienteScreen();
        },
      ),

      GoRoute(
        path: '/direccionesCliente',
        builder: (context, state) {
          final clienteId = state.extra as int;
          return DireccionesScreen(idCliente: clienteId);
        },
      ),

      GoRoute(
        path: '/direccionesClienteCreate',
        builder: (context, state) {
          final clienteId = state.extra as int;
          return ConnectAddressCustomerScreen(idCliente: clienteId);
        },
      ),
      
      GoRoute(
      path: '/productList',
      builder: (context, state) {
        final params = state.extra as Map<String, dynamic>;
        return ProductListScreen(
          products: params['products'],
          supplierName: params['supplierName'],
          supplierId: params['supplierId'],
        );
      },
    ),
    
    GoRoute(
        path: '/compras',
        builder: (context, state) {
          return const PurchasesScreen();
        },
      ),

      GoRoute(
        path: '/editSupplier',
        builder: (context, state) {
          final proveedorId = state.extra as int;
          return SupplierDetailScreen(supplierId: proveedorId);
        },
      ),


      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    redirect: (context, state) {
      final isGoingTo = state.matchedLocation;
      final authStatus = goRouterNotifier.authStatus;

      if (isGoingTo == '/splash' && authStatus == AuthStatus.checking)
        return null;

      if (authStatus == AuthStatus.noAuthenticated) {
        if (isGoingTo == '/login') return null;

        return '/login';
      }

      if (authStatus == AuthStatus.authenticated) {
        if (isGoingTo == '/login' || isGoingTo == '/splash') return '/';
      }

      return null;
    },
  );
});
