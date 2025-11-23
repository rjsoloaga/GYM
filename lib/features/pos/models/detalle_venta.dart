import 'package:equatable/equatable.dart';

class DetalleVenta extends Equatable {
  final int? id;
  final int ventaId;
  final int productoId;
  final String productoNombre; // Guardamos el nombre por si el producto se elimina
  final int cantidad;
  final double precioUnitario;
  final double descuento;
  final double subtotal;
  final int? loteId;

  const DetalleVenta({
    this.id,
    required this.ventaId,
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.precioUnitario,
    this.descuento = 0,
    required this.subtotal,
    this.loteId,
  });

  factory DetalleVenta.fromMap(Map<String, dynamic> map) {
    return DetalleVenta(
      id: map['id'] as int?,
      ventaId: map['ventaId'] as int,
      productoId: map['productoId'] as int,
      productoNombre: map['productoNombre'] as String,
      cantidad: map['cantidad'] as int,
      precioUnitario: map['precioUnitario'] as double,
      descuento: (map['descuento'] as num?)?.toDouble() ?? 0,
      subtotal: map['subtotal'] as double,
      loteId: map['loteId'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'ventaId': ventaId,
      'productoId': productoId,
      'productoNombre': productoNombre,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
      'descuento': descuento,
      'subtotal': subtotal,
      'loteId': loteId,
    };
  }

  DetalleVenta copyWith({
    int? id,
    int? ventaId,
    int? productoId,
    String? productoNombre,
    int? cantidad,
    double? precioUnitario,
    double? descuento,
    double? subtotal,
    int? loteId,
  }) {
    return DetalleVenta(
      id: id ?? this.id,
      ventaId: ventaId ?? this.ventaId,
      productoId: productoId ?? this.productoId,
      productoNombre: productoNombre ?? this.productoNombre,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      descuento: descuento ?? this.descuento,
      subtotal: subtotal ?? this.subtotal,
      loteId: loteId ?? this.loteId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ventaId,
        productoId,
        productoNombre,
        cantidad,
        precioUnitario,
        descuento,
        subtotal,
        loteId,
      ];
}
