import 'package:equatable/equatable.dart';

enum TipoAlerta {
  stockBajo,
  stockCritico,
  vencimientoProximo,
  vencimientoCritico,
  productoVencido,
}

enum PrioridadAlerta {
  baja,
  media,
  alta,
  critica,
}

class AlertaInventario extends Equatable {
  final int? id;
  final TipoAlerta tipo;
  final int? productoId;
  final int? loteId;
  final String mensaje;
  final PrioridadAlerta prioridad;
  final bool leida;
  final DateTime fechaCreacion;
  final DateTime? fechaVencimiento;

  const AlertaInventario({
    this.id,
    required this.tipo,
    this.productoId,
    this.loteId,
    required this.mensaje,
    this.prioridad = PrioridadAlerta.media,
    this.leida = false,
    required this.fechaCreacion,
    this.fechaVencimiento,
  });

  factory AlertaInventario.fromMap(Map<String, dynamic> map) {
    return AlertaInventario(
      id: map['id'] as int?,
      tipo: _tipoFromString(map['tipo'] as String),
      productoId: map['productoId'] as int?,
      loteId: map['loteId'] as int?,
      mensaje: map['mensaje'] as String,
      prioridad: _prioridadFromString(map['prioridad'] as String? ?? 'media'),
      leida: (map['leida'] as int?) == 1,
      fechaCreacion: DateTime.parse(map['fechaCreacion'] as String),
      fechaVencimiento: map['fechaVencimiento'] != null
          ? DateTime.parse(map['fechaVencimiento'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tipo': _tipoToString(tipo),
      'productoId': productoId,
      'loteId': loteId,
      'mensaje': mensaje,
      'prioridad': _prioridadToString(prioridad),
      'leida': leida ? 1 : 0,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaVencimiento': fechaVencimiento?.toIso8601String(),
    };
  }

  AlertaInventario copyWith({
    int? id,
    TipoAlerta? tipo,
    int? productoId,
    int? loteId,
    String? mensaje,
    PrioridadAlerta? prioridad,
    bool? leida,
    DateTime? fechaCreacion,
    DateTime? fechaVencimiento,
  }) {
    return AlertaInventario(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      productoId: productoId ?? this.productoId,
      loteId: loteId ?? this.loteId,
      mensaje: mensaje ?? this.mensaje,
      prioridad: prioridad ?? this.prioridad,
      leida: leida ?? this.leida,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
    );
  }

  // Helpers para conversión de enums
  static TipoAlerta _tipoFromString(String tipo) {
    switch (tipo) {
      case 'stock_bajo':
        return TipoAlerta.stockBajo;
      case 'stock_critico':
        return TipoAlerta.stockCritico;
      case 'vencimiento_proximo':
        return TipoAlerta.vencimientoProximo;
      case 'vencimiento_critico':
        return TipoAlerta.vencimientoCritico;
      case 'producto_vencido':
        return TipoAlerta.productoVencido;
      default:
        return TipoAlerta.stockBajo;
    }
  }

  static String _tipoToString(TipoAlerta tipo) {
    switch (tipo) {
      case TipoAlerta.stockBajo:
        return 'stock_bajo';
      case TipoAlerta.stockCritico:
        return 'stock_critico';
      case TipoAlerta.vencimientoProximo:
        return 'vencimiento_proximo';
      case TipoAlerta.vencimientoCritico:
        return 'vencimiento_critico';
      case TipoAlerta.productoVencido:
        return 'producto_vencido';
    }
  }

  static PrioridadAlerta _prioridadFromString(String prioridad) {
    switch (prioridad) {
      case 'baja':
        return PrioridadAlerta.baja;
      case 'media':
        return PrioridadAlerta.media;
      case 'alta':
        return PrioridadAlerta.alta;
      case 'critica':
        return PrioridadAlerta.critica;
      default:
        return PrioridadAlerta.media;
    }
  }

  static String _prioridadToString(PrioridadAlerta prioridad) {
    switch (prioridad) {
      case PrioridadAlerta.baja:
        return 'baja';
      case PrioridadAlerta.media:
        return 'media';
      case PrioridadAlerta.alta:
        return 'alta';
      case PrioridadAlerta.critica:
        return 'critica';
    }
  }

  @override
  List<Object?> get props => [
        id,
        tipo,
        productoId,
        loteId,
        mensaje,
        prioridad,
        leida,
        fechaCreacion,
        fechaVencimiento,
      ];
}
