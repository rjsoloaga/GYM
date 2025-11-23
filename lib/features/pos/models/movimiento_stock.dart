import 'package:equatable/equatable.dart';

enum TipoMovimiento {
  entrada,
  salida,
  ajuste,
  venta,
  compra,
  devolucion,
  merma,
  transferencia,
}

class MovimientoStock extends Equatable {
  final int? id;
  final int productoId;
  final int? loteId;
  final TipoMovimiento tipo;
  final int cantidad;
  final int stockAnterior;
  final int stockNuevo;
  final String? motivo;
  final int? referenciaId;
  final String? referenciaTabla;
  final int? usuarioId;
  final DateTime fechaMovimiento;

  const MovimientoStock({
    this.id,
    required this.productoId,
    this.loteId,
    required this.tipo,
    required this.cantidad,
    required this.stockAnterior,
    required this.stockNuevo,
    this.motivo,
    this.referenciaId,
    this.referenciaTabla,
    this.usuarioId,
    required this.fechaMovimiento,
  });

  factory MovimientoStock.fromMap(Map<String, dynamic> map) {
    return MovimientoStock(
      id: map['id'] as int?,
      productoId: map['productoId'] as int,
      loteId: map['loteId'] as int?,
      tipo: _tipoFromString(map['tipo'] as String),
      cantidad: map['cantidad'] as int,
      stockAnterior: map['stockAnterior'] as int,
      stockNuevo: map['stockNuevo'] as int,
      motivo: map['motivo'] as String?,
      referenciaId: map['referenciaId'] as int?,
      referenciaTabla: map['referenciaTabla'] as String?,
      usuarioId: map['usuarioId'] as int?,
      fechaMovimiento: DateTime.parse(map['fechaMovimiento'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'productoId': productoId,
      'loteId': loteId,
      'tipo': _tipoToString(tipo),
      'cantidad': cantidad,
      'stockAnterior': stockAnterior,
      'stockNuevo': stockNuevo,
      'motivo': motivo,
      'referenciaId': referenciaId,
      'referenciaTabla': referenciaTabla,
      'usuarioId': usuarioId,
      'fechaMovimiento': fechaMovimiento.toIso8601String(),
    };
  }

  MovimientoStock copyWith({
    int? id,
    int? productoId,
    int? loteId,
    TipoMovimiento? tipo,
    int? cantidad,
    int? stockAnterior,
    int? stockNuevo,
    String? motivo,
    int? referenciaId,
    String? referenciaTabla,
    int? usuarioId,
    DateTime? fechaMovimiento,
  }) {
    return MovimientoStock(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      loteId: loteId ?? this.loteId,
      tipo: tipo ?? this.tipo,
      cantidad: cantidad ?? this.cantidad,
      stockAnterior: stockAnterior ?? this.stockAnterior,
      stockNuevo: stockNuevo ?? this.stockNuevo,
      motivo: motivo ?? this.motivo,
      referenciaId: referenciaId ?? this.referenciaId,
      referenciaTabla: referenciaTabla ?? this.referenciaTabla,
      usuarioId: usuarioId ?? this.usuarioId,
      fechaMovimiento: fechaMovimiento ?? this.fechaMovimiento,
    );
  }

  // Helpers para conversión de enums
  static TipoMovimiento _tipoFromString(String tipo) {
    switch (tipo) {
      case 'entrada':
        return TipoMovimiento.entrada;
      case 'salida':
        return TipoMovimiento.salida;
      case 'ajuste':
        return TipoMovimiento.ajuste;
      case 'venta':
        return TipoMovimiento.venta;
      case 'compra':
        return TipoMovimiento.compra;
      case 'devolucion':
        return TipoMovimiento.devolucion;
      case 'merma':
        return TipoMovimiento.merma;
      case 'transferencia':
        return TipoMovimiento.transferencia;
      default:
        return TipoMovimiento.ajuste;
    }
  }

  static String _tipoToString(TipoMovimiento tipo) {
    switch (tipo) {
      case TipoMovimiento.entrada:
        return 'entrada';
      case TipoMovimiento.salida:
        return 'salida';
      case TipoMovimiento.ajuste:
        return 'ajuste';
      case TipoMovimiento.venta:
        return 'venta';
      case TipoMovimiento.compra:
        return 'compra';
      case TipoMovimiento.devolucion:
        return 'devolucion';
      case TipoMovimiento.merma:
        return 'merma';
      case TipoMovimiento.transferencia:
        return 'transferencia';
    }
  }

  @override
  List<Object?> get props => [
        id,
        productoId,
        loteId,
        tipo,
        cantidad,
        stockAnterior,
        stockNuevo,
        motivo,
        referenciaId,
        referenciaTabla,
        usuarioId,
        fechaMovimiento,
      ];
}
