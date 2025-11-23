class CajaSesion {
  final int? id;
  final int usuarioId;
  final DateTime fechaApertura;
  final DateTime? fechaCierre;
  final double montoInicial;
  final double? montoFinalEsperado;
  final double? montoFinalReal;
  final double? diferencia;
  final String estado; // 'abierta', 'cerrada'
  final String? notas;

  CajaSesion({
    this.id,
    required this.usuarioId,
    required this.fechaApertura,
    this.fechaCierre,
    required this.montoInicial,
    this.montoFinalEsperado,
    this.montoFinalReal,
    this.diferencia,
    required this.estado,
    this.notas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'fechaApertura': fechaApertura.toIso8601String(),
      'fechaCierre': fechaCierre?.toIso8601String(),
      'montoInicial': montoInicial,
      'montoFinalEsperado': montoFinalEsperado,
      'montoFinalReal': montoFinalReal,
      'diferencia': diferencia,
      'estado': estado,
      'notas': notas,
    };
  }

  factory CajaSesion.fromMap(Map<String, dynamic> map) {
    return CajaSesion(
      id: map['id'],
      usuarioId: map['usuarioId'],
      fechaApertura: DateTime.parse(map['fechaApertura']),
      fechaCierre: map['fechaCierre'] != null ? DateTime.parse(map['fechaCierre']) : null,
      montoInicial: (map['montoInicial'] as num).toDouble(),
      montoFinalEsperado: (map['montoFinalEsperado'] as num?)?.toDouble(),
      montoFinalReal: (map['montoFinalReal'] as num?)?.toDouble(),
      diferencia: (map['diferencia'] as num?)?.toDouble(),
      estado: map['estado'],
      notas: map['notas'],
    );
  }
}
