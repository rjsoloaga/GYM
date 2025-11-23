import 'package:flutter/material.dart';
import 'package:gym/features/pos/services/ventas_repository.dart';
import 'package:intl/intl.dart';

class DashboardVentasScreen extends StatefulWidget {
  const DashboardVentasScreen({super.key});

  @override
  State<DashboardVentasScreen> createState() => _DashboardVentasScreenState();
}

class _DashboardVentasScreenState extends State<DashboardVentasScreen> {
  final VentasRepository _repository = VentasRepository();
  
  bool _isLoading = true;
  double _totalVentasHoy = 0;
  int _cantidadVentasHoy = 0;
  List<Map<String, dynamic>> _ventas7Dias = [];
  List<Map<String, dynamic>> _topProductos = [];
  Map<String, double> _ventasPorMetodo = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final totalHoy = await _repository.obtenerTotalVentasHoy();
      final cantidadHoy = await _repository.obtenerCantidadVentasHoy();
      final ventas7Dias = await _repository.obtenerVentasUltimos7Dias();
      final topProductos = await _repository.obtenerProductosMasVendidos();
      final ventasMetodo = await _repository.obtenerVentasPorMetodoPago();

      setState(() {
        _totalVentasHoy = totalHoy;
        _cantidadVentasHoy = cantidadHoy;
        _ventas7Dias = ventas7Dias;
        _topProductos = topProductos;
        _ventasPorMetodo = ventasMetodo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando dashboard: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Ventas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Resumen del Día
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Ventas Hoy',
                      currencyFormat.format(_totalVentasHoy),
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Transacciones',
                      _cantidadVentasHoy.toString(),
                      Icons.receipt_long,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Gráfico de Ventas (Últimos 7 días)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ventas Últimos 7 Días',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Total en \$',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: _ventas7Dias.isEmpty
                            ? const Center(child: Text('No hay datos de ventas'))
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: _buildBarChart(),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 3. Top Productos y Métodos de Pago
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Productos
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Top 5 Productos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildTopProductsList(currencyFormat),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Métodos de Pago
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Métodos de Pago', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildPaymentMethodsList(currencyFormat),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: isDark ? Colors.white10 : color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 14)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBarChart() {
    if (_ventas7Dias.isEmpty) return [];

    // Encontrar el valor máximo para escalar
    double maxVal = 0;
    for (var item in _ventas7Dias) {
      final val = (item['total'] as num).toDouble();
      if (val > maxVal) maxVal = val;
    }
    if (maxVal == 0) maxVal = 1;

    return _ventas7Dias.map((item) {
      final total = (item['total'] as num).toDouble();
      final fecha = DateTime.parse(item['fecha'] as String);
      final heightFactor = total / maxVal;
      
      // Formato: "22\nNov" para mostrar día y mes
      final dia = fecha.day.toString();
      final mes = DateFormat('MMM', 'es_ES').format(fecha);

      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Tooltip(
              message: '\$${total.toStringAsFixed(2)}',
              child: Container(
                width: 30,
                height: (140 * heightFactor).clamp(10.0, 140.0), // Reducido de 150 a 140
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Column(
            children: [
              Text(dia, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Text(mes, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
            ],
          ),
        ],
      );
    }).toList();
  }

  Widget _buildTopProductsList(NumberFormat currency) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _topProductos.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final prod = _topProductos[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Text('${index + 1}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
            title: Text(prod['nombre'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text('${prod['cantidad']} unidades vendidas'),
            trailing: Text(
              currency.format(prod['total']),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethodsList(NumberFormat currency) {
    final total = _ventasPorMetodo.values.fold(0.0, (sum, val) => sum + val);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: _ventasPorMetodo.entries.map((entry) {
            final porcentaje = total == 0 ? 0.0 : (entry.value / total);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatMetodoPago(entry.key), style: const TextStyle(fontSize: 14)),
                      Text('${(porcentaje * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: porcentaje,
                    backgroundColor: Colors.grey.shade200,
                    color: _getColorMetodo(entry.key),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatMetodoPago(String metodo) {
    return metodo.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  Color _getColorMetodo(String metodo) {
    switch (metodo) {
      case 'efectivo': return Colors.green;
      case 'tarjeta_debito': return Colors.blue;
      case 'tarjeta_credito': return Colors.orange;
      case 'transferencia': return Colors.purple;
      default: return Colors.grey;
    }
  }
}
