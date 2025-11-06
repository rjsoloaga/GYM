import 'package:sqflite/sqflite.dart'; // PAra la DB
import 'package:path/path.dart'; // Para unir rutas de directorios
import 'package:gym/features/socios/models/socio.dart';
import 'package:flutter/foundation.dart';



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
      //Obtenemos la ruta del dispositivo donde guardamos la base de datos
      String path = join(await getDatabasesPath(), 'gym_database.db');
      
      //Abre o crea la base de datos en la ruta especificada
      return await openDatabase(
          path,
          version: 2, //version de la db(util para futuras actualizaciones)
          onCreate: _createTable, //Funcion que ejecuta al crear la db por primera vez
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 2) {
              // Agregar la columna 'email' para instalaciones anteriores
              await db.execute("ALTER TABLE socio ADD COLUMN email TEXT DEFAULT ''");
            }
          },
      );
  }

  //Metodo para crear la tabla 'socios'
  Future<void> _createTable(Database db, int version) async {
      //Ejecutamos un comando SQL para crear la tabla
      await db.execute('''
          CREATE TABLE socio(
              id INTEGER PRIMARY KEY AUTOINCREMENT, -- El ID se genera automáticamente
              nombreCompleto TEXT NOT NULL,          -- NOT NULL significa que es obligatorio
              dni TEXT NOT NULL UNIQUE,              -- UNIQUE asegura que no haya dos DNIs iguales
              telefono TEXT NOT NULL,
              email TEXT NOT NULL,
              fechaInicio TEXT NOT NULL,             -- Las fechas se guardan como TEXT en formato ISO
              fechaVencimiento TEXT NOT NULL,
              precioMensual REAL NOT NULL,           -- REAL es para números con decimales
              tipoPlan TEXT NOT NULL
          )
              ''');

      // AGREGAR ESTA NUEVA TABLA para el login:
      await db.execute('''
          CREATE TABLE socios(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              dni TEXT NOT NULL UNIQUE,
              nombre TEXT NOT NULL,
              apellido TEXT NOT NULL,
              telefono TEXT NOT NULL,
              email TEXT,
              fecha_inscripcion TEXT,
              activo INTEGER DEFAULT 1
          )
      ''');
  }


  // --- Metodos CRUD (Create, Read, Update, Delete) ---

  //CREATE inserta un nuevo socio
  Future<int> insertarSocio(Socio socio) async {
      Database db = await instance.database; // Obtenemos la referencia de la DB

      // Insertamos el socio convertido a Map y obtenemos su ID automatico
      return await db.insert('socio', socio.toMap());
  }

  //READ - obtener todos los socios
  Future<List<Socio>> getSocios() async {
      Database db = await instance.database;
      // Obtenemos una lista de Maps (cada Map representa una fila de la DB)
      final List<Map<String, dynamic>> maps = await db.query('socio');
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
          'socio',
          socio.toMap(), // Los nuevos datos
          where: 'id = ?', // La condicion es donde la columna 'id' sea igual a...
          whereArgs: [socio.id], // ...el valor de socio.id
      );
  }

  // DELETE - Eliminar un socio
  Future<int> deleteSocio(int id) async {
      Database db = await instance.database;
      return await db.delete(
          'socio',
          where: 'id = ?',
          whereArgs: [id],
      );
  }

  // Métodos para autenticación (necesarios para auth_bloc)
  Future<Map<String, dynamic>?> autenticarUsuario(String dni, String telefono) async {
    final db = await database;
    final result = await db.query(
      'socios', // Esta tabla debe existir después de tus cambios
      where: 'dni = ? AND telefono = ? AND activo = 1',
      whereArgs: [dni, telefono],
    );
    
    if (result.isNotEmpty) {
      return result.first; // Retorna los datos reales del socio
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
    
    return result.first['total'] as double? ?? 0.0;
  }

  Future<int> getCuotasVencidas() async {
    final db = await database;
    final now = DateTime.now();
    
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM socios 
      WHERE fechaVencimiento < ?
    ''', [now.toIso8601String()]);
    
    return result.first['count'] as int? ?? 0;
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
    
    return result.first['count'] as int? ?? 0;
  }

}