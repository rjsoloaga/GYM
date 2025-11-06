import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:intl/date_symbol_data_local.dart';

// Tus imports
import 'package:gym/core/database/database_helper.dart';
import 'package:gym/features/socios/bloc/socios_bloc.dart';

// Autenticación de tu compañera
import 'package:gym/features/socios/bloc/auth_bloc.dart';
import 'package:gym/features/socios/screens/login_screen.dart';
import 'package:gym/features/socios/screens/auth_wrapper.dart';
import 'package:gym/features/socios/screens/main_navigation_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  
  await DatabaseHelper.instance.database;
  await initializeDateFormatting('es_ES', null);
  
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
      ],
      child: MaterialApp(
        title: 'Gym Manager',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF2196F3),
            secondary: const Color(0xFF03DAC6),
            surface: const Color(0xFF1E1E1E),
            error: const Color(0xFFCF6679),
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