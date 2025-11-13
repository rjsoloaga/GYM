import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:gym/features/socios/models/socio.dart';
import 'package:gym/features/auth/models/usuario.dart'; // NUEVO

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'gym_database.db');

    // ⚠️ INCREMENTA LA VERSIÓN para crear nuevas tablas
    return await openDatabase(
      path,
      version: 5, // CAMBIADO de 4 a 5
      onCreate: (db, version) async {
        // Crear tabla de usuarios primero
        await db.execute(_createUsuariosTableSql);
        // Crear tabla de socios
        await db.execute(_createSociosTableSql);
        // Crear tabla de pagos
        await db.execute(_createPagosTableSql);

        // Seed de admin para login de desarrollo
        await _crearUsuarioAdmin(db);
      },
      onOpen: (db) async {
        // Asegurar tablas si faltan
        await db.execute(_createUsuariosTableIfNotExistsSql);
        await db.execute(_createSociosTableIfNotExistsSql);
        await db.execute(_createPagosTableIfNotExistsSql);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Migración desde versión 2 a 3
        if (oldVersion == 2) {
          // Crear tabla de usuarios
          await db.execute(_createUsuariosTableSql);
          // Migrar admin de socios a usuarios
          await _migrarAdminDesdeSocios(db);
          // Agregar nuevas columnas a socios
          await db.execute('ALTER TABLE socios ADD COLUMN pendienteAprobacion INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE socios ADD COLUMN fechaRegistroTelegram TEXT');
          await db.execute('ALTER TABLE socios ADD COLUMN usuarioId INTEGER');
        }
        // Migración desde versión 3 a 4
        if (oldVersion <= 3) {
          // Crear tabla de pagos
          await db.execute(_createPagosTableSql);
        }
        // Migración desde versión 4 a 5
        if (oldVersion == 4) {
          // Agregar usuarioId a tabla de pagos
          await db.execute('ALTER TABLE pagos ADD COLUMN usuarioId INTEGER');
        }
      },
    );
  }

  // NUEVO: SQL para tabla de usuarios
  static const String _createUsuariosTableSql = '''
    CREATE TABLE usuarios (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombreCompleto TEXT NOT NULL,
      email TEXT NOT NULL,
      telefono TEXT NOT NULL,
      dni TEXT NOT NULL UNIQUE,
      rol TEXT NOT NULL,
      fechaCreacion TEXT NOT NULL,
      activo INTEGER DEFAULT 1,
      telegramChatId TEXT
    )
  ''';

  static const String _createUsuariosTableIfNotExistsSql = '''
    CREATE TABLE IF NOT EXISTS usuarios (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombreCompleto TEXT NOT NULL,
      email TEXT NOT NULL,
      telefono TEXT NOT NULL,
      dni TEXT NOT NULL UNIQUE,
      rol TEXT NOT NULL,
      fechaCreacion TEXT NOT NULL,
      activo INTEGER DEFAULT 1,
      telegramChatId TEXT
    )
  ''';

  // SQL actualizado para socios
  static const String _createSociosTableSql = '''
    CREATE TABLE socios (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombreCompleto TEXT NOT NULL,
      dni TEXT NOT NULL,
      telefono TEXT NOT NULL, 
      email TEXT NOT NULL,
      fechaInicio TEXT NOT NULL,
      fechaVencimiento TEXT NOT NULL,
      precioMensual REAL NOT NULL,
      tipoPlan TEXT NOT NULL,
      telegramChatId TEXT,
      pendienteAprobacion INTEGER DEFAULT 0,
      fechaRegistroTelegram TEXT,
      usuarioId INTEGER,
      activo INTEGER DEFAULT 1
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
      telegramChatId TEXT,
      pendienteAprobacion INTEGER DEFAULT 0,
      fechaRegistroTelegram TEXT,
      usuarioId INTEGER,
      activo INTEGER NOT NULL DEFAULT 1
    )
  ''';

  // NUEVO: SQL para tabla de pagos
  static const String _createPagosTableSql = '''
    CREATE TABLE pagos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      socioId INTEGER NOT NULL,
      usuarioId INTEGER,
      amount REAL NOT NULL,
      date TEXT NOT NULL,
      method TEXT NOT NULL,
      FOREIGN KEY (socioId) REFERENCES socios(id) ON DELETE CASCADE,
      FOREIGN KEY (usuarioId) REFERENCES usuarios(id) ON DELETE SET NULL
    )
  ''';

  static const String _createPagosTableIfNotExistsSql = '''
    CREATE TABLE IF NOT EXISTS pagos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      socioId INTEGER NOT NULL,
      usuarioId INTEGER,
      amount REAL NOT NULL,
      date TEXT NOT NULL,
      method TEXT NOT NULL,
      FOREIGN KEY (socioId) REFERENCES socios(id) ON DELETE CASCADE,
      FOREIGN KEY (usuarioId) REFERENCES usuarios(id) ON DELETE SET NULL
    )
  ''';

  // NUEVO: Crear usuario admin
  static Future<void> _crearUsuarioAdmin(Database db) async {
    await db.insert('usuarios', {
      'nombreCompleto': 'Administrador',
      'email': 'admin@gym.com',
      'telefono': '0000000000',
      'dni': 'admin',
      'rol': 'admin',
      'fechaCreacion': DateTime.now().toIso8601String(),
      'activo': 1,
      'telegramChatId': null,
    });
  }

  // NUEVO: Migrar admin desde tabla socios
  static Future<void> _migrarAdminDesdeSocios(Database db) async {
    // Buscar el admin en socios
    final adminSocios = await db.query(
      'socios',
      where: 'dni = ?',
      whereArgs: ['admin'],
    );

    if (adminSocios.isNotEmpty) {
      // Crear usuario admin
      await db.insert('usuarios', {
        'nombreCompleto': 'Administrador',
        'email': 'admin@gym.com',
        'telefono': '0000000000',
        'dni': 'admin',
        'rol': 'admin',
        'fechaCreacion': DateTime.now().toIso8601String(),
        'activo': 1,
        'telegramChatId': null,
      });
    }
  }

  // --- MÉTODOS PARA USUARIOS (NUEVOS) ---

  // CREATE usuario
  Future<int> insertarUsuario(Usuario usuario) async {
    Database db = await instance.database;
    return await db.insert('usuarios', usuario.toMap());
  }

  // READ - obtener todos los usuarios
  Future<List<Usuario>> getUsuarios() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('usuarios');
    return List.generate(maps.length, (i) => Usuario.fromMap(maps[i]));
  }

  // READ - obtener usuario por ID
  Future<Usuario?> getUsuario(int id) async {
    Database db = await instance.database;
    final maps = await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Usuario.fromMap(maps.first);
    }
    return null;
  }

  // UPDATE - actualizar usuario
  Future<int> updateUsuario(Usuario usuario) async {
    Database db = await instance.database;
    return await db.update(
      'usuarios',
      usuario.toMap(),
      where: 'id = ?',
      whereArgs: [usuario.id],
    );
  }

  // Autenticación con usuarios
  Future<Map<String, dynamic>?> autenticarUsuario(String dni, String telefono) async {
    final db = await database;
    final result = await db.query(
      'usuarios', // CAMBIADO: ahora usa tabla usuarios
      where: 'dni = ? AND telefono = ? AND activo = 1',
      whereArgs: [dni, telefono],
    );

    if (result.isNotEmpty) {
      final row = Map<String, dynamic>.from(result.first);

      row['nombreCompleto'] = row['nombreCompleto']?.toString() ?? '';
      row['dni'] = row['dni']?.toString() ?? '';
      row['telefono'] = row['telefono']?.toString() ?? '';
      row['email'] = row['email']?.toString() ?? '';
      row['rol'] = row['rol']?.toString() ?? 'socio';
      row['fechaCreacion'] = row['fechaCreacion']?.toString() ?? DateTime.now().toIso8601String();
      row['telegramChatId'] = row['telegramChatId']?.toString();
      row['activo'] = (row['activo'] is int) ? row['activo'] as int : 1;

      debugPrint('autenticarUsuario: usuario encontrado => $row');
      return row;
    }
    return null;
  }

  // --- MÉTODOS PARA SOCIOS (ACTUALIZADOS) ---

  Future<int> insertarSocio(Socio socio) async {
    Database db = await instance.database;
    return await db.insert('socios', socio.toMap());
  }

  Future<List<Socio>> getSocios() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('socios');
    return List.generate(maps.length, (i) => Socio.fromMap(maps[i]));
  }

  // Obtener socios pendientes de aprobación
  Future<List<Socio>> getSociosPendientes() async {
    Database db = await instance.database;
    final maps = await db.query(
      'socios',
      where: 'pendienteAprobacion = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => Socio.fromMap(maps[i]));
  }

  Future<int> updateSocio(Socio socio) async {
    Database db = await instance.database;
    return await db.update(
      'socios',
      socio.toMap(),
      where: 'id = ?',
      whereArgs: [socio.id],
    );
  }

  Future<int> deleteSocio(int id) async {
    Database db = await instance.database;
    return await db.delete(
      'socios',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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

  Future<int> deleteUsuario(int id) async {
    Database db = await instance.database;
    return await db.delete(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- MÉTODOS PARA PAGOS (NUEVOS) ---

  // Insertar un pago
  Future<int> insertarPago(int socioId, double amount, DateTime date, String method, {int? usuarioId}) async {
    Database db = await instance.database;
    return await db.insert('pagos', {
      'socioId': socioId,
      'usuarioId': usuarioId,
      'amount': amount,
      'date': date.toIso8601String(),
      'method': method,
    });
  }

  // Obtener todos los pagos de un socio
  Future<List<Map<String, dynamic>>> getPagosPorSocio(int socioId) async {
    Database db = await instance.database;
    return await db.query(
      'pagos',
      where: 'socioId = ?',
      whereArgs: [socioId],
      orderBy: 'date DESC',
    );
  }

  // Obtener ingresos diarios (de un día específico)
  Future<double> getIngresosDiarios(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM pagos 
      WHERE date >= ? AND date < ?
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Obtener ingresos mensuales (por tabla de pagos en lugar de cálculo de cuotas)
  Future<double> getIngresosMensualesPorPagos() async {
    final db = await database;
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);

    final result = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM pagos 
      WHERE date >= ? AND date <= ?
    ''', [firstDay.toIso8601String(), lastDay.toIso8601String()]);

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Eliminar un pago
  Future<int> deletePago(int id) async {
    Database db = await instance.database;
    return await db.delete(
      'pagos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Obtener resumen detallado de ingresos diarios con usuario que cobró
  Future<List<Map<String, dynamic>>> getResumenIngresosDiarios(DateTime date) async {
    final db = await database;
    final inicioDelDia = DateTime(date.year, date.month, date.day);
    final finDelDia = inicioDelDia.add(const Duration(days: 1));

    return await db.rawQuery('''
      SELECT 
        p.id,
        p.socioId,
        p.amount,
        p.date,
        p.method,
        s.nombreCompleto as socioNombre,
        u.nombreCompleto as usuarioNombre,
        u.rol as usuarioRol
      FROM pagos p
      LEFT JOIN socios s ON p.socioId = s.id
      LEFT JOIN usuarios u ON p.usuarioId = u.id
      WHERE p.date >= ? AND p.date < ?
      ORDER BY p.date DESC
    ''', [inicioDelDia.toIso8601String(), finDelDia.toIso8601String()]);
  }

}