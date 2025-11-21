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

  // SQL para tabla de auditoría
  static const String _createAuditoriaTableSql = '''
    CREATE TABLE auditoria_socios (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      socioId INTEGER NOT NULL,
      accion TEXT NOT NULL, -- 'ELIMINAR', 'REACTIVAR'
      usuarioId INTEGER,
      usuarioNombre TEXT,
      fechaHora TEXT NOT NULL,
      detalles TEXT
    )
  ''';

  static const String _createAuditoriaTableIfNotExistsSql = '''
    CREATE TABLE IF NOT EXISTS auditoria_socios (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      socioId INTEGER NOT NULL,
      accion TEXT NOT NULL,
      usuarioId INTEGER,
      usuarioNombre TEXT,
      fechaHora TEXT NOT NULL,
      detalles TEXT
    )
  ''';

  static const String _createRecordatoriosTableSql = '''
    CREATE TABLE recordatorios_enviados (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      socioId INTEGER NOT NULL,
      tipo TEXT NOT NULL,
      canal TEXT NOT NULL,
      fechaEnvio TEXT NOT NULL,
      exitoso INTEGER NOT NULL DEFAULT 1,
      detalles TEXT,
      FOREIGN KEY (socioId) REFERENCES socios (id)
    )
  ''';

  static const String _createRecordatoriosTableIfNotExistsSql = '''
    CREATE TABLE IF NOT EXISTS recordatorios_enviados (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      socioId INTEGER NOT NULL,
      tipo TEXT NOT NULL,
      canal TEXT NOT NULL,
      fechaEnvio TEXT NOT NULL,
      exitoso INTEGER NOT NULL DEFAULT 1,
      detalles TEXT,
      FOREIGN KEY (socioId) REFERENCES socios (id)
    )
  ''';

  static const String _createPlantillasTableSql = '''
    CREATE TABLE plantillas_recordatorios (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tipo TEXT NOT NULL,
      canal TEXT NOT NULL,
      asunto TEXT,
      contenido TEXT NOT NULL,
      activa INTEGER NOT NULL DEFAULT 1
    )
  ''';

  static const String _createPlantillasTableIfNotExistsSql = '''
    CREATE TABLE IF NOT EXISTS plantillas_recordatorios (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tipo TEXT NOT NULL,
      canal TEXT NOT NULL,
      asunto TEXT,
      contenido TEXT NOT NULL,
      activa INTEGER NOT NULL DEFAULT 1
    )
  ''';

  // === NUEVAS TABLAS PARA EJERCICIOS Y RUTINAS ===

  // SQL para tabla de ejercicios
  static const String _createEjerciciosTableSql = '''
    CREATE TABLE ejercicios (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      descripcion TEXT,
      grupoMuscular TEXT,
      videoUrl TEXT,
      activo INTEGER DEFAULT 1
    )
  ''';

  // SQL para tabla de rutinas
  static const String _createRutinasTableSql = '''
    CREATE TABLE rutinas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      descripcion TEXT,
      nivel TEXT, -- 'Principiante', 'Intermedio', 'Avanzado'
      activo INTEGER DEFAULT 1,
      fechaCreacion TEXT NOT NULL
    )
  ''';

  // SQL para tabla pivote rutina_ejercicios
  static const String _createRutinaEjerciciosTableSql = '''
    CREATE TABLE rutina_ejercicios (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      rutinaId INTEGER NOT NULL,
      ejercicioId INTEGER NOT NULL,
      orden INTEGER NOT NULL,
      series INTEGER,
      repeticiones INTEGER,
      descansoSegundos INTEGER,
      notas TEXT,
      FOREIGN KEY (rutinaId) REFERENCES rutinas (id) ON DELETE CASCADE,
      FOREIGN KEY (ejercicioId) REFERENCES ejercicios (id)
    )
  ''';

  // SQL para asignación de rutinas a socios
  static const String _createAsignacionRutinasTableSql = '''
    CREATE TABLE asignacion_rutinas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      socioId INTEGER NOT NULL,
      rutinaId INTEGER NOT NULL,
      fechaAsignacion TEXT NOT NULL,
      fechaFin TEXT,
      activa INTEGER DEFAULT 1,
      notas TEXT,
      FOREIGN KEY (socioId) REFERENCES socios (id) ON DELETE CASCADE,
      FOREIGN KEY (rutinaId) REFERENCES rutinas (id)
    )
  ''';


  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'gym_database.db');

    // ⚠️ INCREMENTA LA VERSIÓN para crear nuevas tablas
    return await openDatabase(
      path,
      version: 15, // Incrementado a 15 para agregar rutinas y ejercicios
      onCreate: (db, version) async {
        // Crear tabla de usuarios primero
        await db.execute(_createUsuariosTableSql);
        
        // Crear tabla de planes
        await db.execute(_createPlanesTableSql);
        
        // Crear tabla de socios
        await db.execute(_createSociosTableSql);
        
        // Crear tabla de auditoría
        await db.execute(_createAuditoriaTableSql);

        // Crear tabla de recordatorios
        await db.execute(_createRecordatoriosTableSql);

        // Crear tabla de plantillas
        await db.execute(_createPlantillasTableSql);

        // Crear tablas de ejercicios y rutinas
        await db.execute(_createEjerciciosTableSql);
        await db.execute(_createRutinasTableSql);
        await db.execute(_createRutinaEjerciciosTableSql);
        await db.execute(_createAsignacionRutinasTableSql);
        
        // Insertar planes por defecto
        await _crearPlanesPorDefecto(db);

        // Insertar plantillas por defecto
        await _crearPlantillasPorDefecto(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        debugPrint('🔄 Actualizando base de datos de versión $oldVersion a $newVersion');
        
        // Migración de versión 14 a 15: Añadir tablas de rutinas
        if (oldVersion < 15) {
          try {
            await db.execute(_createEjerciciosTableSql);
            await db.execute(_createRutinasTableSql);
            await db.execute(_createRutinaEjerciciosTableSql);
            await db.execute(_createAsignacionRutinasTableSql);
            debugPrint('✅ Tablas de ejercicios y rutinas creadas correctamente');
          } catch (e) {
            debugPrint('⚠️ Error creando tablas de rutinas (pueden ya existir): $e');
          }
        }

        // Migración de versión 13 a 14: Añadir fechaNacimiento
        if (oldVersion < 14) {
          try {
            await db.execute('ALTER TABLE socios ADD COLUMN fechaNacimiento TEXT');
            debugPrint('✅ Campo fechaNacimiento añadido a tabla socios');
          } catch (e) {
            debugPrint('⚠️ Error añadiendo fechaNacimiento (puede que ya exista): $e');
          }
        }
        
        // Migraciones anteriores...
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
            debugPrint('Error al añadir columna planId: $e');
          }
          oldVersion = 8;
        }
        
        // Migración a la versión 10 - Añadir columna activo a socios
        if (oldVersion == 8 || oldVersion == 9) {
          try {
            final result = await db.rawQuery('PRAGMA table_info(socios)');
            final hasActivo = result.any((column) => column['name'] == 'activo');
            
            if (!hasActivo) {
              await db.execute('ALTER TABLE socios ADD COLUMN activo INTEGER DEFAULT 1');
              debugPrint('✅ Columna activo añadida a la tabla socios');
            }
          } catch (e) {
            debugPrint('Error al añadir columna activo: $e');
          }
          oldVersion = 10;
        }

        // Migración a la versión 11 - Añadir tabla de auditoría
        if (oldVersion == 10) {
          await db.execute(_createAuditoriaTableSql);
          debugPrint('✅ Tabla auditoria_socios creada');
          oldVersion = 11;
        }
      },
      onOpen: (db) async {
        // Asegurar tablas si faltan
        await db.execute(_createUsuariosTableIfNotExistsSql);
        await db.execute(_createSociosTableIfNotExistsSql);
        await db.execute(_createPagosTableIfNotExistsSql);
        await db.execute(_createPlanesTableIfNotExistsSql);
        await db.execute(_createAsistenciasTableIfNotExistsSql);
        await db.execute(_createAuditoriaTableIfNotExistsSql);
        await db.execute(_createRecordatoriosTableIfNotExistsSql);
        await db.execute(_createPlantillasTableIfNotExistsSql);
        
        // CORRECCIÓN: Asegurar que los socios existentes tengan activo = 1
        await db.rawUpdate('UPDATE socios SET activo = 1 WHERE activo IS NULL');
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
      fechaNacimiento TEXT,
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
      fechaNacimiento TEXT,
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

  // Crear plantillas por defecto
  static Future<void> _crearPlantillasPorDefecto(Database db) async {
    final plantillas = [
      // === CUOTA PRÓXIMA - EMAIL ===
      {
        'tipo': 'cuota_proxima',
        'canal': 'email',
        'asunto': '🏋️ Recordatorio: Tu cuota vence en {dias} días',
        'contenido': '''<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .highlight { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
        .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🏋️ Recordatorio de Cuota</h1>
        </div>
        <div class="content">
            <h2>Hola {nombre},</h2>
            <div class="highlight">
                <strong>Tu cuota vence en {dias} días</strong> (el {fecha})
            </div>
            <p>Para continuar disfrutando de nuestras instalaciones sin interrupciones, te sugerimos realizar el pago antes de la fecha de vencimiento.</p>
            <p>Si ya realizaste el pago, por favor ignora este mensaje.</p>
            <p>¡Gracias por ser parte de {gimnasio}!</p>
            <p><strong>Contacto:</strong> {telefono} | {email}</p>
        </div>
        <div class="footer">
            <p>Este es un mensaje automático. Por favor no respondas a este email.</p>
        </div>
    </div>
</body>
</html>''',
        'activa': 1,
      },
      
      // === CUOTA PRÓXIMA - TELEGRAM ===
      {
        'tipo': 'cuota_proxima',
        'canal': 'telegram',
        'asunto': null,
        'contenido': '''🏋️ *Recordatorio de Cuota*

Hola {nombre_corto},

Tu cuota vence en *{dias} días* (el {fecha}).

Para continuar disfrutando de nuestras instalaciones sin interrupciones, te sugerimos realizar el pago antes de la fecha de vencimiento.

Si ya realizaste el pago, por favor ignora este mensaje.

¡Gracias por ser parte de {gimnasio}! 💪

📞 {telefono}''',
        'activa': 1,
      },
      
      // === CUOTA VENCIDA - EMAIL ===
      {
        'tipo': 'cuota_vencida',
        'canal': 'email',
        'asunto': '⚠️ Tu cuota de {gimnasio} está vencida',
        'contenido': '''<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .alert { background: #fff3cd; border-left: 4px solid #dc3545; padding: 15px; margin: 20px 0; }
        .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>⚠️ Cuota Vencida</h1>
        </div>
        <div class="content">
            <h2>Hola {nombre},</h2>
            <div class="alert">
                <strong>Tu cuota venció el {fecha}</strong>
            </div>
            <p>Para continuar utilizando nuestras instalaciones, te pedimos que regularices tu situación a la brevedad.</p>
            <p>Si ya realizaste el pago, por favor comunícate con nosotros para actualizar tu estado.</p>
            <p>¡Esperamos verte pronto en {gimnasio}!</p>
            <p><strong>Contacto:</strong> {telefono} | {email}</p>
        </div>
        <div class="footer">
            <p>Este es un mensaje automático. Por favor no respondas a este email.</p>
        </div>
    </div>
</body>
</html>''',
        'activa': 1,
      },
      
      // === CUOTA VENCIDA - TELEGRAM ===
      {
        'tipo': 'cuota_vencida',
        'canal': 'telegram',
        'asunto': null,
        'contenido': '''⚠️ *Cuota Vencida*

Hola {nombre_corto},

Tu cuota venció el {fecha}.

Para continuar utilizando nuestras instalaciones, te pedimos que regularices tu situación a la brevedad.

Si ya realizaste el pago, por favor comunícate con nosotros para actualizar tu estado.

¡Esperamos verte pronto! 🏋️

📞 {telefono}''',
        'activa': 1,
      },
      
      // === CUMPLEAÑOS - EMAIL ===
      {
        'tipo': 'cumpleanos',
        'canal': 'email',
        'asunto': '🎉 ¡Feliz Cumpleaños, {nombre_corto}!',
        'contenido': '''<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%); color: #333; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; text-align: center; }
        .emoji { font-size: 48px; }
        .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="emoji">🎉🎂🎈</div>
            <h1>¡Feliz Cumpleaños!</h1>
        </div>
        <div class="content">
            <h2>¡Feliz cumpleaños, {nombre}!</h2>
            <p>Todo el equipo de {gimnasio} te desea un día increíble lleno de alegría y salud.</p>
            <p>¡Gracias por ser parte de nuestra familia fitness!</p>
            <p>🎁 <strong>Sorpresa:</strong> Consulta en recepción por tu regalo de cumpleaños 😊</p>
            <p><strong>Contacto:</strong> {telefono} | {email}</p>
        </div>
        <div class="footer">
            <p>Este es un mensaje automático. Por favor no respondas a este email.</p>
        </div>
    </div>
</body>
</html>''',
        'activa': 1,
      },
      
      // === CUMPLEAÑOS - TELEGRAM ===
      {
        'tipo': 'cumpleanos',
        'canal': 'telegram',
        'asunto': null,
        'contenido': '''🎉🎂🎈 *¡Feliz Cumpleaños!*

¡Feliz cumpleaños, {nombre}!

Todo el equipo de {gimnasio} te desea un día increíble lleno de alegría y salud.

¡Gracias por ser parte de nuestra familia fitness!

🎁 *Sorpresa:* Consulta en recepción por tu regalo de cumpleaños 😊

📞 {telefono}''',
        'activa': 1,
      },
    ];

    for (var plantilla in plantillas) {
      try {
        await db.insert('plantillas_recordatorios', plantilla);
      } catch (e) {
        // Ignorar si ya existe
        debugPrint('Plantilla ya existe: ${plantilla['tipo']}-${plantilla['canal']}');
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
  // MODIFICADO: Soft delete (baja lógica) con auditoría
  Future<void> deleteSocio(int id, {int? usuarioId, String? usuarioNombre}) async {
    final db = await database;
    await db.update(
      'socios',
      {'activo': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // Registrar en auditoría
    await _insertarAuditoria(
      socioId: id,
      accion: 'ELIMINAR',
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
      detalles: 'Socio desactivado (baja lógica)',
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
    
    // Registrar en auditoría
    await _insertarAuditoria(
      socioId: id,
      accion: 'REACTIVAR',
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
      detalles: 'Socio reactivado',
    );
    
    debugPrint('♻️ Socio ID:$id reactivado por usuario ID:$usuarioId ($usuarioNombre)');
  }

  // Método privado para insertar auditoría
  Future<void> _insertarAuditoria({
    required int socioId,
    required String accion,
    int? usuarioId,
    String? usuarioNombre,
    String? detalles,
  }) async {
    try {
      final db = await database;
      await db.insert('auditoria_socios', {
        'socioId': socioId,
        'accion': accion,
        'usuarioId': usuarioId,
        'usuarioNombre': usuarioNombre,
        'fechaHora': DateTime.now().toIso8601String(),
        'detalles': detalles,
      });
    } catch (e) {
      debugPrint('Error al registrar auditoría: $e');
    }
  }

  // Obtener historial de auditoría
  Future<List<Map<String, dynamic>>> getAuditoria({int limit = 50}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        a.id,
        a.accion,
        a.usuarioNombre,
        a.fechaHora,
        a.detalles,
        s.nombreCompleto as socioNombre,
        s.dni as socioDni
      FROM auditoria_socios a
      LEFT JOIN socios s ON a.socioId = s.id
      ORDER BY a.fechaHora DESC
      LIMIT ?
    ''', [limit]);
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

  // Obtener ingresos de los últimos N días para gráficos
  Future<List<Map<String, dynamic>>> getIngresosUltimosDias({int dias = 7}) async {
    final db = await database;
    final now = DateTime.now();
    final resultado = <Map<String, dynamic>>[];

    for (int i = dias - 1; i >= 0; i--) {
      final fecha = now.subtract(Duration(days: i));
      final startOfDay = DateTime(fecha.year, fecha.month, fecha.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final result = await db.rawQuery('''
        SELECT SUM(amount) as total 
        FROM pagos 
        WHERE date >= ? AND date < ?
      ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

      final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
      
      resultado.add({
        'fecha': startOfDay,
        'total': total,
      });
    }

    return resultado;
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

  Future<Map<String, dynamic>?> getSocioPorTelefono(String telefono) async {
    final db = await database;
    final result = await db.query(
      'socios',
      where: 'telefono = ? AND activo = 1',
      whereArgs: [telefono],
    );
    return result.isNotEmpty ? result.first : null;
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

  // Obtener asistencias agrupadas por día de la semana (últimos 30 días)
  Future<Map<String, int>> getAsistenciasPorDiaSemana() async {
    final db = await database;
    final now = DateTime.now();
    final hace30Dias = now.subtract(const Duration(days: 30));

    final result = await db.rawQuery('''
      SELECT 
        CAST(strftime('%w', fechaHora) AS INTEGER) as diaSemana,
        COUNT(*) as count
      FROM asistencias
      WHERE fechaHora >= ?
      GROUP BY diaSemana
      ORDER BY diaSemana
    ''', [hace30Dias.toIso8601String()]);

    // Mapear números a nombres de días (0=Domingo, 1=Lunes, etc.)
    final dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    final Map<String, int> estadisticas = {};
    
    // Inicializar todos los días en 0
    for (var dia in dias) {
      estadisticas[dia] = 0;
    }
    
    // Llenar con datos reales
    for (var row in result) {
      final diaSemana = (row['diaSemana'] as int?) ?? 0;
      final count = (row['count'] as int?) ?? 0;
      estadisticas[dias[diaSemana]] = count;
    }

    return estadisticas;
  }

  // Obtener socios que no asisten hace X días
  Future<List<Map<String, dynamic>>> getSociosSinAsistir({int dias = 30}) async {
    final db = await database;
    final now = DateTime.now();
    final fechaLimite = now.subtract(Duration(days: dias));

    return await db.rawQuery('''
      SELECT 
        s.id,
        s.nombreCompleto,
        s.dni,
        s.telefono,
        MAX(a.fechaHora) as ultimaAsistencia,
        CAST((julianday('now') - julianday(MAX(a.fechaHora))) AS INTEGER) as diasSinAsistir
      FROM socios s
      LEFT JOIN asistencias a ON s.id = a.socioId
      WHERE s.activo = 1
      GROUP BY s.id
      HAVING ultimaAsistencia IS NULL OR ultimaAsistencia < ?
      ORDER BY ultimaAsistencia ASC
    ''', [fechaLimite.toIso8601String()]);
  }

  // ============================================================================
  // MÉTODOS DE RECORDATORIOS
  // ============================================================================

  // Registrar envío de recordatorio
  Future<int> registrarRecordatorio({
    required int socioId,
    required String tipo, // 'cuota_proxima', 'cuota_vencida', 'cumpleanos'
    required String canal, // 'email', 'telegram', 'ambos'
    required bool exitoso,
    String? detalles,
  }) async {
    final db = await database;
    return await db.insert('recordatorios_enviados', {
      'socioId': socioId,
      'tipo': tipo,
      'canal': canal,
      'fechaEnvio': DateTime.now().toIso8601String(),
      'exitoso': exitoso ? 1 : 0,
      'detalles': detalles,
    });
  }

  // Verificar si ya se envió un recordatorio hoy
  Future<bool> yaSeEnvioHoy({
    required int socioId,
    required String tipo,
  }) async {
    final db = await database;
    final hoy = DateTime.now();
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final finHoy = inicioHoy.add(const Duration(days: 1));

    final result = await db.query(
      'recordatorios_enviados',
      where: 'socioId = ? AND tipo = ? AND fechaEnvio >= ? AND fechaEnvio < ?',
      whereArgs: [
        socioId,
        tipo,
        inicioHoy.toIso8601String(),
        finHoy.toIso8601String(),
      ],
    );

    return result.isNotEmpty;
  }

  // Obtener socios con cuota próxima a vencer
  Future<List<Map<String, dynamic>>> getSociosCuotaPorVencer({int diasAnticipacion = 3}) async {
    final db = await database;
    final hoy = DateTime.now();
    final fechaLimite = hoy.add(Duration(days: diasAnticipacion));
    final fechaLimiteStr = DateTime(fechaLimite.year, fechaLimite.month, fechaLimite.day).toIso8601String();
    final hoyStr = DateTime(hoy.year, hoy.month, hoy.day).toIso8601String();

    return await db.rawQuery('''
      SELECT 
        s.id,
        s.nombreCompleto,
        s.email,
        s.telefono,
        s.fechaVencimiento,
        CAST((julianday(s.fechaVencimiento) - julianday('now')) AS INTEGER) as diasRestantes
      FROM socios s
      WHERE s.activo = 1
        AND s.fechaVencimiento >= ?
        AND s.fechaVencimiento < ?
      ORDER BY s.fechaVencimiento ASC
    ''', [hoyStr, fechaLimiteStr]);
  }

  // Obtener socios con cuota vencida
  Future<List<Map<String, dynamic>>> getSociosCuotaVencida() async {
    final db = await database;
    final hoy = DateTime.now();
    final hoyStr = DateTime(hoy.year, hoy.month, hoy.day).toIso8601String();

    return await db.rawQuery('''
      SELECT 
        s.id,
        s.nombreCompleto,
        s.email,
        s.telefono,
        s.fechaVencimiento,
        CAST((julianday('now') - julianday(s.fechaVencimiento)) AS INTEGER) as diasVencidos
      FROM socios s
      WHERE s.activo = 1
        AND s.fechaVencimiento < ?
      ORDER BY s.fechaVencimiento ASC
    ''', [hoyStr]);
  }

  // Obtener socios con cumpleaños hoy
  Future<List<Map<String, dynamic>>> getSociosCumpleanosHoy() async {
    final db = await database;
    final hoy = DateTime.now();
    final mesHoy = hoy.month.toString().padLeft(2, '0');
    final diaHoy = hoy.day.toString().padLeft(2, '0');

    return await db.rawQuery('''
      SELECT 
        s.id,
        s.nombreCompleto,
        s.email,
        s.telefono,
        s.fechaNacimiento
      FROM socios s
      WHERE s.activo = 1
        AND substr(s.fechaNacimiento, 6, 2) = ?
        AND substr(s.fechaNacimiento, 9, 2) = ?
    ''', [mesHoy, diaHoy]);
  }

  // Obtener historial de recordatorios
  Future<List<Map<String, dynamic>>> getHistorialRecordatorios({int limit = 100}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        r.*,
        s.nombreCompleto,
        s.dni
      FROM recordatorios_enviados r
      INNER JOIN socios s ON r.socioId = s.id
      ORDER BY r.fechaEnvio DESC
      LIMIT ?
    ''', [limit]);
  }
}