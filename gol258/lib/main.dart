import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase_config.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'features/auth/auth_provider.dart';
import 'features/equipos/equipos_provider.dart';
import 'features/jugadores/jugadores_provider.dart';
import 'features/partidos/partidos_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const Gol258App());
}

class Gol258App extends StatelessWidget {
  const Gol258App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EquiposProvider()),
        ChangeNotifierProvider(create: (_) => JugadoresProvider()),
        ChangeNotifierProvider(create: (_) => PartidosProvider()),
      ],
      child: Builder(
        builder: (context) {
          final auth = context.watch<AuthProvider>();
          final router = createRouter(auth);
          return MaterialApp.router(
            title: 'GOL 258 - CBTis 258',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            routerConfig: router,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('es', 'MX'),
              Locale('en', 'US'),
            ],
          );
        },
      ),
    );
  }
}
