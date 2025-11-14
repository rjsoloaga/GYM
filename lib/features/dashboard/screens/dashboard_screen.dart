import 'package:flutter/material.dart';
import 'package:gym/core/database/database_helper.dart';
import 'package:gym/features/socios/screens/lista_socios_screen.dart';
import 'package:gym/features/dashboard/screens/resumen_ingresos_diarios_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _estadisticasFuture;

  @override
  void initState() {
    super.initState();
    _recargarEstadisticas();
  }

  void _recargarEstadisticas() {
    setState(() {
      _estadisticasFuture = _cargarEstadisticas();
    });
  }

  Future<Map<String, dynamic>> _cargarEstadisticas() async {
    try {
      final db = DatabaseHelper.instance;
      final now = DateTime.now();
      final socios = await db.getSocios();
      
      int vencidas = 0;
      int por_vencer = 0;
      int al_dia = 0;
      
      for (var socio in socios) {
        switch (socio.estadoCuota) {
          case 'Vencido':
            vencidas++;
            break;
          case 'Por Vencer':
            por_vencer++;
            break;
          case 'Al Día':
            al_dia++;
            break;
        }
      }
      
      final ingresos_diarios = await db.getIngresosDiarios(now);
      
      return {
        'vencidas': vencidas,
        'por_vencer': por_vencer,
        'al_dia': al_dia,
        'total': socios.length,
        'ingresos_diarios': ingresos_diarios,
        'fecha_actual': now,
      };
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  void _navigateWithFilter(String filter) {
    if (filter == 'pagos_del_dia') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ResumenIngresosDiariosScreen(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ListaSociosScreen(initialFilter: filter),
        ),
      );
    }
  }

  Widget _buildCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(value, textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _recargarEstadisticas),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _estadisticasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 60),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _recargarEstadisticas, child: const Text('Reintentar')),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Sin datos'));
          }

          final stats = snapshot.data ?? {};
          final vencidas = stats['vencidas'] ?? 0;
          final por_vencer = stats['por_vencer'] ?? 0;
          final al_dia = stats['al_dia'] ?? 0;
          final ingresos = (stats['ingresos_diarios'] ?? 0.0) as double;
          final fecha = stats['fecha_actual'] as DateTime?;
          final total = stats['total'] ?? 0;

          return RefreshIndicator(
            onRefresh: () async {
              _recargarEstadisticas();
              await _estadisticasFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estadísticas del Día', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 24),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.0,
                      children: [
                        _buildCard('Vencidas', vencidas.toString(), Icons.warning_amber_rounded, Colors.red, () => _navigateWithFilter('vencidos')),
                        _buildCard('Por Vencer', por_vencer.toString(), Icons.schedule, Colors.orange, () => _navigateWithFilter('por_vencer')),
                        _buildCard('Al Día', al_dia.toString(), Icons.check_circle, Colors.green, () => _navigateWithFilter('todos')),
                        _buildCard('Ingresos', '\$${ingresos.toStringAsFixed(0)}', Icons.attach_money, Colors.purple, () => _navigateWithFilter('pagos_del_dia')),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Resumen', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 16),
                            ListTile(leading: const Icon(Icons.group), title: const Text('Socios'), trailing: Text(total.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                            const Divider(),
                            ListTile(leading: const Icon(Icons.money), title: const Text('Ingresos Hoy'), trailing: Text('\$${ingresos.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700]))),
                            if (fecha != null) ...[
                              const SizedBox(height: 8),
                              Text('${fecha.day}/${fecha.month}/${fecha.year}', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}