import 'package:gym/core/database/database_helper.dart';
import 'package:gym/features/auth/models/usuario.dart';

class AdminUtils {
  static Future<void> ensureAdminUserExists() async {
    try {
      print('🔄 Verificando usuario administrador...');
      final db = DatabaseHelper.instance;
      
      // Forzar la creación de la base de datos
      await db.database;
      
      // Intentar eliminar el admin existente si hay un error de clave primaria
      try {
        await db.deleteUsuario(1); // ID 1 para el admin
        print('ℹ️ Usuario admin existente eliminado');
      } catch (e) {
        if (!e.toString().contains('no such table')) {
          print('⚠️ No se pudo eliminar el usuario admin: $e');
        }
      }
      
      // Crear el usuario administrador
      try {
        await db.insertarUsuario(
          Usuario(
            id: 1,
            nombreCompleto: 'Administrador',
            email: 'admin@gym.com',
            telefono: 'admin',
            dni: 'admin',
            rol: 'admin',
            fechaCreacion: DateTime.now(),
            activo: true,
          ),
        );
        print('✅ Usuario administrador creado exitosamente');
      } catch (e) {
        // Si falla, intentar sin especificar el ID
        if (e.toString().contains('UNIQUE constraint')) {
          print('⚠️ El usuario admin ya existe, intentando autenticar...');
          try {
            final usuario = await db.autenticarUsuario('admin', 'admin');
            if (usuario != null) {
              print('✅ Usuario admin autenticado correctamente');
              return;
            }
          } catch (authError) {
            print('❌ Error al autenticar usuario admin: $authError');
          }
        }
        rethrow;
      }
    } catch (e) {
      print('❌ Error crítico en ensureAdminUserExists: $e');
      // No lanzamos la excepción para no romper el flujo de la aplicación
    }
  }
}