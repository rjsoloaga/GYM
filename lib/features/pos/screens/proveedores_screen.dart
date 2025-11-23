import 'package:flutter/material.dart';
import 'package:gym/features/pos/models/proveedor.dart';
import 'package:gym/features/pos/services/productos_repository.dart';
import 'package:gym/features/pos/screens/proveedor_form_screen.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  final ProductosRepository _repository = ProductosRepository();
  final TextEditingController _searchController = TextEditingController();
  
  List<Proveedor> _proveedores = [];
  List<Proveedor> _proveedoresFiltrados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarProveedores();
  }

  Future<void> _cargarProveedores() async {
    setState(() => _isLoading = true);
    try {
      final proveedores = await _repository.obtenerProveedores(soloActivos: false);
      setState(() {
        _proveedores = proveedores;
        _proveedoresFiltrados = proveedores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando proveedores: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _filtrarProveedores(String query) {
    setState(() {
      if (query.isEmpty) {
        _proveedoresFiltrados = _proveedores;
      } else {
        _proveedoresFiltrados = _proveedores.where((p) =>
          p.nombre.toLowerCase().contains(query.toLowerCase()) ||
          (p.razonSocial?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
          (p.cuit?.contains(query) ?? false)
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarProveedores,
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
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, razón social o CUIT...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filtrarProveedores('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filtrarProveedores,
            ),
          ),

          // Estadísticas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildStatChip(
                  'Total',
                  _proveedores.length.toString(),
                  Icons.business,
                  Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatChip(
                  'Activos',
                  _proveedores.where((p) => p.activo).length.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ],
            ),
          ),

          const Divider(),

          // Lista de proveedores
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _proveedoresFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No hay proveedores registrados'
                                  : 'No se encontraron proveedores',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                            if (_searchController.text.isEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ProveedorFormScreen(),
                                    ),
                                  );
                                  if (result == true) _cargarProveedores();
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Agregar Primer Proveedor'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _proveedoresFiltrados.length,
                        itemBuilder: (context, index) {
                          final proveedor = _proveedoresFiltrados[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: proveedor.activo 
                                    ? Colors.blue.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.2),
                                child: Icon(
                                  Icons.business,
                                  color: proveedor.activo ? Colors.blue : Colors.grey,
                                ),
                              ),
                              title: Text(
                                proveedor.nombre,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (proveedor.razonSocial != null)
                                    Text(proveedor.razonSocial!),
                                  if (proveedor.cuit != null)
                                    Text('CUIT: ${proveedor.cuit}'),
                                  if (proveedor.telefono != null)
                                    Text('Tel: ${proveedor.telefono}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!proveedor.activo)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Inactivo',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProveedorFormScreen(proveedor: proveedor),
                                  ),
                                );
                                if (result == true) _cargarProveedores();
                              },
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
              builder: (context) => const ProveedorFormScreen(),
            ),
          );
          if (result == true) _cargarProveedores();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Proveedor'),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
