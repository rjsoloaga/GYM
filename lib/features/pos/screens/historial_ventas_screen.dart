import 'package:flutter/material.dart';
import 'package:gym/features/pos/models/venta.dart';
import 'package:gym/features/pos/models/detalle_venta.dart';
import 'package:gym/features/pos/services/ventas_repository.dart';
import 'package:intl/intl.dart';

class HistorialVentasScreen extends StatefulWidget {
  const HistorialVentasScreen({super.key});

  @override
  State<HistorialVentasScreen> createState() => _HistorialVentasScreenState();
}

class _HistorialVentasScreenState extends State<HistorialVentasScreen> {
  final VentasRepository _ventasRepository = VentasRepository();
  
  List<Venta> _ventas = [];
  bool _isLoading = true;
  DateTimeRange? _fechaFilter;

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    setState(() => _isLoading = true);
    try {
      List<Venta> ventas;
      if (_fechaFilter != null) {
        // Ajustar fechas para incluir todo el día final
        final fin = _fechaFilter!.end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
        ventas = await _ventasRepository.obtenerPorFecha(
          desde: _fechaFilter!.start,
          hasta: fin,
        );
      } else {
        ventas = await _ventasRepository.obtenerTodas(limit: 100); // Últimas 100 por defecto
      }
      
      setState(() {
        _ventas = ventas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando ventas: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _seleccionarFechas() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _fechaFilter,
    );
    if (picked != null) {
      setState(() => _fechaFilter = picked);
      _cargarVentas();
    }
  }

  Future<void> _verDetalles(Venta venta) async {
    try {
      final detalles = await _ventasRepository.obtenerDetalles(venta.id!);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => _DetalleVentaDialog(venta: venta, detalles: detalles),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando detalles: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancelarVenta(Venta venta) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Venta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de cancelar la venta ${venta.numeroVenta}?'),
            const SizedBox(height: 8),
            const Text(
              '⚠️ Esta acción devolverá el stock de los productos.',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _ventasRepository.cancelarVenta(venta.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Venta cancelada y stock devuelto'), backgroundColor: Colors.green),
          );
        }
        _cargarVentas();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cancelar: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Color _getColorEstado(EstadoVenta estado) {
    switch (estado) {
      case EstadoVenta.completada:
        return Colors.green;
      case EstadoVenta.cancelada:
        return Colors.red;
      case EstadoVenta.pendiente:
        return Colors.orange;
      case EstadoVenta.devuelta:
        return Colors.purple;
    }
  }

  String _getNombreEstado(EstadoVenta estado) {
    switch (estado) {
      case EstadoVenta.completada:
        return 'Completada';
      case EstadoVenta.cancelada:
        return 'Cancelada';
      case EstadoVenta.pendiente:
        return 'Pendiente';
      case EstadoVenta.devuelta:
        return 'Devuelta';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Ventas'),
        actions: [
          IconButton(
            icon: Icon(_fechaFilter == null ? Icons.date_range_outlined : Icons.date_range),
            onPressed: _seleccionarFechas,
            tooltip: 'Filtrar por fecha',
          ),
          if (_fechaFilter != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() => _fechaFilter = null);
                _cargarVentas();
              },
              tooltip: 'Limpiar filtro',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarVentas,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ventas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No se encontraron ventas',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _ventas.length,
                  itemBuilder: (context, index) {
                    final venta = _ventas[index];
                    final color = _getColorEstado(venta.estado);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _verDetalles(venta),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.receipt, color: color, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            venta.numeroVenta,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            dateFormat.format(venta.fechaVenta),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
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
                                        currencyFormat.format(venta.total),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: venta.estado == EstadoVenta.cancelada
                                              ? Colors.grey
                                              : Colors.green.shade700,
                                          decoration: venta.estado == EstadoVenta.cancelada
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _getNombreEstado(venta.estado),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (venta.estado == EstadoVenta.completada) ...[
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _cancelarVenta(venta),
                                      icon: const Icon(Icons.cancel_outlined, size: 18),
                                      label: const Text('Cancelar Venta'),
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _DetalleVentaDialog extends StatelessWidget {
  final Venta venta;
  final List<DetalleVenta> detalles;

  const _DetalleVentaDialog({required this.venta, required this.detalles});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Venta ${venta.numeroVenta}'),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info General
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Fecha:', dateFormat.format(venta.fechaVenta)),
                  _buildInfoRow('Método Pago:', venta.metodoPago.toString().split('.').last.toUpperCase()),
                  if (venta.observaciones != null)
                    _buildInfoRow('Notas:', venta.observaciones!),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            // Lista de productos
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: detalles.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final detalle = detalles[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(detalle.productoNombre, style: const TextStyle(fontWeight: FontWeight.w500)),
                              Text(
                                '${detalle.cantidad} x ${currencyFormat.format(detalle.precioUnitario)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormat.format(detalle.subtotal),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            
            // Totales
            _buildTotalRow('Subtotal:', currencyFormat.format(venta.subtotal)),
            if (venta.descuento > 0)
              _buildTotalRow('Descuento:', '-${currencyFormat.format(venta.descuento)}', color: Colors.green),
            const SizedBox(height: 8),
            _buildTotalRow(
              'TOTAL:', 
              currencyFormat.format(venta.total), 
              isBold: true, 
              fontSize: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isBold = false, double? fontSize, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
          Text(
            value, 
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
