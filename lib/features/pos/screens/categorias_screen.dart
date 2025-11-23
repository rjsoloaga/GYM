import 'package:flutter/material.dart';
import 'package:gym/features/pos/models/categoria_producto.dart';
import 'package:gym/features/pos/services/productos_repository.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final ProductosRepository _repository = ProductosRepository();
  List<CategoriaProducto> _categorias = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    setState(() => _isLoading = true);
    try {
      final categorias = await _repository.obtenerCategorias(soloActivas: false);
      setState(() {
        _categorias = categorias;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando categorías: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _mostrarFormulario({CategoriaProducto? categoria}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _CategoriaDialog(categoria: categoria),
    );
    if (result == true) _cargarCategorias();
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return Colors.blue;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData _parseIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) return Icons.category;
    
    final iconMap = {
      'fitness_center': Icons.fitness_center,
      'local_drink': Icons.local_drink,
      'fastfood': Icons.fastfood,
      'shopping_bag': Icons.shopping_bag,
      'checkroom': Icons.checkroom,
      'category': Icons.category,
      'sports': Icons.sports,
      'restaurant': Icons.restaurant,
      'local_cafe': Icons.local_cafe,
      'cake': Icons.cake,
    };
    
    return iconMap[iconName] ?? Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías de Productos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarCategorias,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categorias.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No hay categorías registradas',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _mostrarFormulario(),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Primera Categoría'),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categorias.length,
                  onReorder: (oldIndex, newIndex) {
                    // TODO: Implementar reordenamiento
                  },
                  itemBuilder: (context, index) {
                    final categoria = _categorias[index];
                    final color = _parseColor(categoria.color);
                    final icon = _parseIcon(categoria.icono);

                    return Card(
                      key: ValueKey(categoria.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.2),
                          child: Icon(icon, color: color),
                        ),
                        title: Text(
                          categoria.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: categoria.descripcion != null
                            ? Text(categoria.descripcion!)
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!categoria.activo)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Inactiva',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            const SizedBox(width: 8),
                            const Icon(Icons.drag_handle),
                          ],
                        ),
                        onTap: () => _mostrarFormulario(categoria: categoria),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Categoría'),
      ),
    );
  }
}

// ============================================
// DIÁLOGO DE FORMULARIO
// ============================================

class _CategoriaDialog extends StatefulWidget {
  final CategoriaProducto? categoria;

  const _CategoriaDialog({this.categoria});

  @override
  State<_CategoriaDialog> createState() => _CategoriaDialogState();
}

class _CategoriaDialogState extends State<_CategoriaDialog> {
  final _formKey = GlobalKey<FormState>();
  final ProductosRepository _repository = ProductosRepository();
  
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  
  String _iconoSeleccionado = 'category';
  Color _colorSeleccionado = Colors.blue;
  bool _activo = true;
  bool _isLoading = false;

  final Map<String, IconData> _iconosDisponibles = {
    'category': Icons.category,
    'fitness_center': Icons.fitness_center,
    'local_drink': Icons.local_drink,
    'fastfood': Icons.fastfood,
    'shopping_bag': Icons.shopping_bag,
    'checkroom': Icons.checkroom,
    'sports': Icons.sports,
    'restaurant': Icons.restaurant,
    'local_cafe': Icons.local_cafe,
    'cake': Icons.cake,
  };

  final List<Color> _coloresDisponibles = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.categoria != null) {
      _cargarCategoriaExistente();
    }
  }

  void _cargarCategoriaExistente() {
    final cat = widget.categoria!;
    _nombreController.text = cat.nombre;
    _descripcionController.text = cat.descripcion ?? '';
    _iconoSeleccionado = cat.icono ?? 'category';
    _colorSeleccionado = _parseColor(cat.color);
    _activo = cat.activo;
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return Colors.blue;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final categoria = CategoriaProducto(
        id: widget.categoria?.id,
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty 
            ? null 
            : _descripcionController.text.trim(),
        icono: _iconoSeleccionado,
        color: _colorToHex(_colorSeleccionado),
        activo: _activo,
        orden: widget.categoria?.orden ?? 0,
        fechaCreacion: widget.categoria?.fechaCreacion ?? DateTime.now(),
      );

      if (widget.categoria == null) {
        await _repository.crearCategoria(categoria);
      } else {
        await _repository.actualizarCategoria(categoria);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.categoria == null ? 'Nueva Categoría' : 'Editar Categoría'),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => 
                          value?.isEmpty ?? true ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Selector de icono
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Icono:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _iconosDisponibles.entries.map((entry) {
                        final isSelected = _iconoSeleccionado == entry.key;
                        return InkWell(
                          onTap: () => setState(() => _iconoSeleccionado = entry.key),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? _colorSeleccionado.withOpacity(0.2)
                                  : Colors.grey.shade200,
                              border: Border.all(
                                color: isSelected ? _colorSeleccionado : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              entry.value,
                              color: isSelected ? _colorSeleccionado : Colors.grey,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Selector de color
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Color:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _coloresDisponibles.map((color) {
                        final isSelected = _colorSeleccionado == color;
                        return InkWell(
                          onTap: () => setState(() => _colorSeleccionado = color),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text('Activa'),
                      value: _activo,
                      onChanged: (value) => setState(() => _activo = value),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _guardar,
          child: Text(widget.categoria == null ? 'Crear' : 'Guardar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }
}
