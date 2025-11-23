import 'package:flutter/material.dart';
import 'package:gym/features/pos/models/movimiento_stock.dart';
import 'package:gym/features/pos/models/producto.dart';
import 'package:gym/features/pos/services/movimientos_stock_repository.dart';
import 'package:gym/features/pos/services/productos_repository.dart';
import 'package:intl/intl.dart';

class MovimientosStockScreen extends StatefulWidget {
  final Producto? producto; // Si se pasa, muestra solo movimientos de ese producto

  const MovimientosStockScreen({super.key, this.producto});

  @override
  State<MovimientosStockScreen> createState() => _MovimientosStockScreenState();
}

class _MovimientosStockScreenState extends State<MovimientosStockScreen> {
  final MovimientosStockRepository _movimientosRepository = MovimientosStockRepository();
  final ProductosRepository _productosRepository = ProductosRepository();
  
  List<MovimientoStock> _movimientos = [];
  Map<int, Producto> _productosCache = {};
  bool _isLoading = true;
  TipoMovimiento? _filtroTipo;

  @override
  void initState() {
    super.initState();
    _cargarMovimientos();
  }

  Future<void> _cargarMovimientos() async {
    setState(() => _isLoading = true);
    try {
      List<MovimientoStock> movimientos;
      
      if (widget.producto != null) {
        movimientos = await _movimientosRepository.obtenerPorProducto(widget.producto!.id!, limit: 100);
        _productosCache[widget.producto!.id!] = widget.producto!;
      } else if (_filtroTipo != null) {
        movimientos = await _movimientosRepository.obtenerPorTipo(_filtroTipo!, limit: 100);
      } else {
        movimientos = await _movimientosRepository.obtenerTodos(limit: 100);
      }
      
      // Cargar productos en caché
      if (widget.producto == null) {
        final productosIds = movimientos.map((m) => m.productoId).toSet();
        for (var id in productosIds) {
          if (!_productosCache.containsKey(id)) {
            final producto = await _productosRepository.obtenerPorId(id);
            if (producto != null) {
              _productosCache[id] = producto;
            }
          }
        }
      }
      
      setState(() {
        _movimientos = movimientos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando movimientos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getColorTipo(TipoMovimiento tipo) {
    switch (tipo) {
      case TipoMovimiento.entrada:
      case TipoMovimiento.compra:
      case TipoMovimiento.devolucion:
        return Colors.green;
      case TipoMovimiento.salida:
      case TipoMovimiento.venta:
        return Colors.blue;
      case TipoMovimiento.merma:
        return Colors.red;
      case TipoMovimiento.ajuste:
        return Colors.orange;
      case TipoMovimiento.transferencia:
        return Colors.purple;
    }
  }

  IconData _getIconoTipo(TipoMovimiento tipo) {
    switch (tipo) {
      case TipoMovimiento.entrada:
        return Icons.arrow_downward;
      case TipoMovimiento.salida:
        return Icons.arrow_upward;
      case TipoMovimiento.compra:
        return Icons.shopping_cart;
      case TipoMovimiento.venta:
        return Icons.point_of_sale;
      case TipoMovimiento.devolucion:
        return Icons.undo;
      case TipoMovimiento.merma:
        return Icons.delete_outline;
      case TipoMovimiento.ajuste:
        return Icons.tune;
      case TipoMovimiento.transferencia:
        return Icons.swap_horiz;
    }
  }

  String _getNombreTipo(TipoMovimiento tipo) {
    switch (tipo) {
      case TipoMovimiento.entrada:
        return 'Entrada';
      case TipoMovimiento.salida:
        return 'Salida';
      case TipoMovimiento.compra:
        return 'Compra';
      case TipoMovimiento.venta:
        return 'Venta';
      case TipoMovimiento.devolucion:
        return 'Devolución';
      case TipoMovimiento.merma:
        return 'Merma';
      case TipoMovimiento.ajuste:
        return 'Ajuste';
      case TipoMovimiento.transferencia:
        return 'Transferencia';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.producto != null 
            ? 'Movimientos - ${widget.producto!.nombre}'
            : 'Historial de Movimientos'),
        actions: [
          if (widget.producto == null)
            PopupMenuButton<TipoMovimiento?>(
              icon: Icon(_filtroTipo != null ? Icons.filter_alt : Icons.filter_alt_outlined),
              tooltip: 'Filtrar por tipo',
              onSelected: (tipo) {
                setState(() => _filtroTipo = tipo);
                _cargarMovimientos();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: null,
                  child: Text('Todos los tipos'),
                ),
                const PopupMenuDivider(),
                ...TipoMovimiento.values.map((tipo) => PopupMenuItem(
                  value: tipo,
                  child: Row(
                    children: [
                      Icon(_getIconoTipo(tipo), size: 20, color: _getColorTipo(tipo)),
                      const SizedBox(width: 8),
                      Text(_getNombreTipo(tipo)),
                    ],
                  ),
                )),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarMovimientos,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _movimientos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No hay movimientos registrados',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _movimientos.length,
                  itemBuilder: (context, index) {
                    final movimiento = _movimientos[index];
                    final producto = _productosCache[movimiento.productoId];
                    final color = _getColorTipo(movimiento.tipo);
                    final esPositivo = movimiento.stockNuevo > movimiento.stockAnterior;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.2),
                          child: Icon(_getIconoTipo(movimiento.tipo), color: color),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getNombreTipo(movimiento.tipo),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: esPositivo ? Colors.green.shade100 : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${esPositivo ? '+' : ''}${movimiento.cantidad}',
                                style: TextStyle(
                                  color: esPositivo ? Colors.green.shade900 : Colors.red.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (producto != null && widget.producto == null)
                              Text(
                                producto.nombre,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            if (movimiento.motivo != null)
                              Text(movimiento.motivo!),
                            Text(
                              'Stock: ${movimiento.stockAnterior} → ${movimiento.stockNuevo}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              dateFormat.format(movimiento.fechaMovimiento),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          esPositivo ? Icons.trending_up : Icons.trending_down,
                          color: esPositivo ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
