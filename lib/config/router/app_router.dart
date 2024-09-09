import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monarca/config/router/auth_router.notifier.dart';
import 'package:monarca/features/auth/auth.dart';
import 'package:monarca/features/auth/presentation/providers/auth_provider.dart';
import 'package:monarca/features/auth/presentation/screens/user_detail_screen.dart';
import 'package:monarca/features/auth/presentation/screens/user_screen.dart';
import 'package:monarca/features/empleados/presentation/screens/empleados.dart';
import 'package:monarca/features/home/presentation/home_screen.dart';
import 'package:monarca/features/roles/presentation/screens/rol_user_create.dart';
import 'package:monarca/features/roles/presentation/screens/user_roles_screen.dart';


final goRouterProvider = Provider((ref){

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
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
  ],

  redirect: (context, state) {
    final isGoingTo = state.matchedLocation;
    final authStatus = goRouterNotifier.authStatus;

    if(isGoingTo == '/splash' && authStatus == AuthStatus.checking) return null;

    if(authStatus == AuthStatus.noAuthenticated){
      if(isGoingTo == '/login') return null;

      return '/login';
    }

    if(authStatus == AuthStatus.authenticated){
      if(isGoingTo == '/login' || isGoingTo == '/splash') return '/';
    }


    return null;
  },
);
});