import 'package:flutter/material.dart';
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


class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 1;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

          // LISTA DE PANTALLAS CON SUS PROPIO SCAFFOLD
          final List<Widget> _screens = [
            // Pantalla de Socios
            Scaffold(
              appBar: AppBar(
                title: const Text('Socios'),
                backgroundColor: const Color(0xFF0D1B2A),
                leading: IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      _actualizarListaSocios(context);
                    },
                    tooltip: 'Actualizar lista',
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      _verificarNotificaciones(context);
                    },
                    tooltip: 'Verificar recordatorios',
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => _logout(context),
                    tooltip: 'Cerrar sesión',
                  ),
                ],
              ),
              body: const ListaSociosScreen(),
            ),
            // Pantalla de Dashboard  
            Scaffold(
              appBar: AppBar(
                title: const Text('Dashboard'),
                backgroundColor: const Color(0xFF0D1B2A),
                leading: IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      _procesarRegistrosTelegram(context);
                    },
                    tooltip: 'Actualizar registros Telegram',
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      _verificarNotificaciones(context);
                    },
                    tooltip: 'Verificar recordatorios',
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => _logout(context),
                    tooltip: 'Cerrar sesión',
                  ),
                ],
              ),
              body: const DashboardScreen(),
            ),
          ];

          return Scaffold(
            key: _scaffoldKey,
            drawer: _buildDrawer(context),
            body: _screens[_currentIndex],
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(255,255,255,0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                backgroundColor: const Color(0xFF1E1E1E),
                selectedItemColor: const Color(0xFF2196F3),
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people),
                    label: 'Socios',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // MÉTODOS PARA CONECTAR CON LAS FUNCIONALIDADES REALES
  void _procesarRegistrosTelegram(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    
    messenger.showSnackBar(
      const SnackBar(content: Text('🔄 Procesando registros de Telegram...')),
    );

    try {
      await ChatIdRegistroService.procesarNuevosChatIds();
      
      final stats = await ChatIdRegistroService.obtenerEstadisticasRegistros();
      
      messenger.showSnackBar(
        SnackBar(
          content: Text('✅ ${stats['registrados']}/${stats['total']} socios registrados en Telegram'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Error procesando registros: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.fitness_center, size: 40, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'GYM MANAGER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Sistema de Gestión',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // ITEM NUEVO: Aprobación de Socios con badge
          StreamBuilder<List<Socio>>(
            stream: _sociosPendientesStream(),
            builder: (context, snapshot) {
              final countPendientes = snapshot.data?.length ?? 0;
              
              return ListTile(
                leading: Stack(
                  children: [
                    Icon(Icons.person_add, color: Colors.orange),
                    if (countPendientes > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            countPendientes.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text('Aprobación de Socios'),
                subtitle: Text('Registros por Telegram'),
                trailing: countPendientes > 0 
                    ? Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$countPendientes pendiente${countPendientes > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/aprobacion-socios');
                },
              );
            },
          ),
          
          // ITEM EXISTENTE: Gestión de Socios
          ListTile(
            leading: Icon(Icons.people, color: Colors.blue),
            title: Text('Gestión de Socios'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 0; // Navegar a pantalla de Socios
              });
            },
          ),
          
          // ITEM EXISTENTE: Dashboard
          ListTile(
            leading: Icon(Icons.dashboard, color: Colors.green),
            title: Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 1; // Navegar a pantalla de Dashboard
              });
            },
          ),
          
          // ITEM NUEVO: Gestión de Usuarios (solo para admin)
          ListTile(
            leading: Icon(Icons.admin_panel_settings, color: Colors.red),
            title: Text('Gestión de Usuarios'),
            subtitle: Text('Roles y permisos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/gestion-usuarios');
            },
          ),
          
          Divider(),
          
          // ITEM EXISTENTE: Cerrar Sesión
          ListTile(
            leading: Icon(Icons.logout, color: Colors.grey),
            title: Text('Cerrar Sesión'),
            onTap: () {
              context.read<AuthBloc>().add(LogoutEvent());
            },
          ),
        ],
      ),
    );
  }
  
}