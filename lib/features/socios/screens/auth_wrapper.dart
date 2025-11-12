import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/features/socios/bloc/auth_bloc.dart';
import 'package:gym/features/socios/screens/login_screen.dart';
import 'package:gym/features/socios/screens/main_navigation_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, dynamic>(
      builder: (context, state) {
        print('🔄 AuthWrapper - Estado actual: $state');
        
        // Para estados nuevos
        if (state is AuthSuccess || state is AuthAuthenticatedState) {
          print('✅ USUARIO AUTENTICADO - Navegando a MainNavigationScreen');
          return MainNavigationScreen();
        }
        
        // Para estados de error
        if (state is AuthFailure || state is AuthErrorState) {
          print('❌ ERROR DE AUTENTICACIÓN - Mostrando Login con error');
          return LoginScreen();
        }
        
        // Para estados de loading o inicial
        print('🔵 ESTADO INICIAL/LOADING - Mostrando Login normal');
        return LoginScreen();
      },
    );
  }
}