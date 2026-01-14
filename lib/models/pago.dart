class Pago {
  final int? id;
  final int socioId;
  final double monto;
  final DateTime fecha;
  final String metodoPago;
  final String? observaciones;

  Pago({
    this.id,
    required this.socioId,
    required this.monto,
    required this.fecha,
    required this.metodoPago,
    this.observaciones,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'socioId': socioId,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'metodoPago': metodoPago,
      'observaciones': observaciones,
    };
    if (id == null) {
      map.remove('id');
    }
    return map;
  }

  factory Pago.fromMap(Map<String, dynamic> map) {
    return Pago(
      id: map['id'],
      socioId: map['socioId'],
      monto: map['monto'],
      fecha: DateTime.parse(map['fecha']),
      metodoPago: map['metodoPago'],
      observaciones: map['observaciones'],
    );
  }
}
