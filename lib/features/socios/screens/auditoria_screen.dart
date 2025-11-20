import 'package:flutter/material.dart';
import 'package:gym/core/database/database_helper.dart';
import 'package:intl/intl.dart';

class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({super.key});

  @override
  State<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  late Future<List<Map<String, dynamic>>> _auditoriaFuture;

  @override
  void initState() {
    super.initState();
    _auditoriaFuture = DatabaseHelper.instance.getAuditoria();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoría de Acciones'),
        backgroundColor: Colors.blueGrey,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _auditoriaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay registros de auditoría', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final fecha = DateTime.parse(log['fechaHora']);
              final esEliminacion = log['accion'] == 'ELIMINAR';
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: esEliminacion ? Colors.red[100] : Colors.green[100],
                    child: Icon(
                      esEliminacion ? Icons.delete : Icons.restore,
                      color: esEliminacion ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text(log['detalles'] ?? 'Acción desconocida'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Socio: ${log['socioNombre']} (DNI: ${log['socioDni']})'),
                      Text(
                        'Por: ${log['usuarioNombre'] ?? 'Desconocido'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(fecha),
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
