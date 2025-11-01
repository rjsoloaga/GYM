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
  EliminarSocioEvent(this.id);
}

class BuscarSociosEvent extends SocioEvent {
  final String texto;
  BuscarSociosEvent(this.texto);
}
