import 'package:flutter/material.dart';
import 'package:gym/core/database/database_helper.dart';
import 'package:gym/features/auth/models/usuario.dart';

class AdminReportesScreen extends StatefulWidget {
  final Usuario usuarioActual;

  const AdminReportesScreen({super.key, required this.usuarioActual});

  @override
  State<AdminReportesScreen> createState() => _AdminReportesScreenState();
}

class _AdminReportesScreenState extends State<AdminReportesScreen> {
  late DateTime _fechaSeleccionada;

  @override
  void initState() {
    super.initState();
    _fechaSeleccionada = DateTime.now();
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  Future<void> _cambiarFecha() async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (fechaSeleccionada != null) {
      setState(() {
        _fechaSeleccionada = fechaSeleccionada;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Ingresos'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seleccionar fecha:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      _formatearFecha(_fechaSeleccionada),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _cambiarFecha,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Cambiar'),
                )
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper.instance.getResumenIngresosDiarios(_fechaSeleccionada),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final pagos = snapshot.data ?? [];

                if (pagos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.money_off, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay pagos registrados para esta fecha',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Calcular totales
                final totalIngresos = pagos.fold<double>(0.0, (sum, p) => sum + (p['amount'] as num).toDouble());

                // Agrupar por usuario
                final pagosPorUsuario = <String, List<Map<String, dynamic>>>{};
                for (var pago in pagos) {
                  final usuarioNombre = pago['usuarioNombre'] ?? 'Sin usuario';
                  pagosPorUsuario.putIfAbsent(usuarioNombre, () => []);
                  pagosPorUsuario[usuarioNombre]!.add(pago);
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Tarjeta de resumen total
                    Card(
                      elevation: 2,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [Colors.blue[600]!, Colors.blue[800]!],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total del ${_formatearFecha(_fechaSeleccionada)}',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '\$${totalIngresos.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total: ${pagos.length} pagos',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Detalles por operador
                    const Text(
                      'Detalles por Operador',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...pagosPorUsuario.entries.map((entry) {
                      final usuarioNombre = entry.key;
                      final pagosDelUsuario = entry.value;
                      final totalUsuario = pagosDelUsuario.fold<double>(0.0, (sum, p) => sum + (p['amount'] as num).toDouble());

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue[300]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      usuarioNombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '${pagosDelUsuario.length} pago${pagosDelUsuario.length != 1 ? 's' : ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '\$${totalUsuario.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...pagosDelUsuario.map((pago) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  Icons.payment,
                                  color: Colors.blue[600],
                                ),
                                title: Text(pago['socioNombre'] ?? 'Socio desconocido'),
                                subtitle: Text(
                                  'Método: ${pago['method'] ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Text(
                                  '\$${(pago['amount'] as num).toDouble().toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 16),
                        ],
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}