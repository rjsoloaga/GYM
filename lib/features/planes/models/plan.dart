class Plan {
  final int? id;
  final String nombre;
  final double precio;
  final int? duracionDias; // Hacemos que sea nullable para soportar tiempo indeterminado
  final bool activo;
  final bool tiempoIndeterminado; // Nuevo campo para indicar si el plan es por tiempo indeterminado
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  Plan({
    this.id,
    required this.nombre,
    required this.precio,
    this.duracionDias,
    this.tiempoIndeterminado = false, // Por defecto no es tiempo indeterminado
    this.activo = true,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  })  : fechaCreacion = fechaCreacion ?? DateTime.now(),
        fechaActualizacion = fechaActualizacion ?? DateTime.now(),
        // Validación para asegurar que al menos uno de los dos campos esté configurado
        assert(duracionDias != null || tiempoIndeterminado == true, 
               'Debe especificar duración o marcar como tiempo indeterminado'),
        assert(!(duracionDias != null && tiempoIndeterminado == true),
               'No puede tener duración y ser tiempo indeterminado al mismo tiempo');

  // Convertir un Map a Plan
  factory Plan.fromMap(Map<String, dynamic> map) {
    return Plan(
      id: map['id'],
      nombre: map['nombre'],
      precio: map['precio'] is int ? (map['precio'] as int).toDouble() : map['precio'],
      duracionDias: map['duracionDias'],
      tiempoIndeterminado: map['tiempoIndeterminado'] == 1,
      activo: map['activo'] == 1,
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
      fechaActualizacion: map['fechaActualizacion'] != null 
          ? DateTime.parse(map['fechaActualizacion'])
          : DateTime.now(),
    );
  }

  // Convertir un Plan a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'duracionDias': duracionDias,
      'tiempoIndeterminado': tiempoIndeterminado ? 1 : 0,
      'activo': activo ? 1 : 0,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion.toIso8601String(),
    };
  }

  // Copiar con cambios
  Plan copyWith({
    int? id,
    String? nombre,
    double? precio,
    int? duracionDias,
    bool? tiempoIndeterminado,
    bool? activo,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return Plan(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      duracionDias: duracionDias ?? this.duracionDias,
      tiempoIndeterminado: tiempoIndeterminado ?? this.tiempoIndeterminado,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}