import 'package:gym/features/rutinas/models/ejercicio.dart';

class RutinaEjercicio {
  final int? id;
  final int? rutinaId;
  final int ejercicioId;
  final int orden;
  final int? series;
  final int? repeticiones;
  final int? descansoSegundos;
  final String? notas;
  
  // Objeto ejercicio completo (para UI)
  final Ejercicio? ejercicio;

  RutinaEjercicio({
    this.id,
    this.rutinaId,
    required this.ejercicioId,
    required this.orden,
    this.series,
    this.repeticiones,
    this.descansoSegundos,
    this.notas,
    this.ejercicio,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rutinaId': rutinaId,
      'ejercicioId': ejercicioId,
      'orden': orden,
      'series': series,
      'repeticiones': repeticiones,
      'descansoSegundos': descansoSegundos,
      'notas': notas,
    };
  }

  factory RutinaEjercicio.fromMap(Map<String, dynamic> map, {Ejercicio? ejercicio}) {
    return RutinaEjercicio(
      id: map['id'],
      rutinaId: map['rutinaId'],
      ejercicioId: map['ejercicioId'],
      orden: map['orden'],
      series: map['series'],
      repeticiones: map['repeticiones'],
      descansoSegundos: map['descansoSegundos'],
      notas: map['notas'],
      ejercicio: ejercicio,
    );
  }
}

class Rutina {
  final int? id;
  final String nombre;
  final String? descripcion;
  final String? nivel; // 'Principiante', 'Intermedio', 'Avanzado'
  final bool activo;
  final DateTime fechaCreacion;
  
  // Lista de ejercicios en la rutina
  final List<RutinaEjercicio> ejercicios;

  Rutina({
    this.id,
    required this.nombre,
    this.descripcion,
    this.nivel,
    this.activo = true,
    required this.fechaCreacion,
    this.ejercicios = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'nivel': nivel,
      'activo': activo ? 1 : 0,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  factory Rutina.fromMap(Map<String, dynamic> map, {List<RutinaEjercicio> ejercicios = const []}) {
    return Rutina(
      id: map['id'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      nivel: map['nivel'],
      activo: map['activo'] == 1,
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
      ejercicios: ejercicios,
    );
  }

  Rutina copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    String? nivel,
    bool? activo,
    DateTime? fechaCreacion,
    List<RutinaEjercicio>? ejercicios,
  }) {
    return Rutina(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      nivel: nivel ?? this.nivel,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      ejercicios: ejercicios ?? this.ejercicios,
    );
  }
}
