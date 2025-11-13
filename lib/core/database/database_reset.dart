import 'package:gym/core/database/database_helper.dart';
import 'package:gym/features/auth/models/usuario.dart';

class DatabaseReset {
  static Future<void> resetAdminUser() async {
    print('🔄 RESTABLECIENDO USUARIO ADMIN...');
    
    try {
      final dbHelper = DatabaseHelper.instance;
      
      // 1. Eliminar admin existente si existe
      final usuarios = await dbHelper.getUsuarios();
      final adminExistente = usuarios.firstWhere(
        (user) => user.dni == 'admin',
        orElse: () => Usuario(
          nombreCompleto: '',
          email: '',
          telefono: '',
          dni: '',
          rol: '',
          fechaCreacion: DateTime.now(),
        ),
      );
      
      if (adminExistente.id != null) {
        await dbHelper.deleteUsuario(adminExistente.id!);
        print('✅ Admin existente eliminado');
      }
      
      // 2. Crear nuevo admin con credenciales correctas
      final nuevoAdmin = Usuario(
        nombreCompleto: 'Administrador',
        email: 'admin@gym.com',
        telefono: 'admin', // TELÉFONO CORRECTO
        dni: 'admin',
        rol: 'admin',
        fechaCreacion: DateTime.now(),
      );
      
      await dbHelper.insertarUsuario(nuevoAdmin);
      print('✅ Nuevo admin creado: dni=admin, telefono=admin');
      
      // 3. Verificar que funciona
      final resultado = await dbHelper.autenticarUsuario('admin', 'admin');
      print('🔐 Verificación: ${resultado != null ? '✅ ÉXITO' : '❌ FALLO'}');
      
    } catch (e) {
      print('❌ Error en reset: $e');
    }
  }
  
  static Future<void> deleteUsuario(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}