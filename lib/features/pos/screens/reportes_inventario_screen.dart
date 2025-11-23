import 'package:flutter/material.dart';
import 'package:gym/features/pos/models/producto.dart';
import 'package:gym/features/pos/models/movimiento_stock.dart';
import 'package:gym/features/pos/services/productos_repository.dart';
import 'package:gym/features/pos/services/movimientos_stock_repository.dart';
import 'package:intl/intl.dart';

class ReportesInventarioScreen extends StatefulWidget {
  const ReportesInventarioScreen({super.key});

  @override
  State<ReportesInventarioScreen> createState() => _ReportesInventarioScreenState();
}

class _ReportesInventarioScreenState extends State<ReportesInventarioScreen> {
  final ProductosRepository _productosRepository = ProductosRepository();
  final MovimientosStockRepository _movimientosRepository = MovimientosStockRepository();

  bool _isLoading = true;
  
  // Métricas
  double _valorizacionTotal = 0;
  int _totalProductos = 0;
  int _productosBajoStock = 0;
  int _productosSinStock = 0;
  double _margenPromedioGeneral = 0;
  
  List<Producto> _productosMasValiosos = [];
  List<Producto> _productosBajoStockList = [];
  List<Producto> _productosSinMovimiento = [];

  @override
  void initState() {
    super.initState();
    _cargarReportes();
  }

  Future<void> _cargarReportes() async {
    setState(() => _isLoading = true);
    try {
      final productos = await _productosRepository.obtenerTodos();
      
      // Cálculos básicos
      _totalProductos = productos.length;
      _productosBajoStock = productos.where((p) => p.bajStock).length;
      _productosSinStock = productos.where((p) => p.stock == 0).length;
      
      // Valorización total (stock * precio de compra)
      _valorizacionTotal = productos.fold(0.0, (sum, p) => sum + (p.stock * p.precioCompra));
      
      // Margen promedio
      final productosConMargen = productos.where((p) => p.margenGanancia != null).toList();
      if (productosConMargen.isNotEmpty) {
        _margenPromedioGeneral = productosConMargen.fold(0.0, (sum, p) => sum + p.margenGanancia!) / productosConMargen.length;
      }
      
      // Productos más valiosos (por valor total en stock)
      final productosConValor = productos.map((p) {
        return MapEntry(p, p.stock * p.precioCompra);
      }).toList();
      productosConValor.sort((a, b) => b.value.compareTo(a.value));
      _productosMasValiosos = productosConValor.take(5).map((e) => e.key).toList();
      
      // Productos bajo stock
      _productosBajoStockList = productos.where((p) => p.bajStock && p.stock > 0).toList();
      _productosBajoStockList.sort((a, b) => a.stock.compareTo(b.stock));
      _productosBajoStockList = _productosBajoStockList.take(10).toList();
      
      // Productos sin movimiento (últimos 30 días)
      final hace30Dias = DateTime.now().subtract(const Duration(days: 30));
      _productosSinMovimiento = [];
      
      for (var producto in productos) {
        final movimientos = await _movimientosRepository.obtenerPorProducto(producto.id!, limit: 1);
        if (movimientos.isEmpty || movimientos.first.fechaMovimiento.isBefore(hace30Dias)) {
          _productosSinMovimiento.add(producto);
        }
        // Limitar a 10 para no hacer muy lenta la carga
        if (_productosSinMovimiento.length >= 10) break;
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando reportes: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarReportes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarReportes,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Métricas principales
                  const Text(
                    'Resumen General',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildMetricCard(
                        'Valorización Total',
                        currencyFormat.format(_valorizacionTotal),
                        Icons.attach_money,
                        Colors.green,
                      ),
                      _buildMetricCard(
                        'Total Productos',
                        _totalProductos.toString(),
                        Icons.inventory_2,
                        Colors.blue,
                      ),
                      _buildMetricCard(
                        'Bajo Stock',
                        _productosBajoStock.toString(),
                        Icons.warning,
                        Colors.orange,
                      ),
                      _buildMetricCard(
                        'Sin Stock',
                        _productosSinStock.toString(),
                        Icons.error,
                        Colors.red,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.trending_up, color: Colors.green.shade700, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Margen Promedio General',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                                Text(
                                  '${_margenPromedioGeneral.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Productos más valiosos
                  _buildSectionTitle('Top 5 - Productos Más Valiosos', Icons.star, Colors.amber),
                  const SizedBox(height: 8),
                  ..._productosMasValiosos.map((producto) {
                    final valorTotal = producto.stock * producto.precioCompra;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber.withOpacity(0.2),
                          child: const Icon(Icons.star, color: Colors.amber),
                        ),
                        title: Text(producto.nombre),
                        subtitle: Text('Stock: ${producto.stock} ${producto.unidadMedida}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(valorTotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${currencyFormat.format(producto.precioCompra)} c/u',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Productos bajo stock
                  if (_productosBajoStockList.isNotEmpty) ...[
                    _buildSectionTitle('Productos Bajo Stock', Icons.warning, Colors.orange),
                    const SizedBox(height: 8),
                    ..._productosBajoStockList.map((producto) {
                      final porcentaje = (producto.stock / producto.stockMinimo * 100).toInt();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.withOpacity(0.2),
                            child: const Icon(Icons.warning, color: Colors.orange),
                          ),
                          title: Text(producto.nombre),
                          subtitle: Text('Mínimo: ${producto.stockMinimo} ${producto.unidadMedida}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${producto.stock}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.orange,
                                ),
                              ),
                              Text(
                                '$porcentaje%',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // Productos sin movimiento
                  if (_productosSinMovimiento.isNotEmpty) ...[
                    _buildSectionTitle('Productos Sin Movimiento (30 días)', Icons.schedule, Colors.grey),
                    const SizedBox(height: 8),
                    ..._productosSinMovimiento.map((producto) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            child: const Icon(Icons.schedule, color: Colors.grey),
                          ),
                          title: Text(producto.nombre),
                          subtitle: Text('Stock: ${producto.stock} ${producto.unidadMedida}'),
                          trailing: Text(
                            currencyFormat.format(producto.stock * producto.precioCompra),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
