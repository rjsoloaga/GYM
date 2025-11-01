import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('PANEL PRINCIPAL - EN CONSTRUCCIÓN'),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/socios'),
              child: const Text('Gestionar Socios'),
            ),
          ],
        ),
      ),
    );
  }
}