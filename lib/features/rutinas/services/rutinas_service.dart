import 'package:sqflite/sqflite.dart';
import 'package:gym/core/database/database_helper.dart';
import 'package:gym/features/rutinas/models/ejercicio.dart';
import 'package:gym/features/rutinas/models/rutina.dart';

class RutinasService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // === EJERCICIOS ===

  Future<int> crearEjercicio(Ejercicio ejercicio) async {
    final db = await _dbHelper.database;
    return await db.insert('ejercicios', ejercicio.toMap());
  }

  Future<List<Ejercicio>> getEjercicios({bool soloActivos = true}) async {
    final db = await _dbHelper.database;
    final whereClause = soloActivos ? 'activo = 1' : null;
    final maps = await db.query('ejercicios', where: whereClause, orderBy: 'nombre ASC');
    return List.generate(maps.length, (i) => Ejercicio.fromMap(maps[i]));
  }

  Future<int> actualizarEjercicio(Ejercicio ejercicio) async {
    final db = await _dbHelper.database;
    return await db.update(
      'ejercicios',
      ejercicio.toMap(),
      where: 'id = ?',
      whereArgs: [ejercicio.id],
    );
  }

  Future<int> eliminarEjercicio(int id) async {
    // Soft delete (marcar como inactivo) para no romper integridad referencial
    final db = await _dbHelper.database;
    return await db.update(
      'ejercicios',
      {'activo': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === RUTINAS ===

  Future<int> crearRutina(Rutina rutina) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      // 1. Insertar la rutina
      final rutinaId = await txn.insert('rutinas', rutina.toMap());

      // 2. Insertar los ejercicios de la rutina
      for (var item in rutina.ejercicios) {
        final itemMap = item.toMap();
        itemMap['rutinaId'] = rutinaId; // Asignar el ID de la rutina creada
        await txn.insert('rutina_ejercicios', itemMap);
      }

      return rutinaId;
    });
  }

  Future<List<Rutina>> getRutinas({bool soloActivas = true}) async {
    final db = await _dbHelper.database;
    final whereClause = soloActivas ? 'activo = 1' : null;
    final maps = await db.query('rutinas', where: whereClause, orderBy: 'nombre ASC');
    
    // Cargar ejercicios para cada rutina (esto podría optimizarse cargando bajo demanda)
    List<Rutina> rutinas = [];
    for (var map in maps) {
      final rutinaId = map['id'] as int;
      final ejercicios = await getEjerciciosDeRutina(rutinaId);
      rutinas.add(Rutina.fromMap(map, ejercicios: ejercicios));
    }
    
    return rutinas;
  }

  Future<List<RutinaEjercicio>> getEjerciciosDeRutina(int rutinaId) async {
    final db = await _dbHelper.database;
    
    // Hacer join con la tabla de ejercicios para obtener el nombre y detalles
    final result = await db.rawQuery('''
      SELECT re.*, e.nombre, e.descripcion, e.grupoMuscular, e.videoUrl, e.activo as ejercicioActivo
      FROM rutina_ejercicios re
      INNER JOIN ejercicios e ON re.ejercicioId = e.id
      WHERE re.rutinaId = ?
      ORDER BY re.orden ASC
    ''', [rutinaId]);

    return result.map((map) {
      // Construir el objeto Ejercicio embebido
      final ejercicio = Ejercicio(
        id: map['ejercicioId'] as int,
        nombre: map['nombre'] as String,
        descripcion: map['descripcion'] as String?,
        grupoMuscular: map['grupoMuscular'] as String?,
        videoUrl: map['videoUrl'] as String?,
        activo: (map['ejercicioActivo'] as int) == 1,
      );

      return RutinaEjercicio.fromMap(map, ejercicio: ejercicio);
    }).toList();
  }

  Future<void> actualizarRutina(Rutina rutina) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Actualizar datos básicos de la rutina
      await txn.update(
        'rutinas',
        rutina.toMap(),
        where: 'id = ?',
        whereArgs: [rutina.id],
      );

      // 2. Eliminar ejercicios anteriores
      await txn.delete(
        'rutina_ejercicios',
        where: 'rutinaId = ?',
        whereArgs: [rutina.id],
      );

      // 3. Insertar nuevos ejercicios
      for (var item in rutina.ejercicios) {
        final itemMap = item.toMap();
        itemMap['rutinaId'] = rutina.id;
        await txn.insert('rutina_ejercicios', itemMap);
      }
    });
  }

  Future<int> eliminarRutina(int id) async {
    // Soft delete
    final db = await _dbHelper.database;
    return await db.update(
      'rutinas',
      {'activo': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
