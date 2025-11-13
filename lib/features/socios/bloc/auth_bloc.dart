import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gym/core/database/database_helper.dart';
import 'package:gym/features/auth/models/usuario.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    
    // Mantener compatibilidad con eventos antiguos
    on<CheckAuthEvent>(_onCheckAuthEvent);
    on<LoginEvent>(_onLoginEvent);
    on<LogoutEvent>(_onLogoutEvent);
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    await _procesarLogin(event.dni, event.telefono, emit);
  }

  // Compatibilidad con evento antiguo
  Future<void> _onLoginEvent(LoginEvent event, Emitter<AuthState> emit) async {
    await _procesarLogin(event.dni, event.telefono, emit);
  }

  Future<void> _procesarLogin(String dni, String telefono, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      final result = await DatabaseHelper.instance.autenticarUsuario(dni, telefono);
      
      if (result != null) {
        final usuario = Usuario.fromMap(result);
        
        print('✅ LOGIN EXITOSO - Usuario: ${usuario.nombreCompleto}');
        
        // Emitir ambos estados para compatibilidad
        emit(AuthSuccess(usuario: usuario));
        emit(AuthAuthenticatedState(user: usuario.toMap())); // Compatibilidad
        
        print('✅ ESTADOS EMITIDOS - Debería navegar ahora');
      } else {
        print('❌ LOGIN FALLIDO - Credenciales incorrectas');
        emit(AuthFailure(error: 'DNI o teléfono incorrectos'));
        emit(AuthErrorState(error: 'DNI o teléfono incorrectos')); // Compatibilidad
      }
    } catch (e) {
      print('❌ ERROR EN LOGIN: $e');
      emit(AuthFailure(error: 'Error de conexión: $e'));
      emit(AuthErrorState(error: 'Error de conexión: $e')); // Compatibilidad
    }
  }

  void _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) {
    _procesarLogout(emit);
  }

  // Compatibilidad con evento antiguo
  void _onLogoutEvent(LogoutEvent event, Emitter<AuthState> emit) {
    _procesarLogout(emit);
  }

  void _procesarLogout(Emitter<AuthState> emit) {
    emit(AuthInitial());
    emit(AuthUnauthenticatedState()); // Compatibilidad
  }

  void _onCheckAuthEvent(CheckAuthEvent event, Emitter<AuthState> emit) {
    // Lógica de verificación de auth si es necesaria
    emit(AuthInitial());
  }
}