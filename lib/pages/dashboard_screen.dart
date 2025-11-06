import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gym/repositories/database_helper.dart';
import 'package:gym/models/socio.dart';

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
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Row(
                    children: [
                      const Icon(Icons.dashboard, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _cargarEstadisticas,
                        tooltip: 'Actualizar',
                      ),
                    ],
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
                                  Icons.people,
                                  const Color(0xFF2196F3),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  'Ingresos Mensuales',
                                  '\$${_formatNumber(stats['ingresosMensuales'] as double)}',
                                  Icons.attach_money,
                                  const Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  'Cuotas Vencidas',
                                  stats['cuotasVencidas'].toString(),
                                  Icons.error,
                                  const Color(0xFFCF6679),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  'Por Vencer (7 días)',
                                  stats['cuotasPorVencer'].toString(),
                                  Icons.warning,
                                  Colors.amber,
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
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A3A3A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
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
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
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
              color: const Color(0xFFCF6679).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCF6679).withOpacity(0.3)),
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
