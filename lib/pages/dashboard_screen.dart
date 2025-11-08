import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gym/repositories/database_helper.dart';
import 'package:gym/models/socio.dart';
import 'package:gym/widgets/estado_cuotas_chart.dart';
import 'package:gym/pages/socios_filtrados_screen.dart';
import 'package:gym/pages/main_navigation_screen.dart';
import 'package:gym/pages/ingresos_chart_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _estadisticasFuture;
  bool _mostrarGraficoCuotas = false;

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

    final sociosAlDia = socios.where((socio) {
      final dias = socio.fechaVencimiento.difference(ahora).inDays;
      return dias > 7; // Más de 7 días restantes
    }).toList();

    return {
      'totalSocios': socios.length,
      'ingresosMensuales': ingresosMensuales,
      'ingresosDiarios': ingresosDiarios,
      'cuotasVencidas': cuotasVencidas,
      'cuotasPorVencer': cuotasPorVencer,
      'sociosPorVencer': sociosPorVencer,
      'sociosVencidos': sociosVencidos,
      'sociosAlDia': sociosAlDia,
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

                  return StatefulBuilder(
                    builder: (context, setStateLocal) {
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
                                  context,
                                  'Total Socios',
                                  stats['totalSocios'].toString(),
                                  Icons.people_outline,
                                  const Color(0xFF40E0D0),
                                  onTap: () => _navegarATodosLosSocios(context),
                                  isMobile: isMobile,
                                ),
                                const SizedBox(height: 12),
                                _buildMetricCard(
                                  context,
                                  'Ingresos Diarios',
                                  '\$${_formatNumber(stats['ingresosDiarios'] as double)}',
                                  Icons.today,
                                  const Color(0xFF30D5C8),
                                  onTap: () => _navegarAGraficoIngresos(context, true),
                                  isMobile: isMobile,
                                ),
                                const SizedBox(height: 12),
                                _buildMetricCard(
                                  context,
                                  'Ingresos Mensuales',
                                  '\$${_formatNumber(stats['ingresosMensuales'] as double)}',
                                  Icons.trending_up,
                                  const Color(0xFF4CAF50),
                                  onTap: () => _navegarAGraficoIngresos(context, false),
                                  isMobile: isMobile,
                                ),
                                const SizedBox(height: 12),
                                _buildMetricCard(
                                  context,
                                  'Cuotas Vencidas',
                                  stats['cuotasVencidas'].toString(),
                                  Icons.error_outline,
                                  Colors.red,
                                  onTap: () => _navegarASociosFiltrados(
                                    context,
                                    stats['sociosVencidos'] as List<Socio>,
                                    'Socios con Cuotas Vencidas',
                                    Colors.red,
                                  ),
                                  isMobile: isMobile,
                                ),
                                const SizedBox(height: 12),
                                _buildMetricCard(
                                  context,
                                  'Por Vencer (7 días)',
                                  stats['cuotasPorVencer'].toString(),
                                  Icons.warning_amber_rounded,
                                  Colors.amber,
                                  onTap: () => _navegarASociosFiltrados(
                                    context,
                                    stats['sociosPorVencer'] as List<Socio>,
                                    'Socios por Vencer (7 días)',
                                    Colors.amber,
                                  ),
                                  isMobile: isMobile,
                                ),
                                const SizedBox(height: 12),
                                // Estado de Cuotas en móvil
                                _buildCardEstadoCuotasCompacta(
                                  context,
                                  stats['distribucionCuotas'] as Map<String, int>,
                                  isMobile: isMobile,
                                  onTap: () {
                                    setStateLocal(() {
                                      _mostrarGraficoCuotas = !_mostrarGraficoCuotas;
                                    });
                                  },
                                  mostrarGrafico: _mostrarGraficoCuotas,
                                  sociosAlDia: stats['sociosAlDia'] as List<Socio>,
                                  sociosPorVencer: stats['sociosPorVencer'] as List<Socio>,
                                  sociosVencidos: stats['sociosVencidos'] as List<Socio>,
                                ),
                              ] else ...[
                                // Layout horizontal para tablet/desktop (2x2)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricCard(
                                        context,
                                        'Total Socios',
                                        stats['totalSocios'].toString(),
                                        Icons.people_outline,
                                        const Color(0xFF40E0D0),
                                        onTap: () => _navegarATodosLosSocios(context),
                                        isMobile: isMobile,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildMetricCard(
                                        context,
                                        'Ingresos Diarios',
                                        '\$${_formatNumber(stats['ingresosDiarios'] as double)}',
                                        Icons.today,
                                        const Color(0xFF30D5C8),
                                        onTap: () => _navegarAGraficoIngresos(context, true),
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
                                        context,
                                        'Ingresos Mensuales',
                                        '\$${_formatNumber(stats['ingresosMensuales'] as double)}',
                                        Icons.trending_up,
                                        const Color(0xFF4CAF50),
                                        onTap: () => _navegarAGraficoIngresos(context, false),
                                        isMobile: isMobile,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildMetricCard(
                                        context,
                                        'Cuotas Vencidas',
                                        stats['cuotasVencidas'].toString(),
                                        Icons.error_outline,
                                        Colors.red,
                                        onTap: () => _navegarASociosFiltrados(
                                          context,
                                          stats['sociosVencidos'] as List<Socio>,
                                          'Socios con Cuotas Vencidas',
                                          Colors.red,
                                        ),
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
                                        context,
                                        'Por Vencer (7 días)',
                                        stats['cuotasPorVencer'].toString(),
                                        Icons.warning_amber_rounded,
                                        Colors.amber,
                                        onTap: () => _navegarASociosFiltrados(
                                          context,
                                          stats['sociosPorVencer'] as List<Socio>,
                                          'Socios por Vencer (7 días)',
                                          Colors.amber,
                                        ),
                                        isMobile: isMobile,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Estado de Cuotas en el espacio disponible
                                    Expanded(
                                      child: _buildCardEstadoCuotasCompacta(
                                        context,
                                        stats['distribucionCuotas'] as Map<String, int>,
                                        isMobile: isMobile,
                                        onTap: () {
                                          setStateLocal(() {
                                            _mostrarGraficoCuotas = !_mostrarGraficoCuotas;
                                          });
                                        },
                                        mostrarGrafico: _mostrarGraficoCuotas,
                                        sociosAlDia: stats['sociosAlDia'] as List<Socio>,
                                        sociosPorVencer: stats['sociosPorVencer'] as List<Socio>,
                                        sociosVencidos: stats['sociosVencidos'] as List<Socio>,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              SizedBox(height: isMobile ? 24 : 32),

                              // Gráfico expandido (mostrado solo si se hizo clic en la tarjeta compacta)
                              if (_mostrarGraficoCuotas) ...[
                                SizedBox(height: isMobile ? 16 : 20),
                                _buildGraficoExpandido(
                                  stats['distribucionCuotas'] as Map<String, int>,
                                  sociosAlDia: stats['sociosAlDia'] as List<Socio>,
                                  sociosPorVencer: stats['sociosPorVencer'] as List<Socio>,
                                  sociosVencidos: stats['sociosVencidos'] as List<Socio>,
                                  isMobile: isMobile,
                                ),
                                SizedBox(height: isMobile ? 24 : 32),
                              ],

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
    BuildContext context,
    String titulo,
    String valor,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
    bool isMobile = false,
  }) {
    final padding = isMobile ? 16.0 : 20.0;
    final iconSize = isMobile ? 22.0 : 26.0;
    final valueFontSize = isMobile ? 28.0 : 32.0;
    final titleFontSize = isMobile ? 12.0 : 13.0;
    final iconPadding = isMobile ? 8.0 : 10.0;
    
    Widget cardContent = Container(
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
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: color.withValues(alpha: 0.7),
                ),
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

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: cardContent,
      );
    }

    return cardContent;
  }

  void _navegarATodosLosSocios(BuildContext context) {
    // Navegar a la pestaña de Socios en MainNavigationScreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MainNavigationScreen(initialIndex: 1),
      ),
    );
  }

  void _navegarASociosFiltrados(
    BuildContext context,
    List<Socio> socios,
    String titulo,
    Color color,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SociosFiltradosScreen(
          socios: socios,
          titulo: titulo,
          color: color,
        ),
      ),
    );
  }

  void _navegarAGraficoIngresos(BuildContext context, bool esDiario) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IngresosChartScreen(
          esDiario: esDiario,
        ),
      ),
    );
  }

  Widget _buildCardEstadoCuotasCompacta(
    BuildContext context,
    Map<String, int> distribucionCuotas, {
    required bool isMobile,
    required VoidCallback onTap,
    required bool mostrarGrafico,
    required List<Socio> sociosAlDia,
    required List<Socio> sociosPorVencer,
    required List<Socio> sociosVencidos,
  }) {
    final alDia = distribucionCuotas['alDia'] ?? 0;
    final porVencer = distribucionCuotas['porVencer'] ?? 0;
    final vencidas = distribucionCuotas['vencidas'] ?? 0;
    final total = alDia + porVencer + vencidas;
    // Variables calculadas pero no usadas (comentadas para evitar warnings)
    // final alDiaPorcentaje = total > 0 ? (alDia / total * 100) : 0;
    // final porVencerPorcentaje = total > 0 ? (porVencer / total * 100) : 0;
    // final vencidasPorcentaje = total > 0 ? (vencidas / total * 100) : 0;

    final padding = isMobile ? 16.0 : 20.0;
    final iconSize = isMobile ? 22.0 : 26.0;
    final valueFontSize = isMobile ? 28.0 : 32.0;
    final titleFontSize = isMobile ? 12.0 : 13.0;
    final iconPadding = isMobile ? 8.0 : 10.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
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
                        const Color(0xFF4CAF50).withValues(alpha: 0.3),
                        const Color(0xFF4CAF50).withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.pie_chart,
                    color: const Color(0xFF4CAF50),
                    size: iconSize,
                  ),
                ),
                const Spacer(),
                Icon(
                  mostrarGrafico ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF4CAF50),
                  size: 20,
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              total.toString(),
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4CAF50),
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 4 : 6),
            Text(
              'Estado de Cuotas',
              style: TextStyle(
                fontSize: titleFontSize,
                color: Colors.grey.shade300,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: isMobile ? 8 : 10),
            // Mini resumen
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniIndicador('Al Día', alDia, Colors.green, isMobile),
                _buildMiniIndicador('Por Vencer', porVencer, Colors.amber, isMobile),
                _buildMiniIndicador('Vencidas', vencidas, Colors.red, isMobile),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniIndicador(String label, int valor, Color color, bool isMobile) {
    return Column(
      children: [
        Container(
          width: isMobile ? 8 : 10,
          height: isMobile ? 8 : 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(height: isMobile ? 2 : 4),
        Text(
          valor.toString(),
          style: TextStyle(
            color: color,
            fontSize: isMobile ? 10 : 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGraficoExpandido(
    Map<String, int> distribucionCuotas, {
    required bool isMobile,
    required List<Socio> sociosAlDia,
    required List<Socio> sociosPorVencer,
    required List<Socio> sociosVencidos,
  }) {
    // if (kDebugMode) {
    //   print('📊 Construyendo gráfico expandido. Datos: $distribucionCuotas');
    // }
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF40E0D0).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gráfico de Estado de Cuotas',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          EstadoCuotasChart(
            datos: distribucionCuotas,
            sociosAlDia: sociosAlDia,
            sociosPorVencer: sociosPorVencer,
            sociosVencidos: sociosVencidos,
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
