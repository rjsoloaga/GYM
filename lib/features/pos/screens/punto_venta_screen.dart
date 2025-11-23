import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/features/pos/models/producto.dart';
import 'package:gym/features/pos/models/venta.dart';
import 'package:gym/features/pos/models/detalle_venta.dart';
import 'package:gym/features/pos/models/caja_sesion.dart';
import 'package:gym/features/pos/services/productos_repository.dart';
import 'package:gym/features/pos/services/ventas_repository.dart';
import 'package:gym/features/pos/services/caja_repository.dart';
import 'package:gym/features/pos/screens/apertura_caja_screen.dart';
import 'package:gym/features/pos/screens/cierre_caja_screen.dart';
import 'package:gym/features/socios/bloc/auth_bloc.dart';
import 'package:intl/intl.dart';

class ItemCarrito {
  final Producto producto;
  int cantidad;
  double descuento;

  ItemCarrito({
    required this.producto,
    this.cantidad = 1,
    this.descuento = 0,
  });

  double get subtotal => (producto.precioVenta * cantidad) - descuento;
}

class PuntoVentaScreen extends StatefulWidget {
  final CajaSesion cajaInicial;
  
  const PuntoVentaScreen({super.key, required this.cajaInicial});

  @override
  State<PuntoVentaScreen> createState() => _PuntoVentaScreenState();
}

class _PuntoVentaScreenState extends State<PuntoVentaScreen> {
  final ProductosRepository _productosRepository = ProductosRepository();
  final VentasRepository _ventasRepository = VentasRepository();
  final CajaRepository _cajaRepository = CajaRepository();
  
  final TextEditingController _codigoBarrasController = TextEditingController();
  final FocusNode _codigoBarrasFocus = FocusNode();
  
  List<ItemCarrito> _carrito = [];
  MetodoPago _metodoPago = MetodoPago.efectivo;
  double _descuentoGeneral = 0;
  bool _isProcessing = false;
  int _multiplicadorProximo = 1; // Para la función "X"
  late CajaSesion _cajaActual;

