import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:gym/features/socios/models/socio.dart';

class DatabaseHelper {
  //Constructor privado (parte del patron Singleton)
  DatabaseHelper._privateConstructor();

  //Instancia estatica unica
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  //Referencia a la base de datos
  static Database? _database;

  //Getter para la base de datos (si no existe, la crea)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  //Metodo para inicializar la base de datos
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'gym_database.db');

    // Incrementa version si haces migraciones futuras
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Se crea la tabla al instalar por primera vez
        await db.execute(_createSociosTableSql);

        // Seed de admin para login de desarrollo
        await db.insert('socios', {
          'nombreCompleto': 'Admin Test',
          'dni': 'admin',
          'telefono': 'admin',
          'email': 'admin@example.com',
          'fechaInicio': DateTime.now().toIso8601String(),
          'fechaVencimiento': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'precioMensual': 0.0,
          'tipoPlan': 'Admin',
          'activo': 1,
        });
      },
      onOpen: (db) async {
        // Asegura la tabla si por alguna razón falta en DB previa
        await db.execute(_createSociosTableIfNotExistsSql);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // migraciones futuras
      },
    );
  }

  static const String _createSociosTableSql = '''
    CREATE TABLE socios (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombreCompleto TEXT NOT NULL,
      dni TEXT NOT NULL UNIQUE,
      telefono TEXT NOT NULL,
      email TEXT NOT NULL,
      fechaInicio TEXT NOT NULL,
      fechaVencimiento TEXT NOT NULL,
      precioMensual REAL NOT NULL,
      tipoPlan TEXT NOT NULL,
      activo INTEGER NOT NULL DEFAULT 1
    )
  ''';

  static const String _createSociosTableIfNotExistsSql = '''
    CREATE TABLE IF NOT EXISTS socios (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombreCompleto TEXT NOT NULL,
      dni TEXT NOT NULL UNIQUE,
      telefono TEXT NOT NULL,
      email TEXT NOT NULL,
      fechaInicio TEXT NOT NULL,
      fechaVencimiento TEXT NOT NULL,
      precioMensual REAL NOT NULL,
      tipoPlan TEXT NOT NULL,
      activo INTEGER NOT NULL DEFAULT 1
    )
  ''';

  // --- Metodos CRUD (Create, Read, Update, Delete) ---

  //CREATE inserta un nuevo socio
  Future<int> insertarSocio(Socio socio) async {
      Database db = await instance.database; // Obtenemos la referencia de la DB

      // Insertamos el socio convertido a Map y obtenemos su ID automatico
      return await db.insert('socios', socio.toMap());
  }

  //READ - obtener todos los socios
  Future<List<Socio>> getSocios() async {
      Database db = await instance.database;
      // Obtenemos una lista de Maps (cada Map representa una fila de la DB)
      final List<Map<String, dynamic>> maps = await db.query('socios');
      // Convertimos cada Map en una lista de un objeto Socio usando .fromMap()
      return List.generate(maps.length, (i) {
          return Socio.fromMap(maps[i]);
      });
  }

  //UPDATE - actualizar un socio existente
  Future<int> updateSocio(Socio socio) async {
      debugPrint(' DB: Actualizando Socio ID: ${socio.id}');
      Database db = await instance.database;
      // Actualizamos la fila donde el ID coincida
      return await db.update(
          'socios',
          socio.toMap(), // Los nuevos datos
          where: 'id = ?', // La condicion es donde la columna 'id' sea igual a...
          whereArgs: [socio.id], // ...el valor de socio.id
      );
  }

  // DELETE - Eliminar un socio
  Future<int> deleteSocio(int id) async {
      Database db = await instance.database;
      return await db.delete(
          'socios',
          where: 'id = ?',
          whereArgs: [id],
      );
  }

  // Métodos para autenticación (necesarios para auth_bloc)
  // Autenticación: devuelve el Map del socio si coincide dni+telefono y activo=1
  Future<Map<String, dynamic>?> autenticarUsuario(String dni, String telefono) async {
    final db = await database;
    final result = await db.query(
      'socios',
      where: 'dni = ? AND telefono = ? AND activo = 1',
      whereArgs: [dni, telefono],
    );

    if (result.isNotEmpty) {
      // Saneamos el row para evitar nulls que causen TypeError en la UI/Bloc
      final row = Map<String, dynamic>.from(result.first);

      row['nombreCompleto'] = row['nombreCompleto']?.toString() ?? '';
      row['dni'] = row['dni']?.toString() ?? '';
      row['telefono'] = row['telefono']?.toString() ?? '';
      row['email'] = row['email']?.toString() ?? '';
      row['fechaInicio'] = row['fechaInicio']?.toString() ?? DateTime.fromMillisecondsSinceEpoch(0).toIso8601String();
      row['fechaVencimiento'] = row['fechaVencimiento']?.toString() ?? DateTime.fromMillisecondsSinceEpoch(0).toIso8601String();
      row['precioMensual'] = (row['precioMensual'] is num) ? (row['precioMensual'] as num).toDouble() : double.tryParse(row['precioMensual']?.toString() ?? '') ?? 0.0;
      row['tipoPlan'] = row['tipoPlan']?.toString() ?? '';
      row['activo'] = (row['activo'] is int) ? row['activo'] as int : int.tryParse(row['activo']?.toString() ?? '1') ?? 1;

      debugPrint('autenticarUsuario: row saneada => $row');
      return row;
    }
    return null;
  }

  // Métodos para dashboard (necesarios para dashboard_screen)
  Future<double> getIngresosMensuales() async {
    final db = await database;
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    
    final result = await db.rawQuery('''
      SELECT SUM(precioMensual) as total 
      FROM socios 
      WHERE fechaVencimiento BETWEEN ? AND ?
    ''', [firstDay.toIso8601String(), lastDay.toIso8601String()]);
    
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> getCuotasVencidas() async {
    final db = await database;
    final now = DateTime.now();
    
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM socios 
      WHERE fechaVencimiento < ?
    ''', [now.toIso8601String()]);
    
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  Future<int> getCuotasPorVencer([int dias = 7]) async {
    final db = await database;
    final now = DateTime.now();
    final inXDias = now.add(Duration(days: dias));
    
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM socios 
      WHERE fechaVencimiento BETWEEN ? AND ?
    ''', [now.toIso8601String(), inXDias.toIso8601String()]);
    
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  // Método de ayuda para debug: devuelve todas las filas crudas de la tabla socios
  Future<List<Map<String, dynamic>>> getAllRawSocios() async {
    final db = await database;
    return await db.query('socios');
  }

  // Método de ayuda para debug: imprime en logs el contenido de socios
  Future<void> debugPrintAllSocios() async {
    final rows = await getAllRawSocios();
    debugPrint('--- Contenido tabla socios: ${rows.length} filas ---');
    for (var r in rows) {
      debugPrint(r.toString());
    }
  }

  /// Borra el archivo de base de datos usado por la app (solo para desarrollo).
  Future<void> dropDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'gym_database.db');
    await deleteDatabase(path);
    debugPrint('Database deleted: $path');
    _database = null;
  }

}