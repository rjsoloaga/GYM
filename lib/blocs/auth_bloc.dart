import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym/repositories/database_helper.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitialState()) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthEvent>(_onCheckAuth);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());

    try {
      final usuario = await DatabaseHelper.instance.autenticarUsuario(
        event.username,
        event.password,
      );

      if (usuario != null) {
        // Guardar sesión
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', usuario['username']);
        await prefs.setString('nombre', usuario['nombre']);
        await prefs.setBool('isLoggedIn', true);

        emit(AuthAuthenticatedState(
          usuario['username'],
          usuario['nombre'],
        ));
      } else {
        emit(AuthErrorState('Usuario o contraseña incorrectos'));
      }
    } catch (e) {
      emit(AuthErrorState('Error al iniciar sesión: $e'));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    emit(AuthUnauthenticatedState());
  }

  Future<void> _onCheckAuth(CheckAuthEvent event, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      final username = prefs.getString('username') ?? '';
      final nombre = prefs.getString('nombre') ?? '';
      emit(AuthAuthenticatedState(username, nombre));
    } else {
      emit(AuthUnauthenticatedState());
    }
  }
}
