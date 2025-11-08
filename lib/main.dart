import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/pages/login_screen.dart';
import 'package:gym/pages/main_navigation_screen.dart';
import 'package:gym/pages/selection_screen.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:sqflite/sqflite.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'repositories/database_helper.dart';
import 'blocs/socios_bloc.dart';
import 'blocs/auth_bloc.dart';
import 'blocs/pagos_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa FFI para sqflite si la plataforma es web
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  
  // Inicializar formato de fechas en español
  try {
    await initializeDateFormatting('es_ES', null);
    print('✅ Formato de fechas inicializado correctamente');
  } catch (e) {
    print('⚠️ Error al inicializar formato de fechas: $e');
  }
  
  // Inicializar la base de datos antes de iniciar la app
  try {
    await DatabaseHelper.instance.database;
    print('✅ Base de datos inicializada correctamente');
    
    // Asegurar que el usuario por defecto existe
    await DatabaseHelper.instance.asegurarUsuarioPorDefecto();
    
    // Asegurar que el usuario coach existe (forzar creación si no existe)
    await DatabaseHelper.instance.crearUsuarioCoachManual();
    
    // Crear socios ficticios SOLO en modo debug (para desarrollo/testing)
    // En modo release (producción), NO se crearán socios ficticios
    if (kDebugMode) {
      await DatabaseHelper.instance.crearSociosFicticios();
    }
  } catch (e) {
    print('❌ Error al inicializar base de datos: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc()..add(CheckAuthEvent()),
        ),
        BlocProvider(
          create: (context) => SociosBloc(DatabaseHelper.instance)..add(CargarSociosEvent()),
        ),
        BlocProvider(
          create: (context) => PagosBloc(DatabaseHelper.instance),
        ),
      ],
      child: MaterialApp(
        title: 'Gym Manager',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF40E0D0), // Turquesa vibrante - energía y frescura
            secondary: const Color(0xFF30D5C8), // Turquesa medio - dinamismo
            tertiary: const Color(0xFF4CAF50), // Verde - salud y crecimiento
            surface: const Color(0xFF0A0A0A), // Negro intenso como hierro
            error: const Color(0xFFFF4444), // Rojo para errores (mantener para errores)
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.white,
            onError: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFF000000), // Fondo negro puro
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0A0A0A),
            elevation: 0,
            foregroundColor: Colors.white,
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF1A1A1A),
            elevation: 8,
            shadowColor: const Color(0xFF40E0D0).withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2A2A2A), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF40E0D0), width: 2),
            ),
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/main': (context) => const MainNavigationScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticatedState) {
          return const SelectionScreen();
        } else if (state is AuthUnauthenticatedState || state is AuthInitialState) {
          return const LoginScreen();
        } else if (state is AuthLoadingState) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}