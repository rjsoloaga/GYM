import 'package:equatable/equatable.dart';

class Proveedor extends Equatable {
  final int? id;
  final String nombre;
  final String? razonSocial;
  final String? cuit;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String? contacto;
  final String? notas;
  final bool activo;
  final DateTime fechaCreacion;

  const Proveedor({
    this.id,
    required this.nombre,
    this.razonSocial,
    this.cuit,
    this.telefono,
    this.email,
    this.direccion,
    this.contacto,
    this.notas,
    this.activo = true,
    required this.fechaCreacion,
  });

  factory Proveedor.fromMap(Map<String, dynamic> map) {
    return Proveedor(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      razonSocial: map['razonSocial'] as String?,
      cuit: map['cuit'] as String?,
      telefono: map['telefono'] as String?,
      email: map['email'] as String?,
      direccion: map['direccion'] as String?,
      contacto: map['contacto'] as String?,
      notas: map['notas'] as String?,
      activo: (map['activo'] as int?) == 1,
      fechaCreacion: DateTime.parse(map['fechaCreacion'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'razonSocial': razonSocial,
      'cuit': cuit,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'contacto': contacto,
      'notas': notas,
      'activo': activo ? 1 : 0,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  Proveedor copyWith({
    int? id,
    String? nombre,
    String? razonSocial,
    String? cuit,
    String? telefono,
    String? email,
    String? direccion,
    String? contacto,
    String? notas,
    bool? activo,
    DateTime? fechaCreacion,
  }) {
    return Proveedor(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      razonSocial: razonSocial ?? this.razonSocial,
      cuit: cuit ?? this.cuit,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      contacto: contacto ?? this.contacto,
      notas: notas ?? this.notas,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        razonSocial,
        cuit,
        telefono,
        email,
        direccion,
        contacto,
        notas,
        activo,
        fechaCreacion,
      ];
}