  @override
  void initState() {
    super.initState();
    _cajaActual = widget.cajaInicial;
    
    // Dar foco al campo de búsqueda
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _codigoBarrasFocus.requestFocus();
    });
  }

  // Manejo de teclas (Atajos y Multiplicador)
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // F1: Finalizar Venta
      if (event.logicalKey == LogicalKeyboardKey.f1) {
        if (_carrito.isNotEmpty) _finalizarVenta();
      }
      // F4: Cancelar Venta
      else if (event.logicalKey == LogicalKeyboardKey.f4) {
        if (_carrito.isNotEmpty) _cancelarVenta();
      }
      // F2: Foco en buscador
      else if (event.logicalKey == LogicalKeyboardKey.f2) {
        _codigoBarrasFocus.requestFocus();
      }
      // Tecla X (si no estamos escribiendo en un campo de texto)
      else if (event.logicalKey == LogicalKeyboardKey.keyX && 
               FocusManager.instance.primaryFocus != _codigoBarrasFocus) {
        _mostrarDialogoMultiplicador();
      }
    }
  }

  void _onSearchChanged(String value) {
    if (value.toLowerCase() == 'x') {
      _mostrarDialogoMultiplicador();
    }
  }

  Future<void> _procesarInput(String valor) async {
    if (valor.trim().isEmpty) return;

    // Detectar multiplicador "X" o "x"
    if (valor.toLowerCase() == 'x') {
      _mostrarDialogoMultiplicador();
      return;
    }

    // Si el usuario escribió "5x" o "5X" directamente
    if (valor.toLowerCase().endsWith('x') && valor.length > 1) {
      final cantidadStr = valor.substring(0, valor.length - 1);
      final cantidad = int.tryParse(cantidadStr);
      if (cantidad != null && cantidad > 0) {
        setState(() => _multiplicadorProximo = cantidad);
        _codigoBarrasController.clear();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🔢 Multiplicador activo: $cantidad unidades para el próximo producto'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }

    // Procesar como código de producto
    await _buscarYAgregarProducto(valor);
  }

  Future<void> _mostrarDialogoMultiplicador() async {
    _codigoBarrasController.clear();
    final controller = TextEditingController();
    
    final cantidad = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ingresar Cantidad'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Cantidad',
            hintText: 'Ej: 5',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            Navigator.pop(context, int.tryParse(value));
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (cantidad != null && cantidad > 0) {
      setState(() => _multiplicadorProximo = cantidad);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔢 Multiplicador activo: $cantidad unidades para el próximo producto'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    _codigoBarrasFocus.requestFocus();
  }

  Future<void> _buscarYAgregarProducto(String valor) async {
    try {
      // 1. Intentar buscar por código exacto (barras o interno)
      Producto? producto = await _productosRepository.obtenerPorCodigo(valor.trim());
      
      // 2. Si no encuentra, buscar por nombre (si el valor parece texto)
      if (producto == null) {
        final productosPorNombre = await _productosRepository.buscarProductos(valor.trim());
        
        if (productosPorNombre.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ No se encontró: $valor'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          _codigoBarrasController.clear();
          _codigoBarrasFocus.requestFocus();
          return;
        } else if (productosPorNombre.length == 1) {
          // Solo uno encontrado por nombre
          producto = productosPorNombre.first;
        } else {
          // Varios encontrados: Mostrar selector
          if (mounted) {
            final seleccionado = await showDialog<Producto>(
              context: context,
              builder: (context) => SimpleDialog(
                title: Text('Seleccionar Producto ("$valor")'),
                children: productosPorNombre.map((p) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, p),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('\$${p.precioVenta}', style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
                )).toList(),
              ),
            );
            
            if (seleccionado != null) {
              producto = seleccionado;
            } else {
              _codigoBarrasController.clear();
              _codigoBarrasFocus.requestFocus();
              return;
            }
          }
        }
      }

      // A partir de aquí, ya tenemos un producto identificado
      if (producto!.stock <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ ${producto.nombre} sin stock'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        _codigoBarrasController.clear();
        _codigoBarrasFocus.requestFocus();
        return;
      }

      // Usar multiplicador y resetearlo
      final cantidadAAgregar = _multiplicadorProximo;
      
      // Verificar stock total necesario
      if (cantidadAAgregar > producto.stock) {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Stock insuficiente para $cantidadAAgregar unidades (${producto.stock} disponibles)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        _codigoBarrasController.clear();
        _codigoBarrasFocus.requestFocus();
        return;
      }

      setState(() {
        final index = _carrito.indexWhere((item) => item.producto.id == producto!.id);
        if (index >= 0) {
          // Ya existe
          if (_carrito[index].cantidad + cantidadAAgregar <= producto!.stock) {
            _carrito[index].cantidad += cantidadAAgregar;
          }
        } else {
          // Nuevo
          _carrito.add(ItemCarrito(producto: producto!, cantidad: cantidadAAgregar));
        }
        
        // Resetear multiplicador
        _multiplicadorProximo = 1;
      });

      _codigoBarrasController.clear();
      _codigoBarrasFocus.requestFocus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${producto.nombre} (x$cantidadAAgregar) agregado'),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      _codigoBarrasController.clear();
      _codigoBarrasFocus.requestFocus();
    }
  }

  void _eliminarItem(int index) {
    setState(() {
      _carrito.removeAt(index);
    });
    _codigoBarrasFocus.requestFocus();
  }

  void _modificarCantidad(int index, int nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      _eliminarItem(index);
      return;
    }

    final producto = _carrito[index].producto;
    if (nuevaCantidad > producto.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Stock insuficiente (${producto.stock} disponibles)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _carrito[index].cantidad = nuevaCantidad;
    });
    _codigoBarrasFocus.requestFocus();
  }

  double get _subtotal => _carrito.fold(0, (sum, item) => sum + item.subtotal);
  double get _total => _subtotal - _descuentoGeneral;

  Future<void> _finalizarVenta() async {
    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ El carrito está vacío'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final venta = Venta(
        numeroVenta: '',
        fechaVenta: DateTime.now(),
        subtotal: _subtotal,
        descuento: _descuentoGeneral,
        total: _total,
        metodoPago: _metodoPago,
        fechaCreacion: DateTime.now(),
      );

      final detalles = _carrito.map((item) {
        return DetalleVenta(
          ventaId: 0,
          productoId: item.producto.id!,
          productoNombre: item.producto.nombre,
          cantidad: item.cantidad,
          precioUnitario: item.producto.precioVenta,
          descuento: item.descuento,
          subtotal: item.subtotal,
        );
      }).toList();

      final ventaId = await _ventasRepository.crearVenta(
        venta: venta,
        detalles: detalles,
      );

      if (mounted) {
        setState(() {
          _carrito.clear();
          _descuentoGeneral = 0;
          _metodoPago = MetodoPago.efectivo;
          _isProcessing = false;
          _multiplicadorProximo = 1;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Venta #$ventaId completada - Total: \$${_total.toStringAsFixed(2)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        _codigoBarrasFocus.requestFocus();
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al procesar venta: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _cancelarVenta() {
    if (_carrito.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Venta'),
        content: const Text('¿Deseas cancelar la venta actual?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _carrito.clear();
                _descuentoGeneral = 0;
                _metodoPago = MetodoPago.efectivo;
                _multiplicadorProximo = 1;
              });
              Navigator.pop(context);
              _codigoBarrasFocus.requestFocus();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return KeyboardListener(
      focusNode: FocusNode(), // Nodo para escuchar teclas globales en esta pantalla
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Punto de Venta'),
          actions: [
            IconButton(
              icon: const Icon(Icons.point_of_sale),
              onPressed: () async {
                final resultado = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CierreCajaScreen(caja: _cajaActual),
                  ),
                );
                if (resultado == true) {
                  // Caja cerrada, volver al menú principal
                  if (mounted) Navigator.pop(context);
                }
              },
              tooltip: 'Cerrar Caja',
            ),
            if (_carrito.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: _cancelarVenta,
                tooltip: 'Cancelar venta (F4)',
              ),
          ],
        ),
        body: Column(
          children: [
            // Campo de código de barras
            Container(
              padding: const EdgeInsets.all(16),
              color: _multiplicadorProximo > 1 ? Colors.blue.shade100 : Colors.blue.shade50,
              child: Column(
                children: [
                  if (_multiplicadorProximo > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.production_quantity_limits, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Multiplicador Activo: x$_multiplicadorProximo',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setState(() => _multiplicadorProximo = 1),
                            child: const Text('Cancelar'),
                          )
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      const Icon(Icons.qr_code_scanner, size: 32, color: Colors.blue),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _codigoBarrasController,
                          focusNode: _codigoBarrasFocus,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: 'Escanea, escribe código o "X" para cantidad...',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.search),
                          ),
                          onSubmitted: _procesarInput,
                          onChanged: _onSearchChanged,
                          onTapOutside: (_) => _codigoBarrasFocus.requestFocus(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _procesarInput(_codigoBarrasController.text),
                        icon: const Icon(Icons.check),
                        tooltip: 'Ingresar Manualmente',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Atajos: "X" Cantidad | F1: Cobrar | F4: Cancelar',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Carrito
            Expanded(
              child: _carrito.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Escanea productos para agregar al carrito',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _carrito.length,
                      itemBuilder: (context, index) {
                        final item = _carrito[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              item.producto.nombre,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${currencyFormat.format(item.producto.precioVenta)} x ${item.cantidad}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _modificarCantidad(index, item.cantidad - 1),
                                  color: Colors.red,
                                ),
                                Text(
                                  '${item.cantidad}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _modificarCantidad(index, item.cantidad + 1),
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    currencyFormat.format(item.subtotal),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _eliminarItem(index),
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Totales y Pago
            if (_carrito.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('Método de Pago:', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButton<MetodoPago>(
                            value: _metodoPago,
                            isExpanded: true,
                            items: MetodoPago.values.map((metodo) {
                              return DropdownMenuItem(
                                value: metodo,
                                child: Text(_getNombreMetodoPago(metodo)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _metodoPago = value!);
                              _codigoBarrasFocus.requestFocus();
                            },
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                        Text(
                          currencyFormat.format(_subtotal),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL:', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(
                          currencyFormat.format(_total),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _finalizarVenta,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle, size: 32),
                        label: Text(
                          _isProcessing ? 'Procesando...' : 'FINALIZAR VENTA (F1)',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getNombreMetodoPago(MetodoPago metodo) {
    switch (metodo) {
      case MetodoPago.efectivo: return 'Efectivo';
      case MetodoPago.tarjetaDebito: return 'Tarjeta Débito';
      case MetodoPago.tarjetaCredito: return 'Tarjeta Crédito';
      case MetodoPago.transferencia: return 'Transferencia';
      case MetodoPago.qr: return 'QR';
      case MetodoPago.vales: return 'Vales';
      case MetodoPago.mixto: return 'Mixto';
    }
  }

  @override
  void dispose() {
    _codigoBarrasController.dispose();
    _codigoBarrasFocus.dispose();
    super.dispose();
  }
}
