import 'package:flutter/material.dart';
import 'package:gym/core/database/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:gym/features/auth/models/usuario.dart';

class ResumenIngresosDiariosScreen extends StatefulWidget {
  final DateTime? fecha;

  const ResumenIngresosDiariosScreen({super.key, this.fecha});

  @override
  State<ResumenIngresosDiariosScreen> createState() => _ResumenIngresosDiariosScreenState();
}

class _ResumenIngresosDiariosScreenState extends State<ResumenIngresosDiariosScreen> {
  late Future<List<Map<String, dynamic>>> _pagosFuture;
  late DateTime _fechaSeleccionada;

  @override
  void initState() {
    super.initState();
    _fechaSeleccionada = widget.fecha ?? DateTime.now();
    _cargarPagos();
  }

  void _cargarPagos() {
    _pagosFuture = DatabaseHelper.instance.getResumenIngresosDiarios(_fechaSeleccionada);
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
        _cargarPagos();
      });
    }
  }

  // Formatear número con separadores de miles
  String _formatNumber(double number) {
    final formatter = NumberFormat('#,###', 'es_AR');
    return formatter.format(number);
  }

  // Obtener el color según el rol del usuario
  Color _getRolColor(String? rol) {
    switch (rol?.toLowerCase()) {
      case 'admin':
        return Colors.blueAccent;
      case 'operador':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de Ingresos Diarios'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarPagos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fecha:',
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
                  label: const Text('Cambiar Fecha'),
                )
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _pagosFuture,
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
                final totalPagos = pagos.length;

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
                    // Tarjeta de resumen
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.green[600]!, Colors.green[800]!],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.assessment, color: Colors.white70, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Resumen del Día',
                                  style: TextStyle(
                                    color: Colors.white70, 
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    DateFormat('dd/MM/yyyy').format(_fechaSeleccionada),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Total Recaudado',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\$${_formatNumber(totalIngresos)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 40,
                                  width: 1,
                                  color: Colors.white24,
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Total de Pagos',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$totalPagos ${totalPagos == 1 ? 'pago' : 'pagos'}' ,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Pagos por usuario
                    ...pagosPorUsuario.entries.map((entry) {
                      final usuarioNombre = entry.key;
                      final pagosDelUsuario = entry.value;
                      final totalUsuario = pagosDelUsuario.fold<double>(0.0, (sum, p) => sum + (p['amount'] as num).toDouble());

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.person_outline, size: 20, color: Colors.green),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          usuarioNombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${pagosDelUsuario.length} ${pagosDelUsuario.length == 1 ? 'pago' : 'pagos'}' ,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$${_formatNumber(totalUsuario)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Total recaudado',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...pagosDelUsuario.map((pago) {
                            final fechaPago = DateTime.parse(pago['date']);
                            final horaPago = DateFormat('HH:mm').format(fechaPago);
                            final usuarioRol = pago['usuarioRol'] ?? 'sistema';
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: Colors.grey[200]!),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '\$${pago['amount'].toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getRolColor(usuarioRol).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            usuarioRol.toUpperCase(),
                                            style: TextStyle(
                                              color: _getRolColor(usuarioRol),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                                        const SizedBox(width: 4),
                                        Text(
                                          horaPago,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
                                        const SizedBox(width: 4),
                                        Text(
                                          pago['usuarioNombre']?.toString() ?? 'Sistema',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (pago['method'] != null) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.credit_card, size: 14, color: Colors.grey[500]),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Método: ${pago['method']}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (pago['socioNombre'] != null) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.person, size: 14, color: Colors.grey[500]),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Socio: ${pago['socioNombre']}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
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
