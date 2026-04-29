import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/admin/admin_dashboard.dart';
import '../features/equipos/equipos_screen.dart';
import '../features/jugadores/jugadores_screen.dart';
import '../features/calendario/calendario_screen.dart';
import '../features/resultados/resultados_screen.dart';
import '../features/posiciones/posiciones_screen.dart';
import '../features/estadisticas/estadisticas_screen.dart';
import '../widgets/main_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final onLogin = state.matchedLocation == '/';
      if (!loggedIn && !onLogin) return '/';
      if (loggedIn && onLogin) return '/home';
      return null;
    },
    refreshListenable: auth,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
          GoRoute(path: '/calendario', builder: (c, s) => const CalendarioScreen()),
          GoRoute(path: '/posiciones', builder: (c, s) => const PosicionesScreen()),
          GoRoute(path: '/equipos', builder: (c, s) => const EquiposScreen()),
          GoRoute(path: '/jugadores', builder: (c, s) => const JugadoresScreen()),
          GoRoute(path: '/resultados', builder: (c, s) => const ResultadosScreen()),
          GoRoute(path: '/estadisticas', builder: (c, s) => const EstadisticasScreen()),
          GoRoute(path: '/admin', builder: (c, s) => const AdminDashboard()),
        ],
      ),
    ],
  );
}
