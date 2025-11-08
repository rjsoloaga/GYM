import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:gym/repositories/database_helper.dart';

class IngresosChartScreen extends StatefulWidget {
  final bool esDiario;

  const IngresosChartScreen({
    super.key,
    required this.esDiario,
  });

  @override
  State<IngresosChartScreen> createState() => _IngresosChartScreenState();
}

class _IngresosChartScreenState extends State<IngresosChartScreen> {
  late Future<List<Map<String, dynamic>>> _datosFuture;
  int _periodoSeleccionado = 0; // 0: 7 días/meses, 1: 30 días/meses, 2: 6 meses

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    setState(() {
      if (widget.esDiario) {
        // Para ingresos diarios: 7, 30 días
        final dias = _periodoSeleccionado == 0 ? 7 : 30;
        _datosFuture = DatabaseHelper.instance.getIngresosUltimosDias(dias);
      } else {
        // Para ingresos mensuales: 6, 12 meses
        final meses = _periodoSeleccionado == 0 ? 6 : 12;
        _datosFuture = DatabaseHelper.instance.getIngresosUltimosMeses(meses);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.esDiario ? 'Ingresos Diarios' : 'Ingresos Mensuales',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF000000),
        ),
        child: Column(
          children: [
            // Selector de período
            _buildSelectorPeriodo(),
            
            // Gráfico
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _datosFuture,
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
                            onPressed: _cargarDatos,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF40E0D0),
                            ),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }

                  final datos = snapshot.data ?? [];
                  
                  // Debug: imprimir datos
                  print('📊 Datos recibidos: ${datos.length} registros');
                  if (datos.isNotEmpty) {
                    print('📊 Primer dato: ${datos.first}');
                  }
                  
                  if (datos.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bar_chart,
                            size: 64,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay datos para mostrar',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.esDiario 
                                ? 'No se han registrado pagos en el período seleccionado'
                                : 'No se han registrado pagos en los meses seleccionados',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Resumen
                        _buildResumen(datos),
                        const SizedBox(height: 24),
                        
                        // Gráfico de barras
                        _buildGraficoBarras(datos),
                        const SizedBox(height: 24),
                        
                        // Tabla de datos
                        _buildTablaDatos(datos),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorPeriodo() {
    final opciones = widget.esDiario
        ? ['Últimos 7 días', 'Últimos 30 días']
        : ['Últimos 6 meses', 'Últimos 12 meses'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF40E0D0).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: opciones.asMap().entries.map((entry) {
          final index = entry.key;
          final opcion = entry.value;
          final isSelected = _periodoSeleccionado == index;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _periodoSeleccionado = index;
                  });
                  _cargarDatos();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF40E0D0).withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF40E0D0)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    opcion,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF40E0D0)
                          : Colors.grey.shade400,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResumen(List<Map<String, dynamic>> datos) {
    double total = 0.0;
    double promedio = 0.0;
    double maximo = 0.0;

    for (var dato in datos) {
      final ingreso = (dato['ingresos'] as num).toDouble();
      total += ingreso;
      if (ingreso > maximo) {
        maximo = ingreso;
      }
    }

    promedio = datos.isNotEmpty ? total / datos.length : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF40E0D0).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildResumenItem(
              'Total',
              total,
              Icons.attach_money,
              const Color(0xFF40E0D0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildResumenItem(
              'Promedio',
              promedio,
              Icons.trending_up,
              const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildResumenItem(
              'Máximo',
              maximo,
              Icons.arrow_upward,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenItem(String label, double valor, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          '\$${_formatNumber(valor)}',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildGraficoBarras(List<Map<String, dynamic>> datos) {
    if (datos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        height: 300,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF40E0D0).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: const Center(
          child: Text(
            'No hay datos para graficar',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    
    final ingresos = datos.map((d) => (d['ingresos'] as num).toDouble()).toList();
    
    // Calcular maxY de forma segura
    double maxY = 0.0;
    if (ingresos.isNotEmpty) {
      maxY = ingresos.reduce((a, b) => a > b ? a : b);
    }
    
    // Asegurar que maxYValue sea al menos 100 para que el gráfico sea visible
    final maxYValue = maxY > 0 
        ? (maxY * 1.2).ceilToDouble().clamp(100.0, double.infinity)
        : 100.0;
    
    print('📊 Gráfico: maxY=$maxY, maxYValue=$maxYValue, datos=${datos.length}');
    print('📊 Ingresos: $ingresos');

    return Container(
      padding: const EdgeInsets.all(20),
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF40E0D0).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxYValue,
          minY: 0,
          baselineY: 0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => const Color(0xFF1A1A1A),
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '\$${_formatNumber(rod.toY)}',
                  const TextStyle(
                    color: Color(0xFF40E0D0),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < datos.length) {
                    final label = datos[index]['label'] as String;
                    // Para ingresos diarios con muchos días, mostrar solo algunas etiquetas
                    if (widget.esDiario && datos.length > 14) {
                      // Mostrar cada 3-4 días
                      if (index % 4 == 0 || index == datos.length - 1) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    }
                    // Para ingresos mensuales o días menores, mostrar todos
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: widget.esDiario ? 10 : 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 40,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                interval: maxYValue > 0 ? maxYValue / 5 : 20,
                getTitlesWidget: (value, meta) {
                  if (value < 0) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '\$${_formatNumber(value)}',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxYValue > 0 ? maxYValue / 5 : 20,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade800.withValues(alpha: 0.5),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade800, width: 1),
          ),
          barGroups: datos.asMap().entries.map((entry) {
            final index = entry.key;
            final dato = entry.value;
            final ingreso = (dato['ingresos'] as num).toDouble();
            
            print('📊 Barra $index: ingreso=$ingreso, label=${dato['label']}');
            
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: ingreso > 0 ? ingreso : 0,
                  color: const Color(0xFF40E0D0),
                  width: widget.esDiario ? (datos.length > 14 ? 8 : 12) : 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTablaDatos(List<Map<String, dynamic>> datos) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Detalle',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...datos.asMap().entries.map((entry) {
            final dato = entry.value;
            final ingreso = (dato['ingresos'] as num).toDouble();
            final label = dato['label'] as String;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF40E0D0).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '\$${_formatNumber(ingreso)}',
                    style: TextStyle(
                      color: ingreso > 0
                          ? const Color(0xFF40E0D0)
                          : Colors.grey.shade500,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,##0.00', 'es_ES');
    return formatter.format(number);
  }
}

