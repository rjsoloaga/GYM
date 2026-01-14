import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/blocs/auth_bloc.dart';
import 'package:gym/pages/dashboard_screen.dart';
import 'package:gym/pages/lista_socios_screen.dart';
import 'package:gym/widgets/date_time_display.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  
  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const DashboardScreen(), // Dashboard primero (índice 0)
    const ListaSociosScreen(), // Socios segundo (índice 1)
  ];

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
              // El AuthWrapper manejará la navegación automáticamente
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF40E0D0)),
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) {
                _volverAMenu(context);
              }
            },
            child: Scaffold(
              body: _screens[_currentIndex],
              bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
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
                backgroundColor: const Color(0xFF0A0A0A),
                selectedItemColor: const Color(0xFF40E0D0),
                unselectedItemColor: Colors.grey.shade600,
                type: BottomNavigationBarType.fixed,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_outlined),
                    activeIcon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people_outline),
                    activeIcon: Icon(Icons.people),
                    label: 'Socios',
                  ),
                ],
              ),
            ),
            appBar: AppBar(
              toolbarHeight: 80, // Aumentar altura del AppBar
              title: _currentIndex == 0
                  ? Row(
                      children: [
                        Text(authState.rol == 'admin' ? 'Administrador' : authState.nombre),
                        const Spacer(),
                        DateTimeDisplay(
                          showDate: true, // Mostrar fecha y hora
                          showTime: true,
                          textStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        // Logo Lobo 2 - más grande
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF40E0D0).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'lobo2.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Título
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'LOBO',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                authState.rol == 'admin' ? 'Administrador' : authState.nombre,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        DateTimeDisplay(
                          showDate: true, // Mostrar fecha y hora
                          showTime: true,
                          textStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
              elevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF000000), Color(0xFF1A0000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF40E0D0).withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              actions: [
                // Botón para volver al menú principal
                IconButton(
                  icon: const Icon(Icons.home),
                  onPressed: () => _volverAMenu(context),
                  tooltip: 'Volver al menú principal',
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _logout(context),
                  tooltip: 'Cerrar sesión',
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  void _volverAMenu(BuildContext context) {
    Navigator.pop(context);
  }
}
