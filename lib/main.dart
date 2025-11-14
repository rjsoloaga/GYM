import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:intl/date_symbol_data_local.dart';

// Servicios
import 'package:gym/services/notification_service.dart';
import 'package:gym/services/background_service.dart';

// Tus imports
import 'package:gym/core/database/database_helper.dart';
import 'package:gym/features/socios/bloc/socios_bloc.dart';

// Autenticación
import 'package:gym/features/socios/bloc/auth_bloc.dart';
import 'package:gym/features/socios/screens/login_screen.dart';
import 'package:gym/features/socios/screens/auth_wrapper.dart';
import 'package:gym/features/socios/screens/main_navigation_screen.dart';

// Gestión de usuarios y aprobación
import 'package:gym/features/auth/screens/gestion_usuarios_screen.dart';
import 'package:gym/features/socios/screens/aprobacion_socios_screen.dart';

// Telegram
import 'package:gym/features/notificaciones/services/telegram_service.dart';
import 'package:gym/core/utils/admin_utils.dart';

// Gestión de planes
import 'package:gym/features/planes/models/plan.dart';
import 'package:gym/features/planes/screens/planes_list_screen.dart';
import 'package:gym/features/planes/screens/plan_form_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar servicios
  await NotificationService.initialize();
  await BackgroundService.initialize();

  // DIAGNÓSTICO: Capturar errores específicos de DropdownButton
  FlutterError.onError = (details) {
    final exception = details.exception.toString();
    if (exception.contains("DropdownButton") && exception.contains("Pendiente")) {
      debugPrint("🚨 ERROR DROPDOWN DETECTADO:");
      debugPrint("Exception: $exception");
      debugPrint("Stack: ${details.stack}");
    }
    FlutterError.presentError(details);
  };

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  // Inicializar la base de datos
  await DatabaseHelper.instance.database;

  // Asegurarse de que el usuario administrador exista
  try {
    await AdminUtils.ensureAdminUserExists();
  } catch (e) {
    print('⚠️ Advertencia: No se pudo verificar el usuario administrador: $e');
  }

  // Inicializar formato de fechas
  await initializeDateFormatting('es_ES', null);

  // Iniciar la aplicación
  runApp(const MyApp());
  
  // Iniciar verificación periódica de Telegram y el servicio en segundo plano
  startTelegramAutoCheck();
}

// Verificación automática de Telegram y arranque del servicio en segundo plano
Future<void> startTelegramAutoCheck() async {
  // Verificar nuevos mensajes cada 5 minutos
  Timer.periodic(Duration(seconds: 5), (timer) async {
    try {
      await TelegramService.getUpdates();
      print('✅ Verificación automática de Telegram completada');
    } catch (e) {
      print('❌ Error en verificación automática: $e');
    }
  });
  // Iniciar el servicio en segundo plano para Telegram
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await BackgroundService.start();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(),
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
        home: const AuthWrapper(),//home: const EmergencyResetScreen(), // TEMPORAL//
        routes: {
          '/login': (context) => LoginScreen(),
          '/main': (context) => const MainNavigationScreen(),
          '/gestion-usuarios': (context) => GestionUsuariosScreen(),
          '/aprobacion-socios': (context) => AprobacionSociosScreen(),
          '/planes': (context) => const PlanesListScreen(),
          '/planes/form': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            return PlanFormScreen(
              plan: args is Plan ? args : null,
            );
          },
        },
      ),
    );
  }
}
