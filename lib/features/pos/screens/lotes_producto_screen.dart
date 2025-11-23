import 'package:flutter/material.dart';
import 'package:gym/features/pos/models/producto.dart';
import 'package:gym/features/pos/models/lote_producto.dart';
import 'package:gym/features/pos/services/lotes_repository.dart';
import 'package:intl/intl.dart';

class LotesProductoScreen extends StatefulWidget {
  final Producto producto;

  const LotesProductoScreen({super.key, required this.producto});

  @override
  State<LotesProductoScreen> createState() => _LotesProductoScreenState();
}

class _LotesProductoScreenState extends State<LotesProductoScreen> {
  final LotesRepository _repository = LotesRepository();
  List<LoteProducto> _lotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarLotes();
  }

  Future<void> _cargarLotes() async {
    setState(() => _isLoading = true);
    try {
      final lotes = await _repository.obtenerPorProducto(widget.producto.id!);
      setState(() {
        _lotes = lotes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando lotes: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _mostrarFormulario({LoteProducto? lote}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _LoteDialog(
        producto: widget.producto,
        lote: lote,
      ),
    );
    if (result == true) _cargarLotes();
  }

  Future<void> _eliminarLote(LoteProducto lote) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Eliminar el lote ${lote.numeroLote}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _repository.eliminar(lote.id!);
        _cargarLotes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lote eliminado'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Color _getColorEstado(LoteProducto lote) {
    if (lote.estaVencido) return Colors.red;
    if (lote.venceCritico) return Colors.orange;
    if (lote.venceProximo) return Colors.yellow.shade700;
    return Colors.green;
  }

  IconData _getIconoEstado(LoteProducto lote) {
    if (lote.estaVencido) return Icons.dangerous;
    if (lote.venceCritico) return Icons.warning;
    if (lote.venceProximo) return Icons.access_time;
    return Icons.check_circle;
  }

  String _getTextoEstado(LoteProducto lote) {
    if (lote.estaVencido) return 'VENCIDO';
    if (lote.venceCritico) return 'VENCE PRONTO';
    if (lote.venceProximo) return 'Por vencer';
    return 'Vigente';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final stockTotal = _lotes.fold<int>(0, (sum, lote) => sum + lote.stockLote);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lotes del Producto'),
            Text(
              widget.producto.nombre,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarLotes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Resumen
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Total Lotes', _lotes.length.toString(), Icons.inventory_2, Colors.blue),
                _buildStatCard('Stock Total', '$stockTotal ${widget.producto.unidadMedida}', Icons.widgets, Colors.green),
                _buildStatCard(
                  'Vencidos',
                  _lotes.where((l) => l.estaVencido).length.toString(),
                  Icons.dangerous,
                  Colors.red,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista de lotes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _lotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No hay lotes registrados',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _mostrarFormulario(),
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar Primer Lote'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _lotes.length,
                        itemBuilder: (context, index) {
                          final lote = _lotes[index];
                          final color = _getColorEstado(lote);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.2),
                                child: Icon(_getIconoEstado(lote), color: color),
                              ),
                              title: Text(
                                lote.numeroLote,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (lote.fechaVencimiento != null) ...[
                                    Text('Vence: ${dateFormat.format(lote.fechaVencimiento!)}'),
                                    if (lote.diasHastaVencimiento != null)
                                      Text(
                                        lote.diasHastaVencimiento! >= 0
                                            ? '${lote.diasHastaVencimiento} días restantes'
                                            : 'Vencido hace ${-lote.diasHastaVencimiento!} días',
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                  Text('Stock: ${lote.stockLote} ${widget.producto.unidadMedida}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: color),
                                    ),
                                    child: Text(
                                      _getTextoEstado(lote),
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                                        value: 'eliminar',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 20, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'editar') {
                                        _mostrarFormulario(lote: lote);
                                      } else if (value == 'eliminar') {
                                        _eliminarLote(lote);
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
        onPressed: () => _mostrarFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Lote'),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

// ============================================
// DIÁLOGO DE FORMULARIO
// ============================================

class _LoteDialog extends StatefulWidget {
  final Producto producto;
  final LoteProducto? lote;

  const _LoteDialog({required this.producto, this.lote});

  @override
  State<_LoteDialog> createState() => _LoteDialogState();
}

class _LoteDialogState extends State<_LoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final LotesRepository _repository = LotesRepository();

  final _numeroLoteController = TextEditingController();
  final _stockController = TextEditingController();
  final _precioCompraController = TextEditingController();
  final _notasController = TextEditingController();

  DateTime? _fechaVencimiento;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.lote != null) {
      _cargarLoteExistente();
    }
  }

  void _cargarLoteExistente() {
    final lote = widget.lote!;
    _numeroLoteController.text = lote.numeroLote;
    _stockController.text = lote.stockLote.toString();
    _precioCompraController.text = lote.precioCompraLote?.toString() ?? '';
    _notasController.text = lote.notas ?? '';
    _fechaVencimiento = lote.fechaVencimiento;
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaVencimiento ?? DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 años
      locale: const Locale('es', 'ES'),
    );
    if (fecha != null) {
      setState(() => _fechaVencimiento = fecha);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.producto.requiereVencimiento && _fechaVencimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este producto requiere fecha de vencimiento'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final lote = LoteProducto(
        id: widget.lote?.id,
        productoId: widget.producto.id!,
        numeroLote: _numeroLoteController.text.trim(),
        fechaVencimiento: _fechaVencimiento,
        stockLote: int.parse(_stockController.text),
        precioCompraLote: _precioCompraController.text.isEmpty
            ? null
            : double.parse(_precioCompraController.text),
        fechaIngreso: widget.lote?.fechaIngreso ?? DateTime.now(),
        notas: _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
      );

      if (widget.lote == null) {
        await _repository.crear(lote);
      } else {
        await _repository.actualizar(lote);
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
    final dateFormat = DateFormat('dd/MM/yyyy');

    return AlertDialog(
      title: Text(widget.lote == null ? 'Nuevo Lote' : 'Editar Lote'),
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
                      controller: _numeroLoteController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Lote',
                        border: OutlineInputBorder(),
                        hintText: 'Auto-generado si se deja vacío',
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _stockController,
                      decoration: InputDecoration(
                        labelText: 'Stock *',
                        border: const OutlineInputBorder(),
                        suffixText: widget.producto.unidadMedida,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Campo requerido';
                        if (int.tryParse(value!) == null) return 'Valor inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: _seleccionarFecha,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: widget.producto.requiereVencimiento
                              ? 'Fecha de Vencimiento *'
                              : 'Fecha de Vencimiento',
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _fechaVencimiento != null
                              ? dateFormat.format(_fechaVencimiento!)
                              : 'Seleccionar fecha',
                          style: TextStyle(
                            color: _fechaVencimiento != null ? null : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _precioCompraController,
                      decoration: const InputDecoration(
                        labelText: 'Precio de Compra (opcional)',
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _notasController,
                      decoration: const InputDecoration(
                        labelText: 'Notas',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
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
          child: Text(widget.lote == null ? 'Crear' : 'Guardar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _numeroLoteController.dispose();
    _stockController.dispose();
    _precioCompraController.dispose();
    _notasController.dispose();
    super.dispose();
  }
}
