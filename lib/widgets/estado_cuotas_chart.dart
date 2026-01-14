import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gym/models/socio.dart';
import 'package:gym/pages/socios_filtrados_screen.dart';

class EstadoCuotasChart extends StatefulWidget {
  final Map<String, int> datos;
  final List<Socio>? sociosAlDia;
  final List<Socio>? sociosPorVencer;
  final List<Socio>? sociosVencidos;

  const EstadoCuotasChart({
    super.key,
    required this.datos,
    this.sociosAlDia,
    this.sociosPorVencer,
    this.sociosVencidos,
  });

  @override
  State<EstadoCuotasChart> createState() => _EstadoCuotasChartState();
}

class _EstadoCuotasChartState extends State<EstadoCuotasChart> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    final alDia = widget.datos['alDia'] ?? 0;
    final porVencer = widget.datos['porVencer'] ?? 0;
    final vencidas = widget.datos['vencidas'] ?? 0;
    final total = alDia + porVencer + vencidas;


    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF40E0D0).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            'No hay socios registrados',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ),
      );
    }

    final alDiaPorcentaje = (alDia / total * 100);
    final porVencerPorcentaje = (porVencer / total * 100);
    final vencidasPorcentaje = (vencidas / total * 100);

    // Responsive: detectar si es móvil o tablet/desktop
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final screenWidth = constraints.maxWidth;
        
        // Calcular tamaño del gráfico basado en el ancho disponible
        // En móvil: usar 70% del ancho, máximo 250px
        // En desktop: usar tamaño fijo de 200px
        final chartSize = isMobile 
            ? (screenWidth * 0.7).clamp(150.0, 250.0)
            : 200.0;
        
        // Tamaños adaptativos
        final centerSpaceRadius = isMobile ? (chartSize * 0.3) : 60.0;
        final radius = isMobile ? (chartSize * 0.35) : 70.0;
        final titleFontSize = isMobile ? 18.0 : 22.0;
        final iconSize = isMobile ? 22.0 : 26.0;
        final padding = isMobile ? 16.0 : 24.0;
        final spacing = isMobile ? 16.0 : 28.0;

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF40E0D0).withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF40E0D0).withValues(alpha: 0.3),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 8 : 10),
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
                  SizedBox(width: isMobile ? 8 : 12),
                  Expanded(
                    child: Text(
                      'Estado de Cuotas',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              
              // Layout responsive: Row en desktop, Column en móvil
              if (isMobile) ...[
                // Layout vertical para móvil
                Center(
                  child: SizedBox(
                    width: chartSize,
                    height: chartSize,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: centerSpaceRadius,
                        sections: _buildSections(
                          alDia,
                          porVencer,
                          vencidas,
                          alDiaPorcentaje,
                          porVencerPorcentaje,
                          vencidasPorcentaje,
                          radius,
                          isMobile,
                        ),
                        pieTouchData: PieTouchData(
                          enabled: false, // Deshabilitar interacción del gráfico circular
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: spacing),
                // Leyenda en móvil: centrada y más compacta
                Column(
                  children: [
                    InkWell(
                      onTap: _isNavigating ? null : () => _onLeyendaTapped(context, 0),
                      borderRadius: BorderRadius.circular(10),
                      child: _buildLeyendaItem(
                        'Al Día',
                        alDia,
                        Colors.green,
                        alDiaPorcentaje,
                        isMobile: isMobile,
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 20),
                    InkWell(
                      onTap: _isNavigating ? null : () => _onLeyendaTapped(context, 1),
                      borderRadius: BorderRadius.circular(10),
                      child: _buildLeyendaItem(
                        'Por Vencer',
                        porVencer,
                        Colors.amber,
                        porVencerPorcentaje,
                        isMobile: isMobile,
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 20),
                    InkWell(
                      onTap: _isNavigating ? null : () => _onLeyendaTapped(context, 2),
                      borderRadius: BorderRadius.circular(10),
                      child: _buildLeyendaItem(
                        'Vencidas',
                        vencidas,
                        Colors.red,
                        vencidasPorcentaje,
                        isMobile: isMobile,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Layout horizontal para tablet/desktop
                Row(
                  children: [
                    SizedBox(
                      width: chartSize,
                      height: chartSize,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: centerSpaceRadius,
                          sections: _buildSections(
                            alDia,
                            porVencer,
                            vencidas,
                            alDiaPorcentaje,
                            porVencerPorcentaje,
                            vencidasPorcentaje,
                            radius,
                            isMobile,
                          ),
                          pieTouchData: PieTouchData(
                            enabled: false, // Deshabilitar interacción del gráfico circular
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: _isNavigating ? null : () => _onLeyendaTapped(context, 0),
                            borderRadius: BorderRadius.circular(10),
                            child: _buildLeyendaItem(
                              'Al Día',
                              alDia,
                              Colors.green,
                              alDiaPorcentaje,
                              isMobile: isMobile,
                            ),
                          ),
                          const SizedBox(height: 20),
                          InkWell(
                            onTap: _isNavigating ? null : () => _onLeyendaTapped(context, 1),
                            borderRadius: BorderRadius.circular(10),
                            child: _buildLeyendaItem(
                              'Por Vencer',
                              porVencer,
                              Colors.amber,
                              porVencerPorcentaje,
                              isMobile: isMobile,
                            ),
                          ),
                          const SizedBox(height: 20),
                          InkWell(
                            onTap: _isNavigating ? null : () => _onLeyendaTapped(context, 2),
                            borderRadius: BorderRadius.circular(10),
                            child: _buildLeyendaItem(
                              'Vencidas',
                              vencidas,
                              Colors.red,
                              vencidasPorcentaje,
                              isMobile: isMobile,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _buildSections(
    int alDia,
    int porVencer,
    int vencidas,
    double alDiaPorcentaje,
    double porVencerPorcentaje,
    double vencidasPorcentaje,
    double radius,
    bool isMobile,
  ) {
    final titleFontSize = isMobile ? 12.0 : 14.0;
    
    return [
      PieChartSectionData(
        value: alDia.toDouble(),
        title: '${alDiaPorcentaje.toStringAsFixed(0)}%',
        color: Colors.green,
        radius: radius,
        titleStyle: TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: porVencer.toDouble(),
        title: porVencer > 0 ? '${porVencerPorcentaje.toStringAsFixed(0)}%' : '',
        color: Colors.amber,
        radius: radius,
        titleStyle: TextStyle(
          fontSize: titleFontSize - 2,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: vencidas.toDouble(),
        title: vencidas > 0 ? '${vencidasPorcentaje.toStringAsFixed(0)}%' : '',
        color: Colors.red,
        radius: radius,
        titleStyle: TextStyle(
          fontSize: titleFontSize - 2,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  Widget _buildLeyendaItem(
    String label,
    int cantidad,
    Color color,
    double porcentaje, {
    bool isMobile = false,
  }) {
    final padding = isMobile ? 10.0 : 12.0;
    final iconSize = isMobile ? 16.0 : 20.0;
    final labelFontSize = isMobile ? 14.0 : 16.0;
    final infoFontSize = isMobile ? 12.0 : 13.0;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            SizedBox(width: isMobile ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: labelFontSize,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.touch_app,
                        size: 16,
                        color: color.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 2 : 4),
                  Text(
                    '$cantidad socios • ${porcentaje.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: infoFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onLeyendaTapped(BuildContext context, int sectionIndex) {
    if (_isNavigating) return;
    _navegarASociosFiltrados(context, sectionIndex);
  }

  void _navegarASociosFiltrados(BuildContext context, int sectionIndex) {
    if (_isNavigating) return;
    
    setState(() {
      _isNavigating = true;
    });

    List<Socio> socios;
    String titulo;
    Color color;

    switch (sectionIndex) {
      case 0: // Al Día
        socios = widget.sociosAlDia ?? [];
        titulo = 'Socios al Día';
        color = Colors.green;
        break;
      case 1: // Por Vencer
        socios = widget.sociosPorVencer ?? [];
        titulo = 'Socios por Vencer (7 días)';
        color = Colors.amber;
        break;
      case 2: // Vencidas
        socios = widget.sociosVencidos ?? [];
        titulo = 'Socios con Cuotas Vencidas';
        color = Colors.red;
        break;
      default:
        setState(() {
          _isNavigating = false;
        });
        return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SociosFiltradosScreen(
          socios: socios,
          titulo: titulo,
          color: color,
        ),
      ),
    ).then((_) {
      // Resetear el flag cuando se regresa
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    });
  }
}

