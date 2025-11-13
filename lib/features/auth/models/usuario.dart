class Usuario {
  final int? id;
  final String nombreCompleto;
  final String email;
  final String telefono;
  final String dni;
  final String rol; // 'admin', 'operador', 'socio'
  final DateTime fechaCreacion;
  final bool activo;
  final String? telegramChatId;

  Usuario({
    this.id,
    required this.nombreCompleto,
    required this.email,
    required this.telefono,
    required this.dni,
    required this.rol,
    required this.fechaCreacion,
    this.activo = true,
    this.telegramChatId,
  });

  bool get esAdmin => rol == 'admin';
  bool get esOperador => rol == 'operador';
  bool get esSocio => rol == 'socio';

  Usuario copyWith({
    int? id,
    String? nombreCompleto,
    String? email,
    String? telefono,
    String? dni,
    String? rol,
    DateTime? fechaCreacion,
    bool? activo,
    String? telegramChatId,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      dni: dni ?? this.dni,
      rol: rol ?? this.rol,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      activo: activo ?? this.activo,
      telegramChatId: telegramChatId ?? this.telegramChatId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombreCompleto': nombreCompleto,
      'email': email,
      'telefono': telefono,
      'dni': dni,
      'rol': rol,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'activo': activo ? 1 : 0,
      'telegramChatId': telegramChatId,
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as int?,
      nombreCompleto: map['nombreCompleto'] as String? ?? '',
      email: map['email'] as String? ?? '',
      telefono: map['telefono'] as String? ?? '',
      dni: map['dni'] as String? ?? '',
      rol: map['rol'] as String? ?? 'socio',
      fechaCreacion: DateTime.parse(map['fechaCreacion'] as String),
      activo: (map['activo'] as int?) == 1,
      telegramChatId: map['telegramChatId'] as String?,
    );
  }
}