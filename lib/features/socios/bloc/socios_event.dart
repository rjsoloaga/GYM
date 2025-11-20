part of 'socios_bloc.dart';

abstract class SocioEvent {}

class CargarSociosEvent extends SocioEvent {}

class AgregarSocioEvent extends SocioEvent {
  final Socio socio;
  AgregarSocioEvent(this.socio);
}

class ActualizarSocioEvent extends SocioEvent {
  final Socio socio;
  ActualizarSocioEvent(this.socio);
}

class EliminarSocioEvent extends SocioEvent {
  final int id;
  final int? usuarioId;
  final String? usuarioNombre;
  EliminarSocioEvent(this.id, {this.usuarioId, this.usuarioNombre});
}

class BuscarSociosEvent extends SocioEvent {
  final String texto;
  BuscarSociosEvent(this.texto);
}

class CargarSociosInactivosEvent extends SocioEvent {}

class ReactivarSocioEvent extends SocioEvent {
  final int id;
  final int? usuarioId;
  final String? usuarioNombre;
  ReactivarSocioEvent(this.id, {this.usuarioId, this.usuarioNombre});
}