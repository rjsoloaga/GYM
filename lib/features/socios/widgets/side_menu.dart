import 'package:flutter/material.dart';
import 'package:gym/services/gym_config_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SideMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isAdmin;
  final int pendientesCount;
  final int alertasCount;

  const SideMenu({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isAdmin,
    this.pendientesCount = 0,
    this.alertasCount = 0,
  });

  void _mostrarAcercaDe(BuildContext context) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
            const SizedBox(width: 10),
            const Text('Acerca de'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GYM MANAGEMENT SYSTEM',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('Versión: $version (Build $buildNumber)'),
            const SizedBox(height: 16),
            const Text(
              'Desarrollado por:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('Tu Empresa de Software'),
            const SizedBox(height: 8),
            const Text('Contacto: contacto@tuempresa.com'),
            const SizedBox(height: 8),
            const Text(
              '© 2025 Todos los derechos reservados.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final dividerColor = isDark ? Colors.white24 : Colors.black12;
    final iconColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: isDark ? null : Border(right: BorderSide(color: Colors.grey.shade300)),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context, isDark, textColor),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                  _buildSectionHeader('GIMNASIO', subTextColor),
                  _buildMenuItem(
                    icon: Icons.dashboard,
                    title: 'Gym Manager',
                    index: 0,
                    textColor: textColor,
                    iconColor: iconColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.people,
                    title: 'Socios',
                    index: 1,
                    textColor: textColor,
                    iconColor: iconColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.login,
                    title: 'Asistencia',
                    index: 2,
                    subtitle: 'Registro de ingreso',
                    textColor: textColor,
                    iconColor: iconColor,
                    subTextColor: subTextColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.assignment,
                    title: 'Planes',
                    index: 3,
                    textColor: textColor,
                    iconColor: iconColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.fitness_center,
                    title: 'Ejercicios',
                    index: 4,
                    textColor: textColor,
                    iconColor: iconColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.list_alt,
                    title: 'Rutinas',
                    index: 5,
                    textColor: textColor,
                    iconColor: iconColor,
                  ),
                  
                  const SizedBox(height: 16),
                  Divider(color: dividerColor, height: 1),
                  const SizedBox(height: 16),
                  
                  _buildSectionHeader('COMERCIO', subTextColor),
                  _buildMenuItem(
                    icon: Icons.dashboard,
                    title: 'Dashboard Ventas',
                    index: 25,
                    textColor: textColor,
                    iconColor: iconColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.point_of_sale,
                    title: 'Punto de Venta',
                    index: 23,
                    textColor: textColor,
                    iconColor: iconColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.receipt_long,
                    title: 'Historial Ventas',
                    index: 24,
                    textColor: textColor,
                    iconColor: iconColor,
                  ),
                  
                  // Grupo Inventario
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: [17, 18, 19, 20, 21, 22].contains(selectedIndex),
                      leading: Icon(Icons.inventory_2, color: iconColor),
                      title: Text('Inventario', style: TextStyle(color: textColor)),
                      children: [
                        _buildSubMenuItem(
                          title: 'Productos',
                          index: 17,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        _buildSubMenuItem(
                          title: 'Categorías',
                          index: 18,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        _buildSubMenuItem(
                          title: 'Proveedores',
                          index: 19,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        _buildSubMenuItem(
                          title: 'Alertas',
                          index: 20,
                          badgeCount: alertasCount,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        _buildSubMenuItem(
                          title: 'Movimientos',
                          index: 21,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        _buildSubMenuItem(
                          title: 'Reportes',
                          index: 22,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                      ],
                    ),
                  ),
                  
                  if (isAdmin) ...[
                    const SizedBox(height: 10),
                    _buildSectionHeader('ADMINISTRACIÓN', subTextColor),
                  
                  // Grupo Configuración
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: [6, 7, 8, 9, 15, 16].contains(selectedIndex),
                      leading: Icon(Icons.settings, color: iconColor),
                      title: Text('Configuración', style: TextStyle(color: textColor)),
                      children: [
                        _buildSubMenuItem(
                          title: 'General',
                          index: 6,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        _buildSubMenuItem(
                          title: 'Email',
                          index: 7,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        _buildSubMenuItem(
                          title: 'Recordatorios',
                          index: 8,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        _buildSubMenuItem(
                          title: 'Usuarios',
                          index: 9,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        _buildSubMenuItem(
                          title: 'Copias de Seguridad',
                          index: 15,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        _buildSubMenuItem(
                          title: 'Licencia',
                          index: 16,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                      ],
                    ),
                  ),

                  // Grupo Reportes y Auditoría
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: [10, 11, 12, 13].contains(selectedIndex),
                      leading: Icon(Icons.analytics, color: iconColor),
                      title: Text('Reportes y Control', style: TextStyle(color: textColor)),
                      children: [
                         _buildSubMenuItem(
                          title: 'Aprobación Socios',
                          index: 10,
                          badgeCount: pendientesCount,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        _buildSubMenuItem(
                          title: 'Estadísticas Asistencia',
                          index: 11,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        _buildSubMenuItem(
                          title: 'Historial Asistencia',
                          index: 12,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        _buildSubMenuItem(
                          title: 'Auditoría',
                          index: 13,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                         _buildSubMenuItem(
                          title: 'Socios Inactivos',
                          index: 14,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(color: dividerColor),
          ListTile(
            leading: Icon(Icons.info_outline, color: iconColor),
            title: Text('Acerca de', style: TextStyle(color: subTextColor)),
            onTap: () => _mostrarAcercaDe(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text('Cerrar Sesión', style: TextStyle(color: subTextColor)),
            onTap: () => onItemSelected(-1), // -1 para logout
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color textColor) {
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
                style: TextStyle(
                  color: textColor,
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

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: color.withOpacity(0.5),
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
    required Color textColor,
    required Color iconColor,
    Color? subTextColor,
  }) {
    final isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon, 
          color: isSelected ? Colors.blue : iconColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.blue : textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 11, color: subTextColor ?? iconColor)) : null,
        onTap: () => onItemSelected(index),
        selected: isSelected,
      ),
    );
  }

  Widget _buildSubMenuItem({
    required String title,
    required int index,
    int badgeCount = 0,
    required Color textColor,
    required Color subTextColor,
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
                  color: isSelected ? Colors.blue : subTextColor,
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
