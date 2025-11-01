part of 'socios_bloc.dart';

abstract class SociosState {}

class SociosInitialState extends SociosState {}

class SociosCargandoState extends SociosState {}

class SociosCargadosState extends SociosState {
  final List<Socio> todosLosSocios;    // Lista completa
  final List<Socio> sociosFiltrados;   // Lista después de búsqueda
  final String textoBusqueda;          // Texto actual de búsqueda
  
  SociosCargadosState({
    required this.todosLosSocios,
    required this.sociosFiltrados,
    this.textoBusqueda = '',
  });
}

class SociosErrorState extends SociosState {
  final String error;
  SociosErrorState(this.error);
}
