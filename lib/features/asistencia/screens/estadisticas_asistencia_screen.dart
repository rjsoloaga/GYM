import 'package:flutter/material.dart';
import 'package:gym/core/database/database_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class EstadisticasAsistenciaScreen extends StatefulWidget {
  const EstadisticasAsistenciaScreen({super.key});

  @override
  State<EstadisticasAsistenciaScreen> createState() => _EstadisticasAsistenciaScreenState();
}

class _EstadisticasAsistenciaScreenState extends State<EstadisticasAsistenciaScreen> {
  late Future<Map<String, dynamic>> _estadisticasFuture;
  int _diasInactividad = 30;

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
    final asistenciasPorDia = await DatabaseHelper.instance.getAsistenciasPorDiaSemana();
    final sociosInactivos = await DatabaseHelper.instance.getSociosSinAsistir(dias: _diasInactividad);
    
    return {
      'asistenciasPorDia': asistenciasPorDia,
      'sociosInactivos': sociosInactivos,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas de Asistencia'),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _estadisticasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final stats = snapshot.data ?? {};
          final asistenciasPorDia = stats['asistenciasPorDia'] as Map<String, int>? ?? {};
          final sociosInactivos = stats['sociosInactivos'] as List<Map<String, dynamic>>? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gráfico de asistencias por día de la semana
                _buildGraficoDiasSemana(asistenciasPorDia),
                const SizedBox(height: 24),
                
                // Selector de días de inactividad
                _buildSelectorInactividad(),
                const SizedBox(height: 16),
                
                // Lista de socios inactivos
                _buildListaSociosInactivos(sociosInactivos),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGraficoDiasSemana(Map<String, int> datos) {
    if (datos.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay datos de asistencia disponibles'),
        ),
      );
    }

    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final valores = dias.map((dia) => datos[dia]?.toDouble() ?? 0.0).toList();
    final maxY = valores.reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Asistencias por Día (últimos 30 días)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY > 0 ? maxY * 1.2 : 10,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${dias[groupIndex]}\n${rod.toY.toInt()} asistencias',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                          if (value.toInt() >= 0 && value.toInt() < dias.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                dias[value.toInt()].substring(0, 3),
                                style: const TextStyle(fontSize: 10),
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
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    dias.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: valores[index],
                          color: Colors.blue,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorInactividad() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Socios Inactivos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Mostrar socios que no asisten hace:'),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _diasInactividad,
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('7 días')),
                    DropdownMenuItem(value: 15, child: Text('15 días')),
                    DropdownMenuItem(value: 30, child: Text('30 días')),
                    DropdownMenuItem(value: 60, child: Text('60 días')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _diasInactividad = value;
                      });
                      _cargarEstadisticas();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaSociosInactivos(List<Map<String, dynamic>> socios) {
    if (socios.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  '¡Excelente! No hay socios inactivos en los últimos $_diasInactividad días',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '${socios.length} socios inactivos',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: socios.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final socio = socios[index];
              final ultimaAsistencia = socio['ultimaAsistencia'] != null
                  ? DateTime.parse(socio['ultimaAsistencia'])
                  : null;
              final diasSinAsistir = socio['diasSinAsistir'] ?? 0;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.2),
                  child: const Icon(Icons.person_off, color: Colors.orange),
                ),
                title: Text(socio['nombreCompleto'] ?? 'Sin nombre'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DNI: ${socio['dni']}'),
                    if (ultimaAsistencia != null)
                      Text(
                        'Última asistencia: ${DateFormat('dd/MM/yyyy').format(ultimaAsistencia)} ($diasSinAsistir días)',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      )
                    else
                      const Text(
                        'Nunca asistió',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                  ],
                ),
                trailing: socio['telefono'] != null
                    ? IconButton(
                        icon: const Icon(Icons.phone, color: Colors.blue),
                        onPressed: () {
                          // TODO: Integrar con llamada o WhatsApp
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Teléfono: ${socio['telefono']}')),
                          );
                        },
                      )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
