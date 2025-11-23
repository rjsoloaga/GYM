import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:gym/core/database/database_helper.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  Future<String> get _backupDirectory async {
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(join(docsDir.path, 'GymBackups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir.path;
  }

  Future<String> _getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, 'gym_database.db');
  }

  Future<String> createBackup() async {
    try {
      final dbPath = await _getDatabasePath();
      final backupDir = await _backupDirectory;
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupPath = join(backupDir, 'gym_backup_$timestamp.db');

      // Asegurarse de que la base de datos esté cerrada o en un estado seguro sería ideal,
      // pero SQLite permite copiar el archivo si no hay escrituras activas masivas.
      // Para mayor seguridad, podríamos usar la API de backup de SQLite si estuviéramos en C++,
      // pero copiar el archivo suele ser suficiente para apps pequeñas/medianas.
      
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.copy(backupPath);
        return backupPath;
      } else {
        throw Exception('No se encontró la base de datos original.');
      }
    } catch (e) {
      throw Exception('Error creando backup: $e');
    }
  }

  Future<List<FileSystemEntity>> listBackups() async {
    final backupDir = Directory(await _backupDirectory);
    if (!await backupDir.exists()) return [];
    
    final List<FileSystemEntity> files = await backupDir.list().toList();
    // Ordenar por fecha descendente (más reciente primero)
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files.where((file) => file.path.endsWith('.db')).toList();
  }

  Future<void> restoreBackup(String backupPath) async {
    try {
      final dbPath = await _getDatabasePath();
      final backupFile = File(backupPath);
      
      if (!await backupFile.exists()) {
        throw Exception('El archivo de backup no existe.');
      }

      // Cerrar la conexión actual a la base de datos si es posible
      // Nota: DatabaseHelper no expone un método close público fácilmente, 
      // pero al sobrescribir el archivo, la próxima llamada a openDatabase debería manejarlo
      // o podría causar corrupción si hay una conexión activa escribiendo.
      // Lo ideal es reiniciar la app después de restaurar.

      await backupFile.copy(dbPath);
    } catch (e) {
      throw Exception('Error restaurando backup: $e');
    }
  }
  
  Future<void> deleteBackup(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
