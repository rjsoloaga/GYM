import 'package:flutter/material.dart';

class DropdownDebug extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) {
              // Esto forzará el error y nos dirá EXACTAMENTE dónde está
              return DropdownButton<String>(
                value: 'Pendiente',
                items: [
                  // ITEMS DUPLICADOS INTENCIONALMENTE para encontrar el problema
                  DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente')),
                  DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente Duplicado')),
                ],
                onChanged: (value) {},
              );
            },
          ),
        ),
      ),
    );
  }
}