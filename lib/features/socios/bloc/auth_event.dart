part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginRequested extends AuthEvent {
  final String dni;
  final String telefono;

  const LoginRequested({required this.dni, required this.telefono});

  @override
  List<Object> get props => [dni, telefono];
}

class LogoutRequested extends AuthEvent {}

// Mantener eventos antiguos para compatibilidad
class CheckAuthEvent extends AuthEvent {}

class LoginEvent extends AuthEvent {
  final String dni;
  final String telefono;

  const LoginEvent({required this.dni, required this.telefono});

  @override
  List<Object> get props => [dni, telefono];
}

class LogoutEvent extends AuthEvent {}