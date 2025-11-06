import 'package:sqflite/sqflite.dart'; // PAra la DB
import 'package:path/path.dart'; // Para unir rutas de directorios
import 'package:gym/models/socio.dart';
import 'package:gym/models/pago.dart';


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
        try {
            //Obtenemos la ruta del dispositivo donde guardamos la base de datos
            String path = join(await getDatabasesPath(), 'gym_database.db');
            
            //Abre o crea la base de datos en la ruta especificada
            final db = await openDatabase(
                path,
                version: 4, // Incrementado para agregar tabla de pagos
                onCreate: _createTable, //Funcion que ejecuta al crear la db por primera vez
                onUpgrade: (db, oldVersion, newVersion) async {
                  // Si la versión es 1 y necesitamos actualizar a 2, crear la tabla de usuarios
                  if (oldVersion < 2) {
                    await db.execute('''
                      CREATE TABLE IF NOT EXISTS usuario(
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        username TEXT NOT NULL UNIQUE,
                        password TEXT NOT NULL,
                        nombre TEXT NOT NULL
                      )
                    ''');
                    await _crearUsuarioPorDefecto(db);
                  }
                  // Si la versión es menor a 3, agregar la columna correo a la tabla socio
                  if (oldVersion < 3) {
                    await db.execute('''
                      ALTER TABLE socio ADD COLUMN correo TEXT DEFAULT ''
                    ''');
                    print('✅ Columna correo agregada a la tabla socio');
                  }
                  // Si la versión es menor a 4, crear la tabla de pagos
                  if (oldVersion < 4) {
                    await db.execute('''
                      CREATE TABLE IF NOT EXISTS pago(
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        socioId INTEGER NOT NULL,
                        monto REAL NOT NULL,
                        fecha TEXT NOT NULL,
                        metodoPago TEXT NOT NULL,
                        observaciones TEXT,
                        FOREIGN KEY (socioId) REFERENCES socio(id) ON DELETE CASCADE
                      )
                    ''');
                    print('✅ Tabla pago creada correctamente');
                  }
                },
            );
            return db;
        } catch (e) {
            print('Error al inicializar base de datos: $e');
            rethrow;
        }
    }

    //Metodo para crear la tabla 'socios'
    Future<void> _createTable(Database db, int version) async {
        try {
            //Ejecutamos un comando SQL para crear la tabla de usuarios
            await db.execute('''
                CREATE TABLE IF NOT EXISTS usuario(
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    username TEXT NOT NULL UNIQUE,
                    password TEXT NOT NULL,
                    nombre TEXT NOT NULL
                )
            ''');

            //Ejecutamos un comando SQL para crear la tabla de socios
            await db.execute('''
                CREATE TABLE IF NOT EXISTS socio(
                    id INTEGER PRIMARY KEY AUTOINCREMENT, -- El ID se genera automáticamente
                    nombreCompleto TEXT NOT NULL,          -- NOT NULL significa que es obligatorio
                    dni TEXT NOT NULL UNIQUE,              -- UNIQUE asegura que no haya dos DNIs iguales
                    telefono TEXT NOT NULL,
                    correo TEXT NOT NULL,                  -- Correo electrónico
                    fechaInicio TEXT NOT NULL,             -- Las fechas se guardan como TEXT en formato ISO
                    fechaVencimiento TEXT NOT NULL,
                    precioMensual REAL NOT NULL,           -- REAL es para números con decimales
                    tipoPlan TEXT NOT NULL
                )
            ''');

            //Ejecutamos un comando SQL para crear la tabla de pagos
            await db.execute('''
                CREATE TABLE IF NOT EXISTS pago(
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    socioId INTEGER NOT NULL,
                    monto REAL NOT NULL,
                    fecha TEXT NOT NULL,
                    metodoPago TEXT NOT NULL,
                    observaciones TEXT,
                    FOREIGN KEY (socioId) REFERENCES socio(id) ON DELETE CASCADE
                )
            ''');

            // Crear usuario por defecto si no existe
            await _crearUsuarioPorDefecto(db);
            print('✅ Tablas creadas correctamente');
        } catch (e) {
            print('❌ Error al crear tablas: $e');
            rethrow;
        }
    }

    // Crear usuario administrador por defecto
    Future<void> _crearUsuarioPorDefecto(Database db) async {
        final usuarios = await db.query('usuario', where: 'username = ?', whereArgs: ['admin']);
        if (usuarios.isEmpty) {
            await db.insert('usuario', {
                'username': 'admin',
                'password': 'admin123', // En producción debería estar hasheado
                'nombre': 'Administrador'
            });
        }
    }

    // Métodos para manejo de usuarios
    Future<Map<String, dynamic>?> autenticarUsuario(String username, String password) async {
        Database db = await instance.database;
        final usuarios = await db.query(
            'usuario',
            where: 'username = ? AND password = ?',
            whereArgs: [username, password],
        );
        if (usuarios.isNotEmpty) {
            return usuarios.first;
        }
        return null;
    }

    Future<int> insertarUsuario(String username, String password, String nombre) async {
        Database db = await instance.database;
        return await db.insert('usuario', {
            'username': username,
            'password': password,
            'nombre': nombre,
        });
    }


    // --- Metodos CRUD (Create, Read, Update, Delete) ---

    //CREATE inserta un nuevo socio
    Future<int> insertarSocio(Socio socio) async {
        try {
            Database db = await instance.database; // Obtenemos la referencia de la DB

            // Insertamos el socio convertido a Map y obtenemos su ID automatico
            return await db.insert('socio', socio.toMap());
        } catch (e) {
            print('Error al insertar socio: $e');
            rethrow;
        }
    }

    //READ - obtener todos los socios
    Future<List<Socio>> getSocios() async {
        try {
            Database db = await instance.database;
            // Obtenemos una lista de Maps (cada Map representa una fila de la DB)
            final List<Map<String, dynamic>> maps = await db.query('socio');
            // Convertimos cada Map en una lista de un objeto Socio usando .fromMap()
            return List.generate(maps.length, (i) {
                return Socio.fromMap(maps[i]);
            });
        } catch (e) {
            print('Error al obtener socios: $e');
            rethrow;
        }
    }

    //UPDATE - actualizar un socio existente
    Future<int> updateSocio(Socio socio) async {
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

    // --- Métodos CRUD para Pagos ---

    // CREATE - Insertar un nuevo pago
    Future<int> insertarPago(Pago pago) async {
        try {
            Database db = await instance.database;
            return await db.insert('pago', pago.toMap());
        } catch (e) {
            print('Error al insertar pago: $e');
            rethrow;
        }
    }

    // READ - Obtener todos los pagos de un socio
    Future<List<Pago>> getPagosPorSocio(int socioId) async {
        try {
            Database db = await instance.database;
            final List<Map<String, dynamic>> maps = await db.query(
                'pago',
                where: 'socioId = ?',
                whereArgs: [socioId],
                orderBy: 'fecha DESC',
            );
            return List.generate(maps.length, (i) {
                return Pago.fromMap(maps[i]);
            });
        } catch (e) {
            print('Error al obtener pagos: $e');
            rethrow;
        }
    }

    // READ - Obtener todos los pagos
    Future<List<Pago>> getTodosLosPagos() async {
        try {
            Database db = await instance.database;
            final List<Map<String, dynamic>> maps = await db.query(
                'pago',
                orderBy: 'fecha DESC',
            );
            return List.generate(maps.length, (i) {
                return Pago.fromMap(maps[i]);
            });
        } catch (e) {
            print('Error al obtener todos los pagos: $e');
            rethrow;
        }
    }

    // READ - Obtener pagos en un rango de fechas
    Future<List<Pago>> getPagosPorFecha(DateTime fechaInicio, DateTime fechaFin) async {
        try {
            Database db = await instance.database;
            final List<Map<String, dynamic>> maps = await db.query(
                'pago',
                where: 'fecha >= ? AND fecha <= ?',
                whereArgs: [
                    fechaInicio.toIso8601String(),
                    fechaFin.toIso8601String(),
                ],
                orderBy: 'fecha DESC',
            );
            return List.generate(maps.length, (i) {
                return Pago.fromMap(maps[i]);
            });
        } catch (e) {
            print('Error al obtener pagos por fecha: $e');
            rethrow;
        }
    }

    // DELETE - Eliminar un pago
    Future<int> eliminarPago(int id) async {
        try {
            Database db = await instance.database;
            return await db.delete(
                'pago',
                where: 'id = ?',
                whereArgs: [id],
            );
        } catch (e) {
            print('Error al eliminar pago: $e');
            rethrow;
        }
    }

    // Métodos para estadísticas
    Future<double> getIngresosMensuales() async {
        try {
            final ahora = DateTime.now();
            final inicioMes = DateTime(ahora.year, ahora.month, 1);
            final finMes = DateTime(ahora.year, ahora.month + 1, 0, 23, 59, 59);

            final pagos = await getPagosPorFecha(inicioMes, finMes);
            double total = 0.0;
            for (var pago in pagos) {
                total += pago.monto;
            }
            return total;
        } catch (e) {
            print('Error al calcular ingresos mensuales: $e');
            return 0.0;
        }
    }

    Future<int> getTotalSocios() async {
        try {
            final socios = await getSocios();
            return socios.length;
        } catch (e) {
            return 0;
        }
    }

    Future<int> getCuotasVencidas() async {
        try {
            final socios = await getSocios();
            final ahora = DateTime.now();
            return socios.where((socio) {
                return socio.fechaVencimiento.isBefore(ahora);
            }).length;
        } catch (e) {
            return 0;
        }
    }

    Future<int> getCuotasPorVencer(int dias) async {
        try {
            final socios = await getSocios();
            final ahora = DateTime.now();
            final limite = ahora.add(Duration(days: dias));
            return socios.where((socio) {
                return socio.fechaVencimiento.isAfter(ahora) &&
                       socio.fechaVencimiento.isBefore(limite);
            }).length;
        } catch (e) {
            return 0;
        }
    }

    // Método para crear socios ficticios de prueba
    Future<void> crearSociosFicticios() async {
        try {
            final sociosExistentes = await getSocios();
            if (sociosExistentes.isNotEmpty) {
                print('ℹ️ Ya existen ${sociosExistentes.length} socios en la base de datos. No se crearán socios ficticios.');
                return;
            }

            final ahora = DateTime.now();
            final nombres = [
                'Juan Pérez', 'María González', 'Carlos Rodríguez', 'Ana Martínez', 'Luis Fernández',
                'Laura Sánchez', 'Diego López', 'Carmen García', 'Roberto Torres', 'Patricia Ramírez',
                'Miguel Herrera', 'Sofia Mendoza', 'Fernando Castro', 'Isabel Ruiz', 'Ricardo Morales',
                'Elena Vargas', 'Andrés Jiménez', 'Lucía Moreno', 'Javier Díaz', 'Andrea Silva',
                'Sergio Ríos', 'Valentina Vega', 'Daniel Ortega', 'Camila Navarro', 'Alejandro Medina',
                'Mariana Campos', 'Gabriel Peña', 'Natalia Rojas', 'Sebastián Cortés', 'Gabriela Guzmán',
            ];

            final tiposPlan = ['Mensual', 'Trimestral', 'Semestral', 'Anual'];
            final precios = [5000.0, 8000.0, 10000.0, 12000.0, 15000.0];

            for (int i = 0; i < 30; i++) {
                final dni = '${10000000 + i}';
                final telefonoNum = (1000000 + i * 12345).toString().padLeft(8, '0');
                final telefono = '11${telefonoNum.substring(0, 8)}';
                final correo = '${nombres[i].toLowerCase().replaceAll(' ', '.')}@email.com';
                
                // Variar el tipo de plan
                final tipoPlan = tiposPlan[i % tiposPlan.length];
                
                // Calcular días según el plan
                int diasPlan = 30;
                switch (tipoPlan) {
                    case 'Trimestral':
                        diasPlan = 90;
                        break;
                    case 'Semestral':
                        diasPlan = 180;
                        break;
                    case 'Anual':
                        diasPlan = 365;
                        break;
                }

                // Variar las fechas para tener diferentes estados
                DateTime fechaInicio;
                DateTime fechaVencimiento;
                
                if (i < 10) {
                    // Primeros 10: cuotas vencidas (hace 5-30 días)
                    fechaInicio = ahora.subtract(Duration(days: diasPlan + 20 + (i * 2)));
                    fechaVencimiento = ahora.subtract(Duration(days: 5 + (i * 2)));
                } else if (i < 20) {
                    // Siguientes 10: por vencer en los próximos 7 días
                    fechaInicio = ahora.subtract(Duration(days: diasPlan - 7 + (i - 10)));
                    fechaVencimiento = ahora.add(Duration(days: i - 10));
                } else {
                    // Últimos 10: al día (vence en más de 7 días)
                    fechaInicio = ahora.subtract(Duration(days: 10 + (i - 20)));
                    fechaVencimiento = ahora.add(Duration(days: 15 + (i - 20) * 5));
                }

                final precio = precios[i % precios.length];

                final socio = Socio(
                    nombreCompleto: nombres[i],
                    dni: dni,
                    telefono: telefono,
                    correo: correo,
                    fechaInicio: fechaInicio,
                    fechaVencimiento: fechaVencimiento,
                    precioMensual: precio,
                    tipoPlan: tipoPlan,
                );

                await insertarSocio(socio);
            }

            print('✅ 30 socios ficticios creados exitosamente');
        } catch (e) {
            print('❌ Error al crear socios ficticios: $e');
        }
    }

}