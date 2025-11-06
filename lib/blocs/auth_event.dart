part of 'auth_bloc.dart';

abstract class AuthEvent {}

class LoginEvent extends AuthEvent {
  final String username;
  final String password;

  LoginEvent(this.username, this.password);
}

class LogoutEvent extends AuthEvent {}

class CheckAuthEvent extends AuthEvent {}
