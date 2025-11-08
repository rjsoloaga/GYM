part of 'auth_bloc.dart';

abstract class AuthState {}

class AuthInitialState extends AuthState {}

class AuthLoadingState extends AuthState {}

class AuthAuthenticatedState extends AuthState {
  final String username;
  final String nombre;
  final String rol; // 'admin' o 'coach'

  AuthAuthenticatedState(this.username, this.nombre, [this.rol = 'admin']);
  
  // Métodos helper para verificar permisos
  bool get puedeEditar => rol == 'admin';
  bool get puedeEliminar => rol == 'admin';
  bool get puedeAgregar => rol == 'admin';
}

class AuthUnauthenticatedState extends AuthState {}

class AuthErrorState extends AuthState {
  final String error;

  AuthErrorState(this.error);
}
