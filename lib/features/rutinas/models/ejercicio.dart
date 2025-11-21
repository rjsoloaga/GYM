class Ejercicio {
  final int? id;
  final String nombre;
  final String? descripcion;
  final String? grupoMuscular;
  final String? videoUrl;
  final bool activo;

  Ejercicio({
    this.id,
    required this.nombre,
    this.descripcion,
    this.grupoMuscular,
    this.videoUrl,
    this.activo = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'grupoMuscular': grupoMuscular,
      'videoUrl': videoUrl,
      'activo': activo ? 1 : 0,
    };
  }

  factory Ejercicio.fromMap(Map<String, dynamic> map) {
    return Ejercicio(
      id: map['id'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      grupoMuscular: map['grupoMuscular'],
      videoUrl: map['videoUrl'],
      activo: map['activo'] == 1,
    );
  }

  Ejercicio copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    String? grupoMuscular,
    String? videoUrl,
    bool? activo,
  }) {
    return Ejercicio(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      grupoMuscular: grupoMuscular ?? this.grupoMuscular,
      videoUrl: videoUrl ?? this.videoUrl,
      activo: activo ?? this.activo,
    );
  }
}
