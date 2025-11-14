import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gym/features/notificaciones/services/notificacion_service.dart';
// imports limpiados: eliminar referencias no usadas
import 'package:gym/core/database/database_helper.dart';
// import 'package:gym/features/socios/screens/agregar_socio_screen.dart'; // no usado

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({Key? key}) : super(key: key);

  @override
  _NotificacionesScreenState createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  late StreamSubscription<Map<String, dynamic>> _suscripcion;

  @override
  void initState() {
    super.initState();
    // Escuchar eventos de nuevas solicitudes aceptadas
    _suscripcion = NotificacionService.onSolicitudAceptada.listen((solicitud) {
      if (mounted) {
        _mostrarDialogoSolicitudAceptada(solicitud);
      }
    });
  }

  @override
  void dispose() {
    _suscripcion.cancel();
    super.dispose();
  }

  Future<void> _mostrarDialogoSolicitudAceptada(Map<String, dynamic> solicitud) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Solicitud Aceptada'),
          content: Text('Se ha aceptado la solicitud de ${solicitud['nombre']}'),
          actions: <Widget>[
            TextButton(
              child: const Text('Ver Lista de Socios'),
              onPressed: () {
                Navigator.of(context).pop();
                // Navegar a la lista de socios
                Navigator.pushReplacementNamed(context, '/socios');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: const Center(
        child: Text('No hay notificaciones recientes'),
      ),
    );
  }
}