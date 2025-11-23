import 'package:equatable/equatable.dart';

class CategoriaProducto extends Equatable {
  final int? id;
  final String nombre;
  final String? descripcion;
  final String? icono;
  final String? color;
  final bool activo;
  final int orden;
  final DateTime fechaCreacion;

  const CategoriaProducto({
    this.id,
    required this.nombre,
    this.descripcion,
    this.icono,
    this.color,
    this.activo = true,
    this.orden = 0,
    required this.fechaCreacion,
  });

  factory CategoriaProducto.fromMap(Map<String, dynamic> map) {
    return CategoriaProducto(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      icono: map['icono'] as String?,
      color: map['color'] as String?,
      activo: (map['activo'] as int?) == 1,
      orden: (map['orden'] as int?) ?? 0,
      fechaCreacion: DateTime.parse(map['fechaCreacion'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'icono': icono,
      'color': color,
      'activo': activo ? 1 : 0,
      'orden': orden,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  CategoriaProducto copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    String? icono,
    String? color,
    bool? activo,
    int? orden,
    DateTime? fechaCreacion,
  }) {
    return CategoriaProducto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      icono: icono ?? this.icono,
      color: color ?? this.color,
      activo: activo ?? this.activo,
      orden: orden ?? this.orden,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  @override
  List<Object?> get props => [id, nombre, descripcion, icono, color, activo, orden, fechaCreacion];
}
