import 'package:equatable/equatable.dart';

class LoteProducto extends Equatable {
  final int? id;
  final int productoId;
  final String numeroLote;
  final DateTime? fechaVencimiento;
  final int stockLote;
  final double? precioCompraLote;
  final DateTime fechaIngreso;
  final int? proveedorId;
  final String? notas;

  const LoteProducto({
    this.id,
    required this.productoId,
    required this.numeroLote,
    this.fechaVencimiento,
    this.stockLote = 0,
    this.precioCompraLote,
    required this.fechaIngreso,
    this.proveedorId,
    this.notas,
  });

  factory LoteProducto.fromMap(Map<String, dynamic> map) {
    return LoteProducto(
      id: map['id'] as int?,
      productoId: map['productoId'] as int,
      numeroLote: map['numeroLote'] as String,
      fechaVencimiento: map['fechaVencimiento'] != null
          ? DateTime.parse(map['fechaVencimiento'] as String)
          : null,
      stockLote: (map['stockLote'] as int?) ?? 0,
      precioCompraLote: (map['precioCompraLote'] as num?)?.toDouble(),
      fechaIngreso: DateTime.parse(map['fechaIngreso'] as String),
      proveedorId: map['proveedorId'] as int?,
      notas: map['notas'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'productoId': productoId,
      'numeroLote': numeroLote,
      'fechaVencimiento': fechaVencimiento?.toIso8601String(),
      'stockLote': stockLote,
      'precioCompraLote': precioCompraLote,
      'fechaIngreso': fechaIngreso.toIso8601String(),
      'proveedorId': proveedorId,
      'notas': notas,
    };
  }

  LoteProducto copyWith({
    int? id,
    int? productoId,
    String? numeroLote,
    DateTime? fechaVencimiento,
    int? stockLote,
    double? precioCompraLote,
    DateTime? fechaIngreso,
    int? proveedorId,
    String? notas,
  }) {
    return LoteProducto(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      numeroLote: numeroLote ?? this.numeroLote,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      stockLote: stockLote ?? this.stockLote,
      precioCompraLote: precioCompraLote ?? this.precioCompraLote,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      proveedorId: proveedorId ?? this.proveedorId,
      notas: notas ?? this.notas,
    );
  }

  // Verificar si está vencido
  bool get estaVencido {
    if (fechaVencimiento == null) return false;
    return DateTime.now().isAfter(fechaVencimiento!);
  }

  // Verificar si vence pronto (menos de 30 días)
  bool get venceProximo {
    if (fechaVencimiento == null) return false;
    final diasRestantes = fechaVencimiento!.difference(DateTime.now()).inDays;
    return diasRestantes > 0 && diasRestantes <= 30;
  }

  // Verificar si vence muy pronto (menos de 7 días)
  bool get venceCritico {
    if (fechaVencimiento == null) return false;
    final diasRestantes = fechaVencimiento!.difference(DateTime.now()).inDays;
    return diasRestantes > 0 && diasRestantes <= 7;
  }

  // Días restantes hasta vencimiento
  int? get diasHastaVencimiento {
    if (fechaVencimiento == null) return null;
    return fechaVencimiento!.difference(DateTime.now()).inDays;
  }

  @override
  List<Object?> get props => [
        id,
        productoId,
        numeroLote,
        fechaVencimiento,
        stockLote,
        precioCompraLote,
        fechaIngreso,
        proveedorId,
        notas,
      ];
}
