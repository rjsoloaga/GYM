import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/features/socios/bloc/socios_bloc.dart';
import 'package:gym/core/database/database_helper.dart';
import 'package:gym/features/socios/models/socio.dart';
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
    _cargarEstadisticas();
  }

  void _cargarEstadisticas() {
    setState(() {
      _estadisticasFuture = _obtenerEstadisticas();
    });
  }

  Future<Map<String, dynamic>> _obtenerEstadisticas() async {
    final socios = await DatabaseHelper.instance.getSocios();
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final ingresosDiarios = await DatabaseHelper.instance.getIngresosDiarios(ahora);
    final cuotasVencidas = await DatabaseHelper.instance.getCuotasVencidas();
    final cuotasPorVencer = await DatabaseHelper.instance.getCuotasPorVencer();
    final sociosPorVencer = socios.where((socio) {
      final v = DateTime(socio.fechaVencimiento.year, socio.fechaVencimiento.month, socio.fechaVencimiento.day);
      final dias = v.difference(hoy).inDays;
      return dias >= 0 && dias <= 7; // incluye HOY
    }).toList();

    final sociosVencidos = socios.where((socio) {
      final v = DateTime(socio.fechaVencimiento.year, socio.fechaVencimiento.month, socio.fechaVencimiento.day);
      final dias = v.difference(hoy).inDays;
      return dias < 0; // excluye HOY
    }).toList();

    return {
      'totalSocios': socios.length,
      'ingresos_diarios': ingresosDiarios, // clave esperada por la UI
      'fecha_actual': ahora,
      // mantenemos compatibilidad si en otro lugar se usa la antigua
      'ingresosMensuales': ingresosDiarios,
      'cuotasVencidas': cuotasVencidas,
      'cuotasPorVencer': cuotasPorVencer,
      'sociosPorVencer': sociosPorVencer,
      'sociosVencidos': sociosVencidos,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null, // Remover AppBar aquí porque lo maneja MainNavigationScreen
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => _cargarEstadisticas(),
            color: const Color(0xFF2196F3),
            child: BlocBuilder<SociosBloc, SociosState>(
              builder: (context, sociosState) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      FutureBuilder<Map<String, dynamic>>(
                        future: _estadisticasFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.red)),
                            );
                          }

                          final stats = snapshot.data ?? {};
                          final vencidas = stats['vencidas'] ?? 0;
                          final por_vencer = stats['por_vencer'] ?? 0;
                          final al_dia = stats['al_dia'] ?? 0;
                          final ingresos = (stats['ingresos_diarios'] ?? 0.0) as double;
                          final fecha = stats['fecha_actual'] as DateTime?;
                          int total = stats['total'] ?? 0;
                          if (sociosState is SociosCargadosState) {
                            total = sociosState.todosLosSocios.length;
                          }

                          return Column(
                            children: [
                              // Grid de métricas
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const ListaSociosScreen(),
                                          ),
                                        );
                                      },
                                      child: _buildMetricCard(
                                        'Total Socios',
                                        total.toString(),
                                        Icons.people,
                                        const Color(0xFF2196F3),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const ResumenIngresosDiariosScreen(),
                                          ),
                                        );
                                      },
                                      child: _buildMetricCard(
                                        'Ingresos Diarios',
                                        '\$${_formatNumber(ingresos)}',
                                        Icons.attach_money,
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ListaSociosScreen(
                                              filtroVencidos: true,
                                            ),
                                          ),
                                        );
                                      },
                                      child: _buildMetricCard(
                                        'Cuotas Vencidas',
                                        vencidas.toString(),
                                        Icons.error,
                                        const Color(0xFFCF6679),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ListaSociosScreen(
                                              filtroPorVencer: true,
                                            ),
                                          ),
                                        );
                                      },
                                      child: _buildMetricCard(
                                        'Por Vencer (7 días)',
                                        por_vencer.toString(),
                                        Icons.warning,
                                        Colors.amber,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Recordatorios
                              if (stats['sociosPorVencer'].length > 0 ||
                                  stats['sociosVencidos'].length > 0)
                                _buildRecordatoriosSection(
                                  stats['sociosPorVencer'],
                                  stats['sociosVencidos'],
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String titulo, String valor, IconData icon, Color color) {
    // Determinar el tamaño de fuente basado en la longitud del valor
    double fontSize = 24.0;
    if (valor.length > 8) {
      fontSize = 20.0;
    } else if (valor.length > 12) {
      fontSize = 16.0;
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 140,
        maxHeight: 160,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (titulo == 'Ingresos Diarios') ...[
                  const SizedBox(height: 4),
                  Text(
                    'Hoy: '+DateFormat('dd/MM/yyyy').format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Se reinicia a las 00:00',
                    style: TextStyle(
                      fontSize: 9,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordatoriosSection(
      List<Socio> sociosPorVencer, List<Socio> sociosVencidos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recordatorios',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Cuotas por vencer
        if (sociosPorVencer.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // Reemplazado para evitar deprecacion de withOpacity
              color: const Color.fromRGBO(255, 255, 255, 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.3),),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      'Cuotas por vencer (${sociosPorVencer.length})',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...sociosPorVencer.map((socio) {
                  final ahora2 = DateTime.now();
                  final hoy2 = DateTime(ahora2.year, ahora2.month, ahora2.day);
                  final v = DateTime(socio.fechaVencimiento.year, socio.fechaVencimiento.month, socio.fechaVencimiento.day);
                  final dias = v.difference(hoy2).inDays;
                  final msg = dias == 0
                      ? 'Vence hoy'
                      : dias == 1
                          ? 'Vence mañana'
                          : 'Vence en $dias días';
                  return _buildRecordatorioItem(
                    socio,
                    Colors.amber,
                    msg,
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Cuotas vencidas
        if (sociosVencidos.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // Reemplazado para evitar deprecacion de withOpacity
              color: const Color.fromRGBO(255, 255, 255, 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.3),),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error, color: Color(0xFFCF6679)),
                    const SizedBox(width: 8),
                    Text(
                      'Cuotas vencidas (${sociosVencidos.length})',
                      style: const TextStyle(
                        color: Color(0xFFCF6679),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...sociosVencidos.take(5).map((socio) {
                  final ahora2 = DateTime.now();
                  final hoy2 = DateTime(ahora2.year, ahora2.month, ahora2.day);
                  final v = DateTime(socio.fechaVencimiento.year, socio.fechaVencimiento.month, socio.fechaVencimiento.day);
                  final dias = hoy2.difference(v).inDays;
                  return _buildRecordatorioItem(
                    socio,
                    const Color(0xFFCF6679),
                    'Vencida hace $dias días',
                  );
                }),
                if (sociosVencidos.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'y ${sociosVencidos.length - 5} más...',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecordatorioItem(Socio socio, Color color, String mensaje) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  socio.nombreCompleto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  mensaje,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('dd/MM/yyyy').format(socio.fechaVencimiento),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,##0.00', 'es_ES');
    return formatter.format(number);
  }
}