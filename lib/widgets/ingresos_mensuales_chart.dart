import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class IngresosMensualesChart extends StatelessWidget {
  final List<Map<String, dynamic>> datos;

  const IngresosMensualesChart({
    super.key,
    required this.datos,
  });

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) {
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
            'No hay datos disponibles',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ),
      );
    }

    final maxIngresos = datos.map((d) => d['ingresos'] as double).reduce((a, b) => a > b ? a : b);
    final maxY = maxIngresos > 0 ? (maxIngresos * 1.2).ceil().toDouble() : 100.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF40E0D0).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF40E0D0).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 1,
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
                      const Color(0xFF40E0D0).withValues(alpha: 0.3),
                      const Color(0xFF40E0D0).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF40E0D0).withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Color(0xFF40E0D0),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ingresos Mensuales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade800,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < datos.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              datos[value.toInt()]['label'],
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: maxY / 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${NumberFormat('#,##0', 'es_ES').format(value.toInt())}',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Colors.grey.shade800,
                    width: 1,
                  ),
                ),
                minX: 0,
                maxX: (datos.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: datos.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value['ingresos'] as double,
                      );
                    }).toList(),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF40E0D0), Color(0xFF30D5C8)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF40E0D0).withValues(alpha: 0.3),
                          const Color(0xFF40E0D0).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

