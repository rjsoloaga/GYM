import 'package:gym/features/socios/models/socio.dart';

class PlantillaNotificacion {
  final int? id;
  final String nombre;
  final String mensaje;
  final int diasAntes;
  final bool activa;
  final DateTime fechaCreacion;

  const PlantillaNotificacion({
    this.id,
    required this.nombre,
    required this.mensaje,
    required this.diasAntes,
    this.activa = true,
    required this.fechaCreacion,
  });

  // Variables disponibles para las plantillas
  static const variablesDisponibles = {
    '{nombre}': 'Nombre del socio',
    '{dias_restantes}': 'Días hasta el vencimiento', 
    '{dias_vencidos}': 'Días vencidos (si aplica)',
    '{fecha_vencimiento}': 'Fecha de vencimiento',
    '{plan}': 'Tipo de plan',
    '{precio}': 'Precio mensual',
  };

  String aplicarVariables(Socio socio) {
    final hoy = DateTime.now();
    final diasHastaVencimiento = socio.fechaVencimiento.difference(hoy).inDays;
    final diasVencidos = diasHastaVencimiento < 0 ? diasHastaVencimiento.abs() : 0;

    return mensaje
        .replaceAll('{nombre}', socio.nombreCompleto)
        .replaceAll('{dias_restantes}', diasHastaVencimiento.toString())
        .replaceAll('{dias_vencidos}', diasVencidos.toString())
        .replaceAll('{fecha_vencimiento}', _formatearFecha(socio.fechaVencimiento))
        .replaceAll('{plan}', socio.tipoPlan)
        .replaceAll('{precio}', socio.precioMensual.toStringAsFixed(2));
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  PlantillaNotificacion copyWith({
    int? id,
    String? nombre,
    String? mensaje,
    int? diasAntes,
    bool? activa,
    DateTime? fechaCreacion,
  }) {
    return PlantillaNotificacion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      mensaje: mensaje ?? this.mensaje,
      diasAntes: diasAntes ?? this.diasAntes,
      activa: activa ?? this.activa,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'mensaje': mensaje,
      'diasAntes': diasAntes,
      'activa': activa ? 1 : 0,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  factory PlantillaNotificacion.fromMap(Map<String, dynamic> map) {
    return PlantillaNotificacion(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      mensaje: map['mensaje'] as String,
      diasAntes: map['diasAntes'] as int,
      activa: (map['activa'] as int?) == 1,
      fechaCreacion: DateTime.parse(map['fechaCreacion'] as String),
    );
  }
}