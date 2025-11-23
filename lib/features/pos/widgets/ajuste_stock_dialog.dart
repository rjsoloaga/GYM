import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym/features/pos/models/producto.dart';
import 'package:gym/features/pos/models/movimiento_stock.dart';
import 'package:gym/features/pos/services/productos_repository.dart';
import 'package:gym/features/pos/services/movimientos_stock_repository.dart';

class AjusteStockDialog extends StatefulWidget {
  final Producto producto;

  const AjusteStockDialog({super.key, required this.producto});

  @override
  State<AjusteStockDialog> createState() => _AjusteStockDialogState();
}

class _AjusteStockDialogState extends State<AjusteStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final ProductosRepository _productosRepository = ProductosRepository();
  final MovimientosStockRepository _movimientosRepository = MovimientosStockRepository();

  final _nuevoStockController = TextEditingController();
  final _motivoController = TextEditingController();
  
  TipoMovimiento _tipoMovimiento = TipoMovimiento.ajuste;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nuevoStockController.text = widget.producto.stock.toString();
  }

  Future<void> _guardarAjuste() async {
    if (!_formKey.currentState!.validate()) return;

    final nuevoStock = int.parse(_nuevoStockController.text);
    final stockAnterior = widget.producto.stock;
    
    if (nuevoStock == stockAnterior) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El stock no ha cambiado'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Calcular la diferencia
      final diferencia = nuevoStock - stockAnterior;
      
      // Registrar movimiento
      final movimiento = MovimientoStock(
        productoId: widget.producto.id!,
        tipo: _tipoMovimiento,
        cantidad: diferencia.abs(),
        stockAnterior: stockAnterior,
        stockNuevo: nuevoStock,
        motivo: _motivoController.text.trim().isEmpty ? null : _motivoController.text.trim(),
        fechaMovimiento: DateTime.now(),
      );
      
      await _movimientosRepository.registrarMovimiento(movimiento);
      
      // Actualizar stock del producto
      await _productosRepository.actualizarStock(widget.producto.id!, nuevoStock);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Stock ajustado correctamente'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nuevoStock = int.tryParse(_nuevoStockController.text) ?? widget.producto.stock;
    final diferencia = nuevoStock - widget.producto.stock;
    final esIncremento = diferencia > 0;

    return AlertDialog(
      title: Text('Ajustar Stock - ${widget.producto.nombre}'),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stock actual
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Stock Actual:', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            '${widget.producto.stock} ${widget.producto.unidadMedida}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nuevo stock
                    TextFormField(
                      controller: _nuevoStockController,
                      decoration: InputDecoration(
                        labelText: 'Nuevo Stock *',
                        border: const OutlineInputBorder(),
                        suffixText: widget.producto.unidadMedida,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Campo requerido';
                        final num = int.tryParse(value!);
                        if (num == null) return 'Valor inválido';
                        if (num < 0) return 'No puede ser negativo';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    // Indicador de diferencia
                    if (diferencia != 0)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: esIncremento ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: esIncremento ? Colors.green : Colors.red,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              esIncremento ? Icons.arrow_upward : Icons.arrow_downward,
                              color: esIncremento ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${esIncremento ? '+' : ''}$diferencia ${widget.producto.unidadMedida}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: esIncremento ? Colors.green.shade900 : Colors.red.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Tipo de movimiento
                    DropdownButtonFormField<TipoMovimiento>(
                      value: _tipoMovimiento,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Movimiento',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        TipoMovimiento.ajuste,
                        TipoMovimiento.entrada,
                        TipoMovimiento.salida,
                        TipoMovimiento.merma,
                      ].map((tipo) {
                        return DropdownMenuItem(
                          value: tipo,
                          child: Text(_getNombreTipo(tipo)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _tipoMovimiento = value!);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Motivo
                    TextFormField(
                      controller: _motivoController,
                      decoration: const InputDecoration(
                        labelText: 'Motivo (opcional)',
                        border: OutlineInputBorder(),
                        hintText: 'Ej: Inventario físico, rotura, etc.',
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
          onPressed: _isLoading ? null : _guardarAjuste,
          child: const Text('Guardar Ajuste'),
        ),
      ],
    );
  }

  String _getNombreTipo(TipoMovimiento tipo) {
    switch (tipo) {
      case TipoMovimiento.ajuste:
        return 'Ajuste de Inventario';
      case TipoMovimiento.entrada:
        return 'Entrada Manual';
      case TipoMovimiento.salida:
        return 'Salida Manual';
      case TipoMovimiento.merma:
        return 'Merma/Pérdida';
      default:
        return tipo.toString();
    }
  }

  @override
  void dispose() {
    _nuevoStockController.dispose();
    _motivoController.dispose();
    super.dispose();
  }
}
