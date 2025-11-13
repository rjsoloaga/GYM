part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final dynamic usuario;

  const AuthSuccess({required this.usuario});

  @override
  List<Object> get props => [usuario];
}

class AuthFailure extends AuthState {
  final String error;

  const AuthFailure({required this.error});

  @override
  List<Object> get props => [error];
}

// Mantener estados antiguos para compatibilidad
class AuthUnauthenticatedState extends AuthState {}

class AuthAuthenticatedState extends AuthState {
  final dynamic user;
  const AuthAuthenticatedState({required this.user});
  
  @override
  List<Object> get props => [user];
}

class AuthErrorState extends AuthState {
  final String error;
  const AuthErrorState({required this.error});
  
  @override
  List<Object> get props => [error];
}

class AuthLoadingState extends AuthState {}