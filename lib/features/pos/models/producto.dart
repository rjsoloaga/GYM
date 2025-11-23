import 'package:equatable/equatable.dart';

class Producto extends Equatable {
  final int? id;
  final String? codigo;
  final String? codigoBarras;
  final String nombre;
  final String? descripcion;
  final int categoriaId;
  final String? marca;
  final int? proveedorId;
  final double precioCompra;
  final double precioVenta;
  final double? margenGanancia;
  final int stock;
  final int stockMinimo;
  final int? stockMaximo;
  final String unidadMedida;
  final double? pesoNeto;
  final String? imagenUrl;
  final bool requiereVencimiento;
  final bool activo;
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;

  const Producto({
    this.id,
    this.codigo,
    this.codigoBarras,
    required this.nombre,
    this.descripcion,
    required this.categoriaId,
    this.marca,
    this.proveedorId,
    this.precioCompra = 0,
    required this.precioVenta,
    this.margenGanancia,
    this.stock = 0,
    this.stockMinimo = 5,
    this.stockMaximo,
    this.unidadMedida = 'unidad',
    this.pesoNeto,
    this.imagenUrl,
    this.requiereVencimiento = false,
    this.activo = true,
    required this.fechaCreacion,
    this.fechaActualizacion,
  });

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] as int?,
      codigo: map['codigo'] as String?,
      codigoBarras: map['codigoBarras'] as String?,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      categoriaId: map['categoriaId'] as int,
      marca: map['marca'] as String?,
      proveedorId: map['proveedorId'] as int?,
      precioCompra: (map['precioCompra'] as num?)?.toDouble() ?? 0,
      precioVenta: (map['precioVenta'] as num).toDouble(),
      margenGanancia: (map['margenGanancia'] as num?)?.toDouble(),
      stock: (map['stock'] as int?) ?? 0,
      stockMinimo: (map['stockMinimo'] as int?) ?? 5,
      stockMaximo: map['stockMaximo'] as int?,
      unidadMedida: (map['unidadMedida'] as String?) ?? 'unidad',
      pesoNeto: (map['pesoNeto'] as num?)?.toDouble(),
      imagenUrl: map['imagenUrl'] as String?,
      requiereVencimiento: (map['requiereVencimiento'] as int?) == 1,
      activo: (map['activo'] as int?) == 1,
      fechaCreacion: DateTime.parse(map['fechaCreacion'] as String),
      fechaActualizacion: map['fechaActualizacion'] != null
          ? DateTime.parse(map['fechaActualizacion'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'codigo': codigo,
      'codigoBarras': codigoBarras,
      'nombre': nombre,
      'descripcion': descripcion,
      'categoriaId': categoriaId,
      'marca': marca,
      'proveedorId': proveedorId,
      'precioCompra': precioCompra,
      'precioVenta': precioVenta,
      'margenGanancia': margenGanancia,
      'stock': stock,
      'stockMinimo': stockMinimo,
      'stockMaximo': stockMaximo,
      'unidadMedida': unidadMedida,
      'pesoNeto': pesoNeto,
      'imagenUrl': imagenUrl,
      'requiereVencimiento': requiereVencimiento ? 1 : 0,
      'activo': activo ? 1 : 0,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion?.toIso8601String(),
    };
  }

  Producto copyWith({
    int? id,
    String? codigo,
    String? codigoBarras,
    String? nombre,
    String? descripcion,
    int? categoriaId,
    String? marca,
    int? proveedorId,
    double? precioCompra,
    double? precioVenta,
    double? margenGanancia,
    int? stock,
    int? stockMinimo,
    int? stockMaximo,
    String? unidadMedida,
    double? pesoNeto,
    String? imagenUrl,
    bool? requiereVencimiento,
    bool? activo,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return Producto(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      categoriaId: categoriaId ?? this.categoriaId,
      marca: marca ?? this.marca,
      proveedorId: proveedorId ?? this.proveedorId,
      precioCompra: precioCompra ?? this.precioCompra,
      precioVenta: precioVenta ?? this.precioVenta,
      margenGanancia: margenGanancia ?? this.margenGanancia,
      stock: stock ?? this.stock,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      stockMaximo: stockMaximo ?? this.stockMaximo,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      pesoNeto: pesoNeto ?? this.pesoNeto,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      requiereVencimiento: requiereVencimiento ?? this.requiereVencimiento,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  // Calcular margen de ganancia
  double calcularMargen() {
    if (precioCompra == 0) return 0;
    return ((precioVenta - precioCompra) / precioCompra) * 100;
  }

  // Verificar si está bajo stock
  bool get bajStock => stock <= stockMinimo;

  // Verificar si está en stock crítico (50% del mínimo)
  bool get stockCritico => stock <= (stockMinimo * 0.5);

  @override
  List<Object?> get props => [
        id,
        codigo,
        codigoBarras,
        nombre,
        descripcion,
        categoriaId,
        marca,
        proveedorId,
        precioCompra,
        precioVenta,
        margenGanancia,
        stock,
        stockMinimo,
        stockMaximo,
        unidadMedida,
        pesoNeto,
        imagenUrl,
        requiereVencimiento,
        activo,
        fechaCreacion,
        fechaActualizacion,
      ];
}
