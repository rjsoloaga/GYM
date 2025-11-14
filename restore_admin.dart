import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Future<void> main() async {
  try {
    print('🔍 Conectando a la base de datos...');
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'gym_database.db');
    
    // Abrir la base de datos
    final db = await openDatabase(path);
    
    // Verificar si ya existe un usuario admin
    final result = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: ['admin@gym.com'],
    );
    
    if (result.isNotEmpty) {
      print('ℹ️ El usuario administrador ya existe en la base de datos.');
      await db.close();
      return;
    }
    
    // Insertar el usuario administrador
    print('➕ Creando usuario administrador...');
    await db.insert('usuarios', {
      'nombreCompleto': 'Administrador',
      'email': 'admin@gym.com',
      'telefono': 'admin',
      'dni': 'admin',
      'rol': 'admin',
      'fechaCreacion': DateTime.now().toIso8601String(),
      'activo': 1,
    });
    
    print('✅ Usuario administrador creado exitosamente!');
    print('   Email: admin@gym.com');
    print('   Contraseña: admin');
    
    await db.close();
  } catch (e) {
    print('❌ Error al crear el usuario administrador:');
    print(e);
  }
}
