import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/pages/login_screen.dart';
import 'package:gym/pages/main_navigation_screen.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
    
    // Crear socios ficticios si la base de datos está vacía
    await DatabaseHelper.instance.crearSociosFicticios();
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
            primary: const Color(0xFF2196F3), // Azul vibrante
            secondary: const Color(0xFF03DAC6), // Cyan/Turquesa
            surface: const Color(0xFF1E1E1E), // Casi negro
            error: const Color(0xFFCF6679), // Rojo suave
            onPrimary: Colors.white,
            onSecondary: Colors.black,
            onSurface: Colors.white,
            onError: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
            elevation: 0,
            foregroundColor: Colors.white,
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF1E1E1E),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF2C2C2C),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3A3A3A), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
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
          return const MainNavigationScreen();
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