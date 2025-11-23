import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym/features/pos/models/producto.dart';
import 'package:gym/features/pos/models/categoria_producto.dart';
import 'package:gym/features/pos/models/proveedor.dart';
import 'package:gym/features/pos/services/productos_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/features/socios/bloc/auth_bloc.dart';

class ProductoFormScreen extends StatefulWidget {
  final Producto? producto;

  const ProductoFormScreen({super.key, this.producto});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductosRepository _repository = ProductosRepository();

  // Controllers
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _codigoController = TextEditingController();
  final _codigoBarrasController = TextEditingController();
  final _marcaController = TextEditingController();
  final _precioCompraController = TextEditingController();
  final _precioVentaController = TextEditingController();
  final _stockController = TextEditingController();
  final _stockMinimoController = TextEditingController();
  final _stockMaximoController = TextEditingController();
  final _pesoNetoController = TextEditingController();
  final _fechaVencimientoController = TextEditingController();
  DateTime? _fechaVencimientoInicial;

  // Dropdowns
  List<CategoriaProducto> _categorias = [];
  List<Proveedor> _proveedores = [];
  int? _categoriaSeleccionada;
  int? _proveedorSeleccionado;
  String _unidadMedida = 'unidad';
  bool _requiereVencimiento = false;
  bool _mostrarDetallesPeso = false;
  bool _activo = true;
  bool _isLoading = false;

  final List<String> _unidadesMedida = [
    'unidad',
    'kg',
    'gramo',
    'litro',
    'ml',
    'caja',
    'paquete',
  ];

  bool _esAdmin = false; // Determinado en initState

  @override
  void initState() {
    super.initState();
    // Determinar rol del usuario autenticado
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticatedState) {
      _esAdmin = authState.user['rol'] == 'admin';
    } else if (authState is AuthSuccess) {
      _esAdmin = authState.usuario['rol'] == 'admin';
    }
    _cargarDatos();
    if (widget.producto != null) {
      _cargarProductoExistente();
    }
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final categorias = await _repository.obtenerCategorias();
      final proveedores = await _repository.obtenerProveedores();
      setState(() {
        _categorias = categorias;
        _proveedores = proveedores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _cargarProductoExistente() {
    final producto = widget.producto!;
    _nombreController.text = producto.nombre;
    _descripcionController.text = producto.descripcion ?? '';
    _codigoController.text = producto.codigo ?? '';
    _codigoBarrasController.text = producto.codigoBarras ?? '';
    _marcaController.text = producto.marca ?? '';
    _precioCompraController.text = producto.precioCompra.toString();
    _precioVentaController.text = producto.precioVenta.toString();
    _stockController.text = producto.stock.toString();
    _stockMinimoController.text = producto.stockMinimo.toString();
    _stockMaximoController.text = producto.stockMaximo?.toString() ?? '';
    _pesoNetoController.text = producto.pesoNeto?.toString() ?? '';
    _categoriaSeleccionada = producto.categoriaId;
    _proveedorSeleccionado = producto.proveedorId;
    _unidadMedida = producto.unidadMedida;
    _requiereVencimiento = producto.requiereVencimiento;
    _activo = producto.activo;
    _mostrarDetallesPeso = _unidadMedida != 'unidad' || (producto.pesoNeto != null);
  }

  void _calcularPrecioVenta() {
    final precioCompra = double.tryParse(_precioCompraController.text) ?? 0;
    if (precioCompra > 0) {
      // Sugerir un margen del 30% por defecto
      final precioSugerido = precioCompra * 1.3;
      _precioVentaController.text = precioSugerido.toStringAsFixed(2);
    }
  }

  double _calcularMargen() {
    final precioCompra = double.tryParse(_precioCompraController.text) ?? 0;
    final precioVenta = double.tryParse(_precioVentaController.text) ?? 0;
    if (precioCompra == 0) return 0;
    return ((precioVenta - precioCompra) / precioCompra) * 100;
  }

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar una categoría'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final producto = Producto(
        id: widget.producto?.id,
        codigo: _codigoController.text.trim().isEmpty ? null : _codigoController.text.trim(),
        codigoBarras: _codigoBarrasController.text.trim().isEmpty ? null : _codigoBarrasController.text.trim(),
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
        categoriaId: _categoriaSeleccionada!,
        marca: _marcaController.text.trim().isEmpty ? null : _marcaController.text.trim(),
        proveedorId: _proveedorSeleccionado,
        precioCompra: double.tryParse(_precioCompraController.text) ?? 0,
        precioVenta: double.parse(_precioVentaController.text),
        stock: int.tryParse(_stockController.text) ?? 0,
        stockMinimo: int.tryParse(_stockMinimoController.text) ?? 5,
        stockMaximo: _stockMaximoController.text.isEmpty ? null : int.tryParse(_stockMaximoController.text),
        unidadMedida: _unidadMedida,
        pesoNeto: _pesoNetoController.text.isEmpty ? null : double.tryParse(_pesoNetoController.text),
        requiereVencimiento: _requiereVencimiento,
        activo: _activo,
        fechaCreacion: widget.producto?.fechaCreacion ?? DateTime.now(),
      );

      // Guardar producto con control de permisos
      if (widget.producto == null) {
        await _repository.crear(
          producto,
          isAdmin: _esAdmin,
          fechaVencimientoInicial: _fechaVencimientoInicial,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Producto creado correctamente'), backgroundColor: Colors.green),
          );
        }
      } else {
        await _repository.actualizar(
          producto,
          isAdmin: _esAdmin,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Producto actualizado correctamente'), backgroundColor: Colors.green),
          );
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error guardando producto: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final margen = _calcularMargen();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.producto == null ? 'Nuevo Producto' : 'Editar Producto'),
        actions: [
          if (widget.producto != null)
            IconButton(
              icon: Icon(_activo ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() => _activo = !_activo);
              },
              tooltip: _activo ? 'Producto activo' : 'Producto inactivo',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Información Básica
                  _buildSectionTitle('Información Básica'),
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Producto *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _codigoController,
                          decoration: const InputDecoration(
                            labelText: 'Código Interno',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.qr_code),
                            hintText: 'Auto-generado',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _codigoBarrasController,
                          decoration: const InputDecoration(
                            labelText: 'Código de Barras',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.barcode_reader),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Categorización
                  _buildSectionTitle('Categorización'),
                  DropdownButtonFormField<int>(
                    value: _categoriaSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Categoría *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _categorias.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.nombre),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _categoriaSeleccionada = value);
                    },
                    validator: (value) => value == null ? 'Debe seleccionar una categoría' : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _marcaController,
                          decoration: const InputDecoration(
                            labelText: 'Marca',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.branding_watermark),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _proveedorSeleccionado,
                          decoration: const InputDecoration(
                            labelText: 'Proveedor',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.local_shipping),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Sin proveedor')),
                            ..._proveedores.map((prov) {
                              return DropdownMenuItem(
                                value: prov.id,
                                child: Text(prov.nombre),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() => _proveedorSeleccionado = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Precios
                  _buildSectionTitle('Precios'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _precioCompraController,
                          enabled: _esAdmin,
                          decoration: const InputDecoration(
                            labelText: 'Precio de Compra',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.shopping_cart),
                            prefixText: '\$ ',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.calculate),
                        onPressed: _calcularPrecioVenta,
                        tooltip: 'Calcular precio de venta (+30%)',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _precioVentaController,
                          enabled: _esAdmin,
                          decoration: InputDecoration(
                            labelText: 'Precio de Venta *',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.attach_money),
                            prefixText: '\$ ',
                            suffixIcon: margen > 0
                                ? Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '+${margen.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          color: Colors.green.shade900,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Campo requerido';
                            if (double.tryParse(value!) == null) return 'Valor inválido';
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Inventario
                  _buildSectionTitle('Inventario'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          enabled: _esAdmin,
                          decoration: const InputDecoration(
                            labelText: 'Stock Actual',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stockMinimoController,
                          decoration: const InputDecoration(
                            labelText: 'Stock Mínimo',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.warning_amber),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _stockMaximoController,
                          decoration: const InputDecoration(
                            labelText: 'Stock Máximo',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.trending_up),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const SizedBox(height: 16),
                  
                  // Opciones Avanzadas (Peso/Unidad)
                  SwitchListTile(
                    title: const Text('Habilitar detalles de peso/medida'),
                    subtitle: const Text('Para venta fraccionada o control de peso'),
                    value: _mostrarDetallesPeso,
                    onChanged: (val) {
                      setState(() {
                        _mostrarDetallesPeso = val;
                        if (!val) {
                          _unidadMedida = 'unidad';
                          _pesoNetoController.clear();
                        }
                      });
                    },
                  ),
                  
                  if (_mostrarDetallesPeso) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _unidadMedida,
                              decoration: const InputDecoration(
                                labelText: 'Unidad de Medida',
                                border: OutlineInputBorder(),
                              ),
                              items: _unidadesMedida.map((unidad) {
                                return DropdownMenuItem(
                                  value: unidad,
                                  child: Text(unidad),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _unidadMedida = value!);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _pesoNetoController,
                              decoration: const InputDecoration(
                                labelText: 'Peso Neto',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.scale),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Opciones
                  _buildSectionTitle('Opciones'),
                  SwitchListTile(
                    title: const Text('Requiere control de vencimiento'),
                    subtitle: const Text('Activar para productos con fecha de vencimiento'),
                    value: _requiereVencimiento,
                    onChanged: (value) {
                      setState(() => _requiereVencimiento = value);
                    },
                    secondary: const Icon(Icons.event_busy),
                  ),

                  if (_requiereVencimiento && widget.producto == null) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fechaVencimientoController,
                      decoration: const InputDecoration(
                        labelText: 'Fecha de Vencimiento Inicial',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                        helperText: 'Se creará un lote inicial con esta fecha',
                      ),
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) {
                          setState(() {
                            _fechaVencimientoInicial = picked;
                            _fechaVencimientoController.text = "${picked.day}/${picked.month}/${picked.year}";
                          });
                        }
                      },
                      validator: (value) {
                        if (_requiereVencimiento && (value == null || value.isEmpty)) {
                          return 'Requerido para el lote inicial';
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _guardarProducto,
                          icon: const Icon(Icons.save),
                          label: Text(widget.producto == null ? 'Crear Producto' : 'Guardar Cambios'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _codigoController.dispose();
    _codigoBarrasController.dispose();
    _marcaController.dispose();
    _precioCompraController.dispose();
    _precioVentaController.dispose();
    _stockController.dispose();
    _stockMinimoController.dispose();
    _stockMaximoController.dispose();
    _pesoNetoController.dispose();
    _fechaVencimientoController.dispose();
    super.dispose();
  }
}
