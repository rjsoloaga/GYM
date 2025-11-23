import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Servicios
import 'package:gym/services/notification_service.dart';
import 'package:gym/services/background_service.dart';
import 'package:gym/services/gym_config_service.dart';
import 'package:gym/services/license_service.dart';

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

// Configuración
import 'package:gym/features/configuracion/screens/configuracion_general_screen.dart';
import 'package:gym/features/rutinas/screens/lista_ejercicios_screen.dart';
import 'package:gym/features/rutinas/screens/lista_rutinas_screen.dart';
import 'package:window_manager/window_manager.dart';


Future<void> main() async {
  sqfliteFfiInit();
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar window_manager para desktop
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Inicializar servicios
  await NotificationService.initialize();
  await BackgroundService.initialize();
  
  // Cargar configuración del gym y actualizar título de ventana
  await GymConfigService().loadConfig();
  final nombreGym = await GymConfigService().getNombreGym();
  
  // Actualizar título de ventana en desktop
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    await windowManager.setTitle(nombreGym);
  }

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
    // Para WEB
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    // Para Escritorio (Linux, Windows, Mac)
    databaseFactory = databaseFactoryFfi;
  }

  // Inicializar la base de datos
  await DatabaseHelper.instance.database;

  // Asegurarse de que el usuario administrador exista
  try {
    await AdminUtils.ensureAdminUserExists();
  } catch (e) {
    print('⚠️ Advertencia: No se pudo verificar el usuario administrador: $e');
  }

  // Inicializar sistema de licencias
  await LicenseService().initialize();

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _nombreGym = 'Gym Manager';

  @override
  void initState() {
    super.initState();
    _cargarNombreGym();
  }

  Future<void> _cargarNombreGym() async {
    final gymConfigService = GymConfigService();
    final nombre = await gymConfigService.getNombreGym();
    if (mounted) {
      setState(() => _nombreGym = nombre);
    }
  }

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
      child: ValueListenableBuilder<String>(
        valueListenable: GymConfigService().nombreGymNotifier,
        builder: (context, nombreGym, child) {
          return ValueListenableBuilder<ThemeMode>(
            valueListenable: GymConfigService().themeModeNotifier,
            builder: (context, themeMode, _) {
              return MaterialApp(
                title: nombreGym,
                debugShowCheckedModeBanner: false,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('es', 'ES'),
                  Locale('en', 'US'),
                ],
                locale: const Locale('es', 'ES'),
                themeMode: themeMode,
                // TEMA CLARO
                theme: ThemeData(
                  useMaterial3: true,
                  brightness: Brightness.light,
                  colorScheme: ColorScheme.light(
                    primary: const Color(0xFF2196F3),
                    secondary: const Color(0xFF03DAC6),
                    surface: const Color(0xFFF5F5F5),
                    error: const Color(0xFFB00020),
                    onPrimary: Colors.white,
                    onSecondary: Colors.black,
                    onSurface: Colors.black87,
                  ),
                  scaffoldBackgroundColor: const Color(0xFFFFFFFF),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Color(0xFF2196F3),
                    elevation: 0,
                    foregroundColor: Colors.white,
                  ),
                ),
                // TEMA OSCURO
                darkTheme: ThemeData(
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
                  '/configuracion-general': (context) => const ConfiguracionGeneralScreen(),
                  '/ejercicios': (context) => const ListaEjerciciosScreen(),
                  '/rutinas': (context) => const ListaRutinasScreen(),
                },
              );
            },
          );
        },
      ),
    );
  }
}
