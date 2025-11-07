import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gym/repositories/database_helper.dart';
import 'package:gym/models/socio.dart';
import 'package:gym/widgets/gym_animated_background.dart';

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
    final ingresosMensuales = await DatabaseHelper.instance.getIngresosMensuales();
    final ingresosDiarios = await DatabaseHelper.instance.getIngresosDiarios();
    final cuotasVencidas = await DatabaseHelper.instance.getCuotasVencidas();
    final cuotasPorVencer = await DatabaseHelper.instance.getCuotasPorVencer(7);

    final ahora = DateTime.now();
    final sociosPorVencer = socios.where((socio) {
      final dias = socio.fechaVencimiento.difference(ahora).inDays;
      return dias >= 0 && dias <= 7;
    }).toList();

    final sociosVencidos = socios.where((socio) {
      return socio.fechaVencimiento.isBefore(ahora);
    }).toList();

    return {
      'totalSocios': socios.length,
      'ingresosMensuales': ingresosMensuales,
      'ingresosDiarios': ingresosDiarios,
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
      body: GymAnimatedBackground(
        particleCount: 15,
        showGrid: false,
        weightsOnly: true, // Solo mancuernas en el dashboard
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => _cargarEstadisticas(),
            color: const Color(0xFF40E0D0),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo Lobo 2 con más espacio
                  Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF40E0D0).withValues(alpha: 0.4),
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'lobo2.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  
                  // Botón de actualizar
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF40E0D0).withValues(alpha: 0.3),
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.refresh, color: Color(0xFF40E0D0)),
                        onPressed: _cargarEstadisticas,
                        tooltip: 'Actualizar',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tarjetas de métricas
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

                      final stats = snapshot.data!;

                      return Column(
                        children: [
                          // Grid de métricas
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  'Total Socios',
                                  stats['totalSocios'].toString(),
                                  Icons.people_outline,
                                  const Color(0xFF40E0D0),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  'Ingresos Diarios',
                                  '\$${_formatNumber(stats['ingresosDiarios'] as double)}',
                                  Icons.today,
                                  const Color(0xFF30D5C8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  'Ingresos Mensuales',
                                  '\$${_formatNumber(stats['ingresosMensuales'] as double)}',
                                  Icons.trending_up,
                                  const Color(0xFF4CAF50),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  'Cuotas Vencidas',
                                  stats['cuotasVencidas'].toString(),
                                  Icons.error_outline,
                                  const Color(0xFF40E0D0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  'Por Vencer (7 días)',
                                  stats['cuotasPorVencer'].toString(),
                                  Icons.warning_amber_rounded,
                                  const Color(0xFF30D5C8),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Espacio vacío para mantener el diseño
                              Expanded(child: Container()),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String titulo, String valor, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.3),
                      color.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            valor,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade300,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
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
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
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
                  final dias = socio.fechaVencimiento.difference(DateTime.now()).inDays;
                  return _buildRecordatorioItem(
                    socio,
                    Colors.amber,
                    'Vence en $dias días',
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
              color: const Color(0xFFCF6679).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCF6679).withValues(alpha: 0.3)),
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
                  final dias = DateTime.now().difference(socio.fechaVencimiento).inDays;
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
