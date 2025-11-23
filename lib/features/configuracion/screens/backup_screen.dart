import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gym/services/backup_service.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  List<FileSystemEntity> _backups = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    try {
      final backups = await _backupService.listBackups();
      setState(() {
        _backups = backups;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando backups: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _crearBackup() async {
    setState(() => _isLoading = true);
    try {
      await _backupService.createBackup();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Backup creado exitosamente'), backgroundColor: Colors.green),
      );
      await _loadBackups();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error creando backup: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restaurarBackup(String path) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Restaurar Base de Datos'),
        content: const Text(
          'Esta acción reemplazará todos los datos actuales con los del backup seleccionado.\n\n'
          'Se recomienda crear un backup actual antes de proceder.\n\n'
          '¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _backupService.restoreBackup(path);
        if (!mounted) return;
        
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('✅ Restauración Completada'),
            content: const Text('La base de datos ha sido restaurada. La aplicación debe reiniciarse para aplicar los cambios.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  // En desktop podríamos intentar cerrar la app, pero mejor dejar que el usuario lo haga
                  exit(0); 
                },
                child: const Text('Cerrar Aplicación'),
              ),
            ],
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error restaurando backup: $e'), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _eliminarBackup(String path) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Backup'),
        content: const Text('¿Estás seguro de que deseas eliminar este archivo de backup?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _backupService.deleteBackup(path);
        await _loadBackups();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error eliminando backup: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Copias de Seguridad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBackups,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Las copias de seguridad se guardan en la carpeta "GymBackups" dentro de tus Documentos.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _crearBackup,
                  icon: const Icon(Icons.save),
                  label: const Text('Crear Backup Ahora'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator()
          else
            Expanded(
              child: _backups.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.backup_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No hay copias de seguridad disponibles', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _backups.length,
                      itemBuilder: (context, index) {
                        final file = _backups[index] as File;
                        final stat = file.statSync();
                        final fileName = path.basename(file.path);
                        final date = stat.modified;
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(Icons.storage, color: Colors.white),
                            ),
                            title: Text(fileName),
                            subtitle: Text(
                              '${DateFormat('dd/MM/yyyy HH:mm').format(date)} • ${_formatSize(stat.size)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.restore, color: Colors.orange),
                                  onPressed: () => _restaurarBackup(file.path),
                                  tooltip: 'Restaurar',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _eliminarBackup(file.path),
                                  tooltip: 'Eliminar',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
