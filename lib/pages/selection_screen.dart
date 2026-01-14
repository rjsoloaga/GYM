import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/blocs/auth_bloc.dart';
import 'package:gym/pages/main_navigation_screen.dart';

class SelectionScreen extends StatelessWidget {
  const SelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticatedState) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF000000),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Lobo 2 centrado
                      Container(
                        width: 180,
                        height: 180,
                        margin: const EdgeInsets.only(bottom: 40),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF40E0D0).withValues(alpha: 0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'lobo2.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Título de bienvenida con nombre
                      Text(
                        'Bienvenido, ${authState.nombre}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Selecciona una sección para comenzar',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 60),
                      // Botón Dashboard
                      _buildSelectionCard(
                        context: context,
                        title: 'Dashboard',
                        description: 'Estadísticas y resumen del gimnasio',
                        icon: Icons.dashboard_rounded,
                        color: const Color(0xFF40E0D0),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MainNavigationScreen(initialIndex: 0),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Botón Socios
                      _buildSelectionCard(
                        context: context,
                        title: 'Socios',
                        description: 'Gestiona los miembros del gimnasio',
                        icon: Icons.people_rounded,
                        color: const Color(0xFF30D5C8),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MainNavigationScreen(initialIndex: 1),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                      // Botón de cerrar sesión
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF1E1E1E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
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
                                  child: const Text(
                                    'Cancelar',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    context.read<AuthBloc>().add(LogoutEvent());
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF40E0D0),
                                  ),
                                  child: const Text(
                                    'Cerrar Sesión',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text(
                          'Cerrar Sesión',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                // Icono
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: color,
                  ),
                ),
                const SizedBox(width: 20),
                // Título y descripción
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Flecha
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

