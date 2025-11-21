import 'package:flutter/material.dart';
import 'package:gym/services/gym_config_service.dart';

class SideMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isAdmin;
  final int pendientesCount;

  const SideMenu({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isAdmin,
    this.pendientesCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  index: 0,
                ),
                _buildMenuItem(
                  icon: Icons.people,
                  title: 'Socios',
                  index: 1,
                ),
                _buildMenuItem(
                  icon: Icons.login,
                  title: 'Asistencia',
                  index: 2,
                  subtitle: 'Registro de ingreso',
                ),
                
                if (isAdmin) ...[
                  const Divider(color: Colors.white24, height: 30),
                  _buildSectionHeader('GESTIÓN'),
                  _buildMenuItem(
                    icon: Icons.assignment,
                    title: 'Planes',
                    index: 3,
                  ),
                  _buildMenuItem(
                    icon: Icons.fitness_center,
                    title: 'Ejercicios',
                    index: 4,
                  ),
                  _buildMenuItem(
                    icon: Icons.list_alt,
                    title: 'Rutinas',
                    index: 5,
                  ),
                  
                  const SizedBox(height: 10),
                  _buildSectionHeader('ADMINISTRACIÓN'),
                  
                  // Grupo Configuración
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: [6, 7, 8, 9, 10, 11, 12].contains(selectedIndex),
                      leading: const Icon(Icons.settings, color: Colors.white70),
                      title: const Text('Configuración', style: TextStyle(color: Colors.white)),
                      children: [
                        _buildSubMenuItem(
                          title: 'General',
                          index: 6,
                        ),
                        _buildSubMenuItem(
                          title: 'Email',
                          index: 7,
                        ),
                        _buildSubMenuItem(
                          title: 'Recordatorios',
                          index: 8,
                        ),
                        _buildSubMenuItem(
                          title: 'Usuarios',
                          index: 9,
                        ),
                      ],
                    ),
                  ),

                  // Grupo Reportes y Auditoría
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: [10, 11, 12, 13].contains(selectedIndex),
                      leading: const Icon(Icons.analytics, color: Colors.white70),
                      title: const Text('Reportes y Control', style: TextStyle(color: Colors.white)),
                      children: [
                         _buildSubMenuItem(
                          title: 'Aprobación Socios',
                          index: 10,
                          badgeCount: pendientesCount,
                        ),
                        _buildSubMenuItem(
                          title: 'Estadísticas Asistencia',
                          index: 11,
                        ),
                        _buildSubMenuItem(
                          title: 'Historial Asistencia',
                          index: 12,
                        ),
                        _buildSubMenuItem(
                          title: 'Auditoría',
                          index: 13,
                        ),
                         _buildSubMenuItem(
                          title: 'Socios Inactivos',
                          index: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white70)),
            onTap: () => onItemSelected(-1), // -1 para logout
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Column(
        children: [
          const Icon(Icons.fitness_center, size: 40, color: Colors.blue),
          const SizedBox(height: 10),
          ValueListenableBuilder<String>(
            valueListenable: GymConfigService().nombreGymNotifier,
            builder: (context, nombreGym, child) {
              return Text(
                nombreGym,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required int index,
    String? subtitle,
  }) {
    final isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon, 
          color: isSelected ? Colors.blue : Colors.white70,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white38)) : null,
        onTap: () => onItemSelected(index),
        selected: isSelected,
      ),
    );
  }

  Widget _buildSubMenuItem({
    required String title,
    required int index,
    int badgeCount = 0,
  }) {
    final isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10, bottom: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 50, right: 10),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        onTap: () => onItemSelected(index),
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
