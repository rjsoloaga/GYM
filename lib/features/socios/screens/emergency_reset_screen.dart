import 'package:flutter/material.dart';
import 'package:gym/core/database/database_reset.dart';

class EmergencyResetScreen extends StatelessWidget {
  const EmergencyResetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reset de Emergencia')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, size: 64, color: Colors.orange),
            SizedBox(height: 20),
            Text('PROBLEMA DE LOGIN', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('El usuario admin no está configurado correctamente.'),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                await DatabaseReset.resetAdminUser();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Admin restablecido. Reinicia la app.')),
                );
              },
              child: Text('RESTABLECER ADMIN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
            SizedBox(height: 20),
            Text('Luego de hacer clic, cierra y reinicia la aplicación.', 
              style: TextStyle(color: Colors.grey)),
            SizedBox(height: 10),
            Text('Contacta al administrador para las credenciales',
              style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}