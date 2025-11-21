import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/features/socios/bloc/auth_bloc.dart';
import 'package:gym/features/socios/bloc/socios_bloc.dart';
import 'package:gym/features/socios/screens/dashboard_screen.dart';
import 'package:gym/features/socios/screens/lista_socios_screen.dart';
import 'package:gym/features/notificaciones/services/chatid_registro_service.dart';
import 'package:gym/features/notificaciones/services/notificacion_service.dart';
import 'package:gym/features/socios/screens/aprobacion_socios_screen.dart'; 
import 'package:gym/features/auth/screens/gestion_usuarios_screen.dart';
import 'package:gym/features/socios/models/socio.dart';
import 'package:gym/features/dashboard/screens/admin_reportes_screen.dart';
import 'package:gym/features/auth/models/usuario.dart';
import 'package:gym/features/planes/screens/planes_list_screen.dart';
import 'package:gym/features/socios/screens/lista_socios_inactivos_screen.dart';
import 'package:gym/services/gym_config_service.dart';
import 'package:gym/features/asistencia/screens/registro_asistencia_screen.dart';
import 'package:gym/features/socios/screens/auditoria_screen.dart';
import 'package:gym/features/asistencia/screens/historial_asistencia_screen.dart';
import 'package:gym/features/asistencia/screens/estadisticas_asistencia_screen.dart';
import 'package:gym/features/notificaciones/screens/configuracion_email_screen.dart';
import 'package:gym/features/notificaciones/screens/configuracion_recordatorios_screen.dart';
import 'package:gym/features/configuracion/screens/configuracion_general_screen.dart';
import 'package:gym/features/rutinas/screens/lista_ejercicios_screen.dart';
import 'package:gym/features/rutinas/screens/lista_rutinas_screen.dart';
import 'package:gym/features/socios/widgets/side_menu.dart';
import 'package:intl/intl.dart';


class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0; // Dashboard por defecto
  late final Stream<List<Socio>> _sociosPendientesBroadcast;
  int _dashboardRefreshKey = 0; // fuerza recreación del dashboard
  Timer? _clockTimer;
  Timer? _clockAlignTimer;

  // Mapa de títulos para el AppBar según el índice
  final Map<int, String> _titles = {
    0: 'Dashboard',
    1: 'Gestión de Socios',
    2: 'Registro de Asistencia',
    3: 'Planes',
    4: 'Ejercicios',
    5: 'Rutinas',
    6: 'Configuración General',
    7: 'Configuración de Email',
    8: 'Configuración de Recordatorios',
    9: 'Gestión de Usuarios',
    10: 'Aprobación de Socios',
    11: 'Estadísticas de Asistencia',
    12: 'Historial de Asistencia',
    13: 'Auditoría del Sistema',
    14: 'Socios Inactivos',
  };

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.white),
            SizedBox(width: 8),
            Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthBloc>().add(LogoutEvent());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCF6679)),
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _startClockTimer() {
    _clockTimer?.cancel();
    _clockAlignTimer?.cancel();
    final now = DateTime.now();
    final nextMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute).add(const Duration(minutes: 1));
    final initialDelay = nextMinute.difference(now);
    _clockAlignTimer = Timer(initialDelay, () {
      if (!mounted) return;
      setState(() {});
      _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _clockAlignTimer?.cancel();
    super.dispose();
  }

  Stream<List<Socio>> _sociosPendientesStream() async* {
    while (true) {
      try {
        final sociosPendientes = await ChatIdRegistroService.obtenerSociosPendientes();
        yield sociosPendientes;
        await Future.delayed(Duration(seconds: 30));
      } catch (e) {
        yield [];
        await Future.delayed(Duration(seconds: 30));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _sociosPendientesBroadcast = _sociosPendientesStream().asBroadcastStream();
    setState(() {});
    _startClockTimer();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticatedState) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticatedState) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Determinar si es admin
          bool isAdmin = false;
          if (authState is AuthSuccess) {
            final dynamic usuario = (authState as AuthSuccess).usuario;
            if (usuario is Usuario) {
              isAdmin = usuario.rol == 'admin';
            } else if (usuario is Map) {
              isAdmin = usuario['rol'] == 'admin';
            }
          } else if (authState is AuthAuthenticatedState) {
            final dynamic user = (authState as AuthAuthenticatedState).user;
            if (user is Map) {
              isAdmin = user['rol'] == 'admin';
            }
          }

          return BlocListener<SociosBloc, SociosState>(
            listener: (context, sociosState) {
              if (sociosState is SociosCargadosState) {
                setState(() {
                  _dashboardRefreshKey++; 
                });
              }
            },
            child: Scaffold(
              body: Row(
                children: [
                  // MENÚ LATERAL
                  StreamBuilder<List<Socio>>(
                    stream: _sociosPendientesBroadcast,
                    builder: (context, snapshot) {
                      return SideMenu(
                        selectedIndex: _currentIndex,
                        isAdmin: isAdmin,
                        pendientesCount: snapshot.data?.length ?? 0,
                        onItemSelected: (index) {
                          if (index == -1) {
                            _logout(context);
                          } else {
                            setState(() {
                              _currentIndex = index;
                              if (index == 0) {
                                _dashboardRefreshKey++;
                              }
                            });
                          }
                        },
                      );
                    }
                  ),
                  
                  // CONTENIDO PRINCIPAL
                  Expanded(
                    child: Column(
                      children: [
                        // APP BAR PERSONALIZADO
                        Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _titles[_currentIndex] ?? 'Gym Manager',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  _buildInfoBar(context, authState),
                                  const SizedBox(width: 20),
                                  IconButton(
                                    icon: ValueListenableBuilder<ThemeMode>(
                                      valueListenable: GymConfigService().themeModeNotifier,
                                      builder: (context, mode, _) {
                                        return Icon(
                                          mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                                        );
                                      },
                                    ),
                                    onPressed: () {
                                      GymConfigService().toggleTheme();
                                    },
                                    tooltip: 'Cambiar tema',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: () {
                                      if (_currentIndex == 1) {
                                        _actualizarListaSocios(context);
                                      } else if (_currentIndex == 0) {
                                        setState(() => _dashboardRefreshKey++);
                                      }
                                    },
                                    tooltip: 'Actualizar',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.notifications),
                                    onPressed: () => _verificarNotificaciones(context),
                                    tooltip: 'Verificar recordatorios',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // CUERPO DE LA PANTALLA
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            child: _buildBody(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    // Usamos un switch para devolver el widget correspondiente
    // Nota: No usamos IndexedStack para las pantallas pesadas para ahorrar recursos,
    // pero sí mantenemos el estado de algunas si es necesario.
    switch (_currentIndex) {
      case 0: return DashboardScreen(key: ValueKey<int>(_dashboardRefreshKey));
      case 1: return const ListaSociosScreen();
      case 2: return const RegistroAsistenciaScreen();
      case 3: return const PlanesListScreen();
      case 4: return const ListaEjerciciosScreen();
      case 5: return const ListaRutinasScreen();
      case 6: return const ConfiguracionGeneralScreen();
      case 7: return const ConfiguracionEmailScreen();
      case 8: return const ConfiguracionRecordatoriosScreen();
      case 9: return GestionUsuariosScreen();
      case 10: return AprobacionSociosScreen();
      case 11: return const EstadisticasAsistenciaScreen();
      case 12: return const HistorialAsistenciaScreen();
      case 13: return const AuditoriaScreen();
      case 14: return const ListaSociosInactivosScreen();
      default: return const Center(child: Text('Pantalla no encontrada'));
    }
  }

  void _verificarNotificaciones(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('🔔 Verificando recordatorios pendientes...')),
    );

    try {
      final sociosBloc = context.read<SociosBloc>();
      final sociosState = sociosBloc.state;
      
      if (sociosState is SociosCargadosState) {
        final resultados = await NotificacionService.enviarNotificacionesAutomaticas(sociosState.sociosFiltrados);
        final exitosas = resultados.where((r) => r['exitoso'] == true).length;
        
        messenger.showSnackBar(
          SnackBar(
            content: Text('✅ $exitosas notificaciones enviadas automáticamente'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('ℹ️ No hay socios cargados para notificar'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Error enviando notificaciones: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _actualizarListaSocios(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔄 Actualizando lista de socios...')),
    );
    context.read<SociosBloc>().add(CargarSociosEvent());
  }

  Widget _buildInfoBar(BuildContext context, AuthState authState) {
    String nombre = '';
    String rol = '';
    if (authState is AuthSuccess) {
      final usuario = authState.usuario;
      if (usuario != null) {
        nombre = usuario.nombre;
        rol = usuario.rol;
      }
    } else if (authState is AuthAuthenticatedState) {
      final user = authState.user;
      if (user is Map) {
        nombre = (user['nombreCompleto'] ?? user['nombre'] ?? '').toString();
        rol = (user['rol'] ?? '').toString();
      }
    }
    final fechaHora = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$nombre ($rol)',
          style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        Text(
          fechaHora,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}