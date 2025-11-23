import 'package:flutter/material.dart';
import 'package:gym/features/pos/models/producto.dart';
import 'package:gym/features/pos/services/productos_repository.dart';
import 'package:gym/features/pos/screens/producto_form_screen.dart';
import 'package:gym/features/pos/screens/lotes_producto_screen.dart';
import 'package:gym/features/pos/widgets/ajuste_stock_dialog.dart';
import 'package:intl/intl.dart';

class ProductosListScreen extends StatefulWidget {
  const ProductosListScreen({super.key});

  @override
  State<ProductosListScreen> createState() => _ProductosListScreenState();
}

class _ProductosListScreenState extends State<ProductosListScreen> {
  final ProductosRepository _repository = ProductosRepository();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  
  List<Producto> _productos = [];
  List<Producto> _productosFiltrados = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _cargarProductos();
    // Asegurar foco para lector de código de barras
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    setState(() => _isLoading = true);
    try {
      final productos = await _repository.obtenerTodos();
      setState(() {
        _productos = productos;
        _productosFiltrados = productos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando productos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _filtrarProductos(String query) {
    setState(() {
      if (query.isEmpty) {
        _productosFiltrados = _productos;
      } else {
        _productosFiltrados = _productos.where((p) =>
          p.nombre.toLowerCase().contains(query.toLowerCase()) ||
          (p.codigo?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
          (p.codigoBarras?.toLowerCase().contains(query.toLowerCase()) ?? false)
        ).toList();
      }
    });
  }

  Color _getStockColor(Producto producto) {
    if (producto.stockCritico) return Colors.red;
    if (producto.bajStock) return Colors.orange;
    return Colors.green;
  }

  IconData _getStockIcon(Producto producto) {
    if (producto.stockCritico) return Icons.error;
    if (producto.bajStock) return Icons.warning;
    return Icons.check_circle;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarProductos,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, código o código de barras...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filtrarProductos('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filtrarProductos,
            ),
          ),

          // Estadísticas rápidas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Total',
                  _productos.length.toString(),
                  Icons.inventory_2,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Bajo Stock',
                  _productos.where((p) => p.bajStock).length.toString(),
                  Icons.warning,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Sin Stock',
                  _productos.where((p) => p.stock == 0).length.toString(),
                  Icons.error,
                  Colors.red,
                ),
              ],
            ),
          ),

          const Divider(),

          // Lista de productos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _productosFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No hay productos registrados'
                                  : 'No se encontraron productos',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                            if (_searchController.text.isEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ProductoFormScreen(),
                                    ),
                                  );
                                  if (result == true) _cargarProductos();
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Agregar Primer Producto'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _productosFiltrados.length,
                        itemBuilder: (context, index) {
                          final producto = _productosFiltrados[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStockColor(producto).withOpacity(0.2),
                                child: Icon(
                                  _getStockIcon(producto),
                                  color: _getStockColor(producto),
                                ),
                              ),
                              title: Text(
                                producto.nombre,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (producto.codigo != null)
                                    Text('Código: ${producto.codigo}'),
                                  Text('Stock: ${producto.stock} ${producto.unidadMedida}'),
                                  Text(
                                    'Precio: ${currencyFormat.format(producto.precioVenta)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (producto.margenGanancia != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '+${producto.margenGanancia!.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          color: Colors.green.shade900,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  if (producto.requiereVencimiento)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Icon(
                                        Icons.event_busy,
                                        size: 20,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  PopupMenuButton(
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'editar',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 20),
                                            SizedBox(width: 8),
                                            Text('Editar'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'ajustar',
                                        child: Row(
                                          children: [
                                            Icon(Icons.tune, size: 20, color: Colors.orange),
                                            SizedBox(width: 8),
                                            Text('Ajustar Stock'),
                                          ],
                                        ),
                                      ),
                                      if (producto.requiereVencimiento)
                                        const PopupMenuItem(
                                          value: 'lotes',
                                          child: Row(
                                            children: [
                                              Icon(Icons.inventory, size: 20, color: Colors.blue),
                                              SizedBox(width: 8),
                                              Text('Gestionar Lotes'),
                                            ],
                                          ),
                                        ),
                                    ],
                                    onSelected: (value) async {
                                      if (value == 'editar') {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ProductoFormScreen(producto: producto),
                                          ),
                                        );
                                        if (result == true) _cargarProductos();
                                      } else if (value == 'ajustar') {
                                        final result = await showDialog(
                                          context: context,
                                          builder: (context) => AjusteStockDialog(producto: producto),
                                        );
                                        if (result == true) _cargarProductos();
                                      } else if (value == 'lotes') {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => LotesProductoScreen(producto: producto),
                                          ),
                                        );
                                        _cargarProductos(); // Recargar para actualizar stock
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProductoFormScreen(),
            ),
          );
          if (result == true) _cargarProductos();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Producto'),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }


}
