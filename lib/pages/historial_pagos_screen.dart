import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:gym/blocs/pagos_bloc.dart';
import 'package:gym/models/socio.dart';
import 'package:gym/models/pago.dart';
import 'package:gym/pages/agregar_pago_screen.dart';

class HistorialPagosScreen extends StatefulWidget {
  final Socio socio;

  const HistorialPagosScreen({super.key, required this.socio});

  @override
  State<HistorialPagosScreen> createState() => _HistorialPagosScreenState();
}

class _HistorialPagosScreenState extends State<HistorialPagosScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PagosBloc>().add(CargarPagosPorSocioEvent(widget.socio.id!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Pagos - ${widget.socio.nombreCompleto}'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
        ),
        child: BlocBuilder<PagosBloc, PagosState>(
          builder: (context, state) {
            if (state is PagosCargandoState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is PagosErrorState) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Color(0xFFCF6679)),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${state.error}',
                      style: const TextStyle(color: Color(0xFFCF6679)),
                    ),
                  ],
                ),
              );
            } else if (state is PagosCargadosState) {
              final pagos = state.pagos;
              final total = pagos.fold(0.0, (sum, pago) => sum + pago.monto);

              return Column(
                children: [
                  // Resumen total
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF3A3A3A)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Pagos',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${_formatNumber(total)}',
                              style: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${pagos.length} pago${pagos.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Icon(Icons.payments, color: Color(0xFF2196F3), size: 32),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Lista de pagos
                  Expanded(
                    child: pagos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay pagos registrados',
                                  style: TextStyle(fontSize: 18, color: Colors.grey.shade400),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: pagos.length,
                            itemBuilder: (context, index) {
                              final pago = pagos[index];
                              return _buildPagoCard(pago);
                            },
                          ),
                  ),
                ],
              );
            } else {
              return const Center(child: Text('No hay datos'));
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AgregarPagoScreen(socio: widget.socio),
            ),
          );
          if (resultado == true) {
            context.read<PagosBloc>().add(CargarPagosPorSocioEvent(widget.socio.id!));
          }
        },
        backgroundColor: const Color(0xFF2196F3),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Registrar Pago',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPagoCard(Pago pago) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.payments,
                color: Color(0xFF4CAF50),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${_formatNumber(pago.monto)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(pago.fecha),
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.payment, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        pago.metodoPago,
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                  if (pago.observaciones != null && pago.observaciones!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      pago.observaciones!,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Color(0xFFCF6679)),
              onPressed: () => _eliminarPago(context, pago),
              tooltip: 'Eliminar',
            ),
          ],
        ),
      ),
    );
  }

  void _eliminarPago(BuildContext context, Pago pago) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFCF6679)),
            SizedBox(width: 8),
            Text('Eliminar Pago', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar este pago de \$${_formatNumber(pago.monto)}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<PagosBloc>().add(EliminarPagoEvent(pago.id!));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pago eliminado correctamente'),
                  backgroundColor: Color(0xFF4CAF50),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCF6679)),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
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
