import 'package:flutter/material.dart';
import 'package:gym/features/socios/screens/lista_socios_screen.dart';
import 'package:gym/features/dashboard/screens/dashboard_screen.dart';
import 'package:gym/features/auth/screens/login_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DashboardScreen(), // Pantalla principal
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/socios': (context) => const ListaSociosScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}