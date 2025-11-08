import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gym/repositories/database_helper.dart';
import 'package:gym/models/socio.dart';
import 'package:gym/widgets/estado_cuotas_chart.dart';

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
    final distribucionCuotas = await DatabaseHelper.instance.getDistribucionEstadoCuotas();

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
      'distribucionCuotas': distribucionCuotas,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null, // Remover AppBar aquí porque lo maneja MainNavigationScreen
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF000000),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => _cargarEstadisticas(),
            color: const Color(0xFF40E0D0),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _estadisticasFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF40E0D0),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _cargarEstadisticas,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF40E0D0),
                            ),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }

                  final stats = snapshot.data!;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header con botón de actualizar (responsive)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Resumen General',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isMobile ? 20 : 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Container(
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
                                  iconSize: isMobile ? 20 : 24,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 16 : 24),

                          // Gráfico de Estado de Cuotas (PRIMERO - DESTACADO)
                          EstadoCuotasChart(
                            datos: stats['distribucionCuotas'] as Map<String, int>,
                          ),
                          SizedBox(height: isMobile ? 24 : 32),

                          // Sección de Métricas (Responsive)
                          Text(
                            'Métricas Principales',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isMobile ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: isMobile ? 12 : 16),
                          
                          // Grid responsive: 2 columnas en desktop, 1 en móvil
                          if (isMobile) ...[
                            // Layout vertical para móvil
                            _buildMetricCard(
                              'Total Socios',
                              stats['totalSocios'].toString(),
                              Icons.people_outline,
                              const Color(0xFF40E0D0),
                              isMobile: isMobile,
                            ),
                            const SizedBox(height: 12),
                            _buildMetricCard(
                              'Ingresos Diarios',
                              '\$${_formatNumber(stats['ingresosDiarios'] as double)}',
                              Icons.today,
                              const Color(0xFF30D5C8),
                              isMobile: isMobile,
                            ),
                            const SizedBox(height: 12),
                            _buildMetricCard(
                              'Ingresos Mensuales',
                              '\$${_formatNumber(stats['ingresosMensuales'] as double)}',
                              Icons.trending_up,
                              const Color(0xFF4CAF50),
                              isMobile: isMobile,
                            ),
                            const SizedBox(height: 12),
                            _buildMetricCard(
                              'Cuotas Vencidas',
                              stats['cuotasVencidas'].toString(),
                              Icons.error_outline,
                              Colors.red,
                              isMobile: isMobile,
                            ),
                            const SizedBox(height: 12),
                            _buildMetricCard(
                              'Por Vencer (7 días)',
                              stats['cuotasPorVencer'].toString(),
                              Icons.warning_amber_rounded,
                              Colors.amber,
                              isMobile: isMobile,
                            ),
                          ] else ...[
                            // Layout horizontal para tablet/desktop (2x2)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricCard(
                                    'Total Socios',
                                    stats['totalSocios'].toString(),
                                    Icons.people_outline,
                                    const Color(0xFF40E0D0),
                                    isMobile: isMobile,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildMetricCard(
                                    'Ingresos Diarios',
                                    '\$${_formatNumber(stats['ingresosDiarios'] as double)}',
                                    Icons.today,
                                    const Color(0xFF30D5C8),
                                    isMobile: isMobile,
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
                                    isMobile: isMobile,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildMetricCard(
                                    'Cuotas Vencidas',
                                    stats['cuotasVencidas'].toString(),
                                    Icons.error_outline,
                                    Colors.red,
                                    isMobile: isMobile,
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
                                    Colors.amber,
                                    isMobile: isMobile,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Espacio para mantener el diseño simétrico
                                Expanded(child: Container()),
                              ],
                            ),
                          ],
                          SizedBox(height: isMobile ? 24 : 32),

                          // Recordatorios
                          if (stats['sociosPorVencer'].length > 0 ||
                              stats['sociosVencidos'].length > 0)
                            _buildRecordatoriosSection(
                              stats['sociosPorVencer'],
                              stats['sociosVencidos'],
                              isMobile: isMobile,
                            ),
                          SizedBox(height: isMobile ? 16 : 24),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String titulo,
    String valor,
    IconData icon,
    Color color, {
    bool isMobile = false,
  }) {
    final padding = isMobile ? 16.0 : 20.0;
    final iconSize = isMobile ? 22.0 : 26.0;
    final valueFontSize = isMobile ? 28.0 : 32.0;
    final titleFontSize = isMobile ? 12.0 : 13.0;
    final iconPadding = isMobile ? 8.0 : 10.0;
    
    return Container(
      padding: EdgeInsets.all(padding),
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
                padding: EdgeInsets.all(iconPadding),
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
                child: Icon(icon, color: color, size: iconSize),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            valor,
            style: TextStyle(
              fontSize: valueFontSize,
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
          SizedBox(height: isMobile ? 4 : 6),
          Text(
            titulo,
            style: TextStyle(
              fontSize: titleFontSize,
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
    List<Socio> sociosPorVencer,
    List<Socio> sociosVencidos, {
    bool isMobile = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recordatorios',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isMobile ? 10 : 12),

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
