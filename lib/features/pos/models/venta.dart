import 'package:equatable/equatable.dart';

enum EstadoVenta {
  pendiente,
  completada,
  cancelada,
  devuelta,
}

enum MetodoPago {
  efectivo,
  tarjetaDebito,
  tarjetaCredito,
  transferencia,
  qr,
  vales,
  mixto,
}

class Venta extends Equatable {
  final int? id;
  final String numeroVenta;
  final DateTime fechaVenta;
  final int? socioId; // Opcional, puede ser venta sin socio
  final double subtotal;
  final double descuento;
  final double total;
  final EstadoVenta estado;
  final MetodoPago metodoPago;
  final String? observaciones;
  final int? usuarioId;
  final DateTime fechaCreacion;

  const Venta({
    this.id,
    required this.numeroVenta,
    required this.fechaVenta,
    this.socioId,
    required this.subtotal,
    this.descuento = 0,
    required this.total,
    this.estado = EstadoVenta.completada,
    required this.metodoPago,
    this.observaciones,
    this.usuarioId,
    required this.fechaCreacion,
  });

  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id'] as int?,
      numeroVenta: map['numeroVenta'] as String,
      fechaVenta: DateTime.parse(map['fechaVenta'] as String),
      socioId: map['socioId'] as int?,
      subtotal: map['subtotal'] as double,
      descuento: (map['descuento'] as num?)?.toDouble() ?? 0,
      total: map['total'] as double,
      estado: _estadoFromString(map['estado'] as String),
      metodoPago: _metodoPagoFromString(map['metodoPago'] as String),
      observaciones: map['observaciones'] as String?,
      usuarioId: map['usuarioId'] as int?,
      fechaCreacion: DateTime.parse(map['fechaCreacion'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'numeroVenta': numeroVenta,
      'fechaVenta': fechaVenta.toIso8601String(),
      'socioId': socioId,
      'subtotal': subtotal,
      'descuento': descuento,
      'total': total,
      'estado': _estadoToString(estado),
      'metodoPago': _metodoPagoToString(metodoPago),
      'observaciones': observaciones,
      'usuarioId': usuarioId,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  Venta copyWith({
    int? id,
    String? numeroVenta,
    DateTime? fechaVenta,
    int? socioId,
    double? subtotal,
    double? descuento,
    double? total,
    EstadoVenta? estado,
    MetodoPago? metodoPago,
    String? observaciones,
    int? usuarioId,
    DateTime? fechaCreacion,
  }) {
    return Venta(
      id: id ?? this.id,
      numeroVenta: numeroVenta ?? this.numeroVenta,
      fechaVenta: fechaVenta ?? this.fechaVenta,
      socioId: socioId ?? this.socioId,
      subtotal: subtotal ?? this.subtotal,
      descuento: descuento ?? this.descuento,
      total: total ?? this.total,
      estado: estado ?? this.estado,
      metodoPago: metodoPago ?? this.metodoPago,
      observaciones: observaciones ?? this.observaciones,
      usuarioId: usuarioId ?? this.usuarioId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  // Helpers para conversión de enums
  static EstadoVenta _estadoFromString(String estado) {
    switch (estado) {
      case 'pendiente':
        return EstadoVenta.pendiente;
      case 'completada':
        return EstadoVenta.completada;
      case 'cancelada':
        return EstadoVenta.cancelada;
      case 'devuelta':
        return EstadoVenta.devuelta;
      default:
        return EstadoVenta.completada;
    }
  }

  static String _estadoToString(EstadoVenta estado) {
    switch (estado) {
      case EstadoVenta.pendiente:
        return 'pendiente';
      case EstadoVenta.completada:
        return 'completada';
      case EstadoVenta.cancelada:
        return 'cancelada';
      case EstadoVenta.devuelta:
        return 'devuelta';
    }
  }

  static MetodoPago _metodoPagoFromString(String metodo) {
    switch (metodo) {
      case 'efectivo':
        return MetodoPago.efectivo;
      case 'tarjeta_debito':
        return MetodoPago.tarjetaDebito;
      case 'tarjeta_credito':
        return MetodoPago.tarjetaCredito;
      case 'transferencia':
        return MetodoPago.transferencia;
      case 'qr':
        return MetodoPago.qr;
      case 'vales':
        return MetodoPago.vales;
      case 'mixto':
        return MetodoPago.mixto;
      default:
        return MetodoPago.efectivo;
    }
  }

  static String _metodoPagoToString(MetodoPago metodo) {
    switch (metodo) {
      case MetodoPago.efectivo:
        return 'efectivo';
      case MetodoPago.tarjetaDebito:
        return 'tarjeta_debito';
      case MetodoPago.tarjetaCredito:
        return 'tarjeta_credito';
      case MetodoPago.transferencia:
        return 'transferencia';
      case MetodoPago.qr:
        return 'qr';
      case MetodoPago.vales:
        return 'vales';
      case MetodoPago.mixto:
        return 'mixto';
    }
  }

  @override
  List<Object?> get props => [
        id,
        numeroVenta,
        fechaVenta,
        socioId,
        subtotal,
        descuento,
        total,
        estado,
        metodoPago,
        observaciones,
        usuarioId,
        fechaCreacion,
      ];
}
