import 'package:intl/intl.dart';
class Socio {
  final int? id;
  final String nombreCompleto;
  final String dni;
  final String telefono;
  final String email;
  final DateTime fechaInicio;
  final DateTime fechaVencimiento;
  final double precioMensual;
  final String tipoPlan; // Mantenido por compatibilidad
  final String? telegramChatId;
  final bool pendienteAprobacion;
  final DateTime? fechaRegistroTelegram;
  final int? usuarioId;
  final int? planId; // Nuevo campo para la relación con Plan

  Socio({
    this.id,
    required this.nombreCompleto,
    required this.dni,
    required this.telefono,
    required this.email,
    required this.fechaInicio,
    required this.fechaVencimiento,
    required this.precioMensual,
    required this.tipoPlan,
    this.telegramChatId,
    this.pendienteAprobacion = false,
    this.fechaRegistroTelegram,
    this.usuarioId,
    this.planId,
  });

  String get estadoCuota {
    final hoy = DateTime.now();
    final diasHastaVencimiento = fechaVencimiento.difference(hoy).inDays;

    if (diasHastaVencimiento > 7) { 
      return 'Al Día';
    } else if (diasHastaVencimiento >= 0) {
      return 'Por Vencer';
    } else {
      return 'Vencido';
    }
  }

  // NUEVO: Icono y color correctos para estado
  String get iconoEstado {
    final hoy = DateTime.now();
    final diasHastaVencimiento = fechaVencimiento.difference(hoy).inDays;

    if (diasHastaVencimiento > 7) { 
      return '✅'; // Icono check para "Al Día"
    } else if (diasHastaVencimiento >= 0) {
      return '⚠️'; // Icono advertencia para "Por Vencer"
    } else {
      return '❌'; // Icono error para "Vencido"
    }
  }

  // NUEVO: Color correcto para estado
  String get colorEstado {
    final hoy = DateTime.now();
    final diasHastaVencimiento = fechaVencimiento.difference(hoy).inDays;

    if (diasHastaVencimiento > 7) { 
      return 'verde'; // Verde para "Al Día"
    } else if (diasHastaVencimiento >= 0) {
      return 'naranja'; // Naranja para "Por Vencer"
    } else {
      return 'rojo'; // Rojo para "Vencido"
    }
  }

  bool get necesitaNotificacion {
    final hoy = DateTime.now();
    final diasHastaVencimiento = fechaVencimiento.difference(hoy).inDays;
    
    return (diasHastaVencimiento <= 7 && diasHastaVencimiento >= 0) || 
          diasHastaVencimiento < 0;
  }

  Socio copyWith({
    int? id,
    String? nombreCompleto,
    String? dni,
    String? telefono,
    String? email,
    DateTime? fechaInicio,
    DateTime? fechaVencimiento,
    double? precioMensual,
    String? tipoPlan,
    String? telegramChatId,
    bool? pendienteAprobacion,
    DateTime? fechaRegistroTelegram,
    int? usuarioId,
    int? planId,
  }) {
    return Socio(
      id: id ?? this.id,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      dni: dni ?? this.dni,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      precioMensual: precioMensual ?? this.precioMensual,
      tipoPlan: tipoPlan ?? this.tipoPlan,
      telegramChatId: telegramChatId ?? this.telegramChatId,
      pendienteAprobacion: pendienteAprobacion ?? this.pendienteAprobacion,
      fechaRegistroTelegram: fechaRegistroTelegram ?? this.fechaRegistroTelegram,
      usuarioId: usuarioId ?? this.usuarioId,
      planId: planId ?? this.planId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombreCompleto': nombreCompleto,
      'dni': dni,
      'telefono': telefono,
      'email': email,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaVencimiento': fechaVencimiento.toIso8601String(),
      'precioMensual': precioMensual,
      'tipoPlan': tipoPlan,
      'telegramChatId': telegramChatId,
      'pendienteAprobacion': pendienteAprobacion ? 1 : 0,
      'fechaRegistroTelegram': fechaRegistroTelegram?.toIso8601String(),
      'usuarioId': usuarioId,
      'planId': planId, // Nuevo campo
    };
  }

  factory Socio.fromMap(Map<String, dynamic> map) {
    return Socio(
      id: map['id'] as int?,
      nombreCompleto: map['nombreCompleto'] as String? ?? '',
      dni: map['dni'] as String? ?? '',
      telefono: map['telefono'] as String? ?? '',
      email: map['email'] as String? ?? '',
      fechaInicio: DateTime.parse(map['fechaInicio'] as String),
      fechaVencimiento: DateTime.parse(map['fechaVencimiento'] as String),
      precioMensual: (map['precioMensual'] as num?)?.toDouble() ?? 0.0,
      tipoPlan: map['tipoPlan'] as String? ?? 'Mensual',
      telegramChatId: map['telegramChatId'] as String?,
      pendienteAprobacion: (map['pendienteAprobacion'] as int?) == 1,
      fechaRegistroTelegram: map['fechaRegistroTelegram'] != null 
          ? DateTime.parse(map['fechaRegistroTelegram'] as String)
          : null,
      usuarioId: map['usuarioId'] as int?,
      planId: map['planId'] as int?,
    );
  }
}