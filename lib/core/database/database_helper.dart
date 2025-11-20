import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:gym/features/socios/models/socio.dart';
import 'package:gym/features/auth/models/usuario.dart';
import 'package:gym/features/planes/models/plan.dart'; // Importar el modelo Plan

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // SQL para tabla de planes
  static const String _createPlanesTableSql = '''
    CREATE TABLE planes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      precio REAL NOT NULL,
      duracionDias INTEGER,
      tiempoIndeterminado INTEGER DEFAULT 0,
      activo INTEGER DEFAULT 1,
      fechaCreacion TEXT NOT NULL,
      fechaActualizacion TEXT NOT NULL
    )
  ''';

  static const String _createPlanesTableIfNotExistsSql = '''
    CREATE TABLE IF NOT EXISTS planes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      precio REAL NOT NULL,
      duracionDias INTEGER,
      tiempoIndeterminado INTEGER DEFAULT 0,
      activo INTEGER DEFAULT 1,
      fechaCreacion TEXT NOT NULL,
      fechaActualizacion TEXT NOT NULL
    )
  ''';

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'gym_database.db');

    // ⚠️ INCREMENTA LA VERSIÓN para crear nuevas tablas
    return await openDatabase(
      path,
      version: 10, // Incrementado a 10 para agregar activo a socios
      onCreate: (db, version) async {
        // Crear tabla de usuarios primero
        await db.execute(_createUsuariosTableSql);
        // Crear tabla de socios
        await db.execute(_createSociosTableSql);
        // Crear tabla de pagos
        await db.execute(_createPagosTableSql);
        // Crear tabla de planes
        await db.execute(_createPlanesTableSql);
        // Crear tabla de asistencias
        await db.execute(_createAsistenciasTableSql);

        // Seed de admin para login de desarrollo
        await _crearUsuarioAdmin(db);
        // Crear planes por defecto
        await _crearPlanesPorDefecto(db);
      },
      onOpen: (db) async {
        // Asegurar tablas si faltan
        await db.execute(_createUsuariosTableIfNotExistsSql);
        await db.execute(_createSociosTableIfNotExistsSql);
        await db.execute(_createPagosTableIfNotExistsSql);
        await db.execute(_createPlanesTableIfNotExistsSql);
        await db.execute(_createAsistenciasTableIfNotExistsSql);
        
        // CORRECCIÓN: Asegurar que los socios existentes tengan activo = 1
        await db.rawUpdate('UPDATE socios SET activo = 1 WHERE activo IS NULL');
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
          oldVersion = 5; // Actualizar oldVersion para la siguiente migración
        }
        
        // Migración a la versión 6 - Añadir tabla de planes
        if (oldVersion == 5) {
          await db.execute(_createPlanesTableSql);
        }
        
        // Migración a la versión 9 - Añadir tiempoIndeterminado a planes
        if (oldVersion <= 8) {
          try {
            // Verificar si la columna ya existe
            final result = await db.rawQuery(
              'PRAGMA table_info(planes)'
            );
            
            final hasTiempoIndeterminado = result.any((col) => 
              col['name'] == 'tiempoIndeterminado');
              
            if (!hasTiempoIndeterminado) {
              await db.execute('''
                ALTER TABLE planes 
                ADD COLUMN tiempoIndeterminado INTEGER DEFAULT 0
              ''');
              
              // Actualizar duracionDias para que sea NULLABLE
              // SQLite no soporta MODIFY COLUMN directamente, así que hay que recrear la tabla
              await db.execute('''
                CREATE TABLE planes_new (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  nombre TEXT NOT NULL,
                  precio REAL NOT NULL,
                  duracionDias INTEGER,
                  tiempoIndeterminado INTEGER DEFAULT 0,
                  activo INTEGER DEFAULT 1,
                  fechaCreacion TEXT NOT NULL,
                  fechaActualizacion TEXT NOT NULL
                )
              ''');
              
              // Copiar datos existentes
              await db.execute('''
                INSERT INTO planes_new 
                (id, nombre, precio, duracionDias, activo, fechaCreacion, fechaActualizacion)
                SELECT id, nombre, precio, duracionDias, activo, fechaCreacion, fechaActualizacion 
                FROM planes
              ''');
              
              // Eliminar la tabla antigua y renombrar la nueva
              await db.execute('DROP TABLE planes');
              await db.execute('ALTER TABLE planes_new RENAME TO planes');
            }
          } catch (e) {
            debugPrint('Error durante la migración a la versión 9: $e');
            // Si hay un error, intentar crear la tabla desde cero
            try {
              await db.execute('DROP TABLE IF EXISTS planes');
              await db.execute(_createPlanesTableSql);
            } catch (e) {
              debugPrint('Error al recrear la tabla planes: $e');
            }
          }
          await _crearPlanesPorDefecto(db);
          oldVersion = 6; // Actualizar oldVersion para la siguiente migración
        }

        // Migración a la versión 7 - Añadir fechaActualizacion a planes
        if (oldVersion == 6) {
          try {
            await db.execute('ALTER TABLE planes ADD COLUMN fechaActualizacion TEXT');
            // Actualizar los registros existentes con la fecha actual
            await db.rawUpdate(
              'UPDATE planes SET fechaActualizacion = ?',
              [DateTime.now().toIso8601String()],
            );
            oldVersion = 7; // Actualizar oldVersion para la siguiente migración
          } catch (e) {
            if (!e.toString().contains('duplicate column name: fechaActualizacion')) {
              rethrow;
            }
            oldVersion = 7; // Asegurarse de que la versión se actualice incluso si la columna ya existe
          }
        }

        // Migración a la versión 8 - Añadir planId a socios
        if (oldVersion == 7) {
          try {
            // Verificar si la columna ya existe
            final result = await db.rawQuery('PRAGMA table_info(socios)');
            final hasPlanId = result.any((column) => column['name'] == 'planId');
            
            if (!hasPlanId) {
              await db.execute('ALTER TABLE socios ADD COLUMN planId INTEGER');
              debugPrint('✅ Columna planId añadida a la tabla socios');
            } else {
              debugPrint('ℹ️ La columna planId ya existe en la tabla socios');
            }
          } catch (e) {
            debugPrint('❌ Error al agregar planId a socios: $e');
            // Continuar con la migración incluso si hay un error
          }
        }

        
        // Migración a la versión 10 - Añadir activo a socios
        if (oldVersion <= 9) {
          try {
            // Verificar si la columna ya existe
            final result = await db.rawQuery('PRAGMA table_info(socios)');
            final hasActivo = result.any((column) => column['name'] == 'activo');
            
            if (!hasActivo) {
              await db.execute('ALTER TABLE socios ADD COLUMN activo INTEGER DEFAULT 1');
              debugPrint('✅ Columna activo añadida a la tabla socios');
            } else {
              debugPrint('ℹ️ La columna activo ya existe en la tabla socios');
            }
          } catch (e) {
            debugPrint('❌ Error al agregar activo a socios: $e');
          }
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
      planId INTEGER,
      activo INTEGER DEFAULT 1,
      FOREIGN KEY (planId) REFERENCES planes (id)
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
      planId INTEGER,
      activo INTEGER NOT NULL DEFAULT 1,
      FOREIGN KEY (planId) REFERENCES planes (id)
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

  // NUEVO: SQL para tabla de asistencias
  static const String _createAsistenciasTableSql = '''
    CREATE TABLE asistencias (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      socioId INTEGER NOT NULL,
      fechaHora TEXT NOT NULL,
      estadoCuota TEXT NOT NULL,
      FOREIGN KEY (socioId) REFERENCES socios(id) ON DELETE CASCADE
    )
  ''';

  static const String _createAsistenciasTableIfNotExistsSql = '''
    CREATE TABLE IF NOT EXISTS asistencias (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      socioId INTEGER NOT NULL,
      fechaHora TEXT NOT NULL,
      estadoCuota TEXT NOT NULL,
      FOREIGN KEY (socioId) REFERENCES socios(id) ON DELETE CASCADE
    )
  ''';

  // Crear planes por defecto
  static Future<void> _crearPlanesPorDefecto(Database db) async {
    final planes = [
      Plan(
        nombre: 'Mensual',
        precio: 5000.0,
        duracionDias: 30,
        activo: true,
      ),
      Plan(
        nombre: 'Trimestral',
        precio: 13500.0, // 10% de descuento
        duracionDias: 90,
        activo: true,
      ),
      Plan(
        nombre: 'Semestral',
        precio: 24000.0, // 20% de descuento
        duracionDias: 180,
        activo: true,
      ),
    ];

    for (var plan in planes) {
      try {
        await db.insert('planes', plan.toMap());
      } catch (e) {
        // Ignorar si ya existe
        if (!e.toString().contains('UNIQUE constraint failed')) {
          rethrow;
        }
      }
    }
  }

  // Crear usuario admin
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

  // --- MÉTODOS PARA PLANES ---

  // Insertar un nuevo plan
  Future<int> insertarPlan(Plan plan) async {
    final db = await database;
    // Asegurarse de que la fecha de actualización sea la actual
    final planConFechas = plan.copyWith(
      fechaCreacion: plan.fechaCreacion ?? DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
    return await db.insert('planes', planConFechas.toMap());
  }

  // Obtener todos los planes
  Future<List<Plan>> getPlanes({bool soloActivos = true}) async {
    final db = await database;
    final where = soloActivos ? 'WHERE activo = 1' : '';
    final orderBy = 'ORDER BY nombre';
    final query = 'SELECT * FROM planes $where $orderBy';
    
    if (kDebugMode) {
      debugPrint('🔍 [DatabaseHelper] Ejecutando consulta de planes:');
      debugPrint('   ├─ Query: $query');
      debugPrint('   └─ soloActivos: $soloActivos');
    }
    
    try {
      final result = await db.rawQuery(query);
      
      if (kDebugMode) {
        debugPrint('✅ [DatabaseHelper] Se encontraron ${result.length} planes');
        if (result.isEmpty) {
          // Verificar si hay planes en la base de datos
          final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM planes'));
          debugPrint('   ℹ️  Total de planes en la base de datos: $count');
          final countActivos = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM planes WHERE activo = 1'));
          debugPrint('   ℹ️  Planes activos: $countActivos');
        }
      }
      
      return result.map((map) => Plan.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ [DatabaseHelper] Error al obtener planes: $e');
      rethrow;
    }
  }

  // Obtener un plan por ID
  Future<Plan?> getPlan(int id) async {
    final db = await database;
    final result = await db.query('planes', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? Plan.fromMap(result.first) : null;
  }
  
  // Obtener un socio por ID
  Future<Socio?> getSocio(int id) async {
    final db = await database;
    final result = await db.query('socios', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? Socio.fromMap(result.first) : null;
  }

  // Actualizar un plan existente
  Future<int> actualizarPlan(Plan plan) async {
    final db = await database;
    // Actualizar la fecha de actualización al momento de actualizar
    final planActualizado = plan.copyWith(fechaActualizacion: DateTime.now());
    return await db.update(
      'planes',
      planActualizado.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  // Desactivar un plan (borrado lógico)
  Future<int> desactivarPlan(int id) async {
    final db = await database;
    return await db.rawUpdate(
      'UPDATE planes SET activo = 0 WHERE id = ?',
      [id],
    );
  }

  // Obtener planes para mostrar en formularios
  Future<List<Map<String, dynamic>>> getPlanesParaFormulario() async {
    final planes = await getPlanes(soloActivos: true);
    return planes.map((plan) => {
      'id': plan.id,
      'nombre': '${plan.nombre} - \$${plan.precio.toStringAsFixed(2)}',
      'precio': plan.precio,
      'duracionDias': plan.duracionDias,
    }).toList();
  }

  // --- MÉTODOS PARA USUARIOS ---

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
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'socios',
      where: 'activo = ?',
      whereArgs: [1],
    );

    return List.generate(maps.length, (i) {
      return Socio.fromMap(maps[i]);
    });
  }

  // NUEVO: Obtener socios inactivos
  Future<List<Socio>> getSociosInactivos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'socios',
      where: 'activo = ?',
      whereArgs: [0],
    );

    return List.generate(maps.length, (i) {
      return Socio.fromMap(maps[i]);
    });
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

  // Obtener socios por plan
  Future<List<Socio>> getSociosPorPlan(int planId) async {
    final db = await database;
    final result = await db.query(
      'socios',
      where: 'planId = ?',
      whereArgs: [planId],
    );
    return result.map((map) => Socio.fromMap(map)).toList();
  }

  // MODIFICADO: Soft delete (baja lógica) con auditoría
  Future<void> deleteSocio(int id, {int? usuarioId, String? usuarioNombre}) async {
    final db = await database;
    await db.update(
      'socios',
      {'activo': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('🗑️ Socio ID:$id desactivado por usuario ID:$usuarioId ($usuarioNombre)');
  }

  // NUEVO: Reactivar socio con auditoría
  Future<void> reactivarSocio(int id, {int? usuarioId, String? usuarioNombre}) async {
    final db = await database;
    await db.update(
      'socios',
      {'activo': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('♻️ Socio ID:$id reactivado por usuario ID:$usuarioId ($usuarioNombre)');
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

  // --- MÉTODOS PARA ASISTENCIAS ---

  // Buscar socio por DNI
  Future<Socio?> getSocioPorDni(String dni) async {
    final db = await database;
    final result = await db.query(
      'socios',
      where: 'dni = ? AND activo = 1',
      whereArgs: [dni],
    );
    return result.isNotEmpty ? Socio.fromMap(result.first) : null;
  }

  // Registrar asistencia
  Future<int> registrarAsistencia(int socioId, String estadoCuota) async {
    final db = await database;
    return await db.insert('asistencias', {
      'socioId': socioId,
      'fechaHora': DateTime.now().toIso8601String(),
      'estadoCuota': estadoCuota,
    });
  }

  // Obtener asistencias del día
  Future<int> getAsistenciasHoy() async {
    final db = await database;
    final now = DateTime.now();
    final inicioDelDia = DateTime(now.year, now.month, now.day);
    final finDelDia = inicioDelDia.add(const Duration(days: 1));

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM asistencias 
      WHERE fechaHora >= ? AND fechaHora < ?
    ''', [inicioDelDia.toIso8601String(), finDelDia.toIso8601String()]);

    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  // Obtener últimas asistencias
  Future<List<Map<String, dynamic>>> getUltimasAsistencias({int limit = 10}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        a.id,
        a.fechaHora,
        a.estadoCuota,
        s.nombreCompleto as socioNombre,
        s.dni as socioDni
      FROM asistencias a
      LEFT JOIN socios s ON a.socioId = s.id
      ORDER BY a.fechaHora DESC
      LIMIT ?
    ''', [limit]);
  }
}