part of 'socios_bloc.dart';

abstract class SociosState {}

class SociosInitialState extends SociosState {}

class SociosCargandoState extends SociosState {}

class SociosCargadosState extends SociosState {
  final List<Socio> socios;
  SociosCargadosState(this.socios);
}

class SociosErrorState extends SociosState {
  final String error;
  SociosErrorState(this.error);
}
