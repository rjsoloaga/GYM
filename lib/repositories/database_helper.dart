import 'package:sqflite/sqflite.dart'; // PAra la DB
import 'package:path/path.dart'; // Para unir rutas de directorios
import 'package:gym/models/socio.dart';


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
            version: 1, //version de la db(util para futuras actualizaciones)
            onCreate: _createTable, //Funcion que ejecuta al crear la db por primera vez
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
                fechaInicio TEXT NOT NULL,             -- Las fechas se guardan como TEXT en formato ISO
                fechaVencimiento TEXT NOT NULL,
                precioMensual REAL NOT NULL,           -- REAL es para números con decimales
                tipoPlan TEXT NOT NULL
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

}