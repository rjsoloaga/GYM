import 'package:flutter/material.dart';
import 'package:gym/core/database/database_helper.dart';
import 'package:intl/intl.dart';

class HistorialAsistenciaScreen extends StatefulWidget {
  const HistorialAsistenciaScreen({super.key});

  @override
  State<HistorialAsistenciaScreen> createState() => _HistorialAsistenciaScreenState();
}

class _HistorialAsistenciaScreenState extends State<HistorialAsistenciaScreen> {
  late Future<List<Map<String, dynamic>>> _asistenciasFuture;

  @override
  void initState() {
    super.initState();
    // Obtener las últimas 100 asistencias
    _asistenciasFuture = DatabaseHelper.instance.getUltimasAsistencias(limit: 100);
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'Vencido':
        return Colors.red;
      case 'Por Vencer':
        return Colors.orange;
      case 'Al Día':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Asistencias'),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _asistenciasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final asistencias = snapshot.data ?? [];

          if (asistencias.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay registros de asistencia', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: asistencias.length,
            itemBuilder: (context, index) {
              final asistencia = asistencias[index];
              final fecha = DateTime.parse(asistencia['fechaHora']);
              final estado = asistencia['estadoCuota'];
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getColorEstado(estado).withOpacity(0.2),
                    child: Icon(
                      Icons.check_circle,
                      color: _getColorEstado(estado),
                    ),
                  ),
                  title: Text(asistencia['socioNombre'] ?? 'Socio desconocido'),
                  subtitle: Text('DNI: ${asistencia['socioDni']}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(fecha),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(fecha),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
