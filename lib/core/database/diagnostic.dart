import 'package:gym/core/database/database_helper.dart';
import 'package:gym/features/auth/models/usuario.dart'; // AGREGAR ESTE IMPORT

class DatabaseDiagnostic {
  static Future<void> checkAdminUser() async {
    print('🔍 DIAGNÓSTICO: Verificando usuario admin...');
    
    try {
      // Verificar en tabla usuarios
      final usuarios = await DatabaseHelper.instance.getUsuarios();
      print('📋 Usuarios en la BD: ${usuarios.length}');
      for (var usuario in usuarios) {
        print('   - ${usuario.nombreCompleto} (${usuario.dni}) - Rol: ${usuario.rol}');
      }
      
      // Verificar en tabla socios (compatibilidad)
      final socios = await DatabaseHelper.instance.getSocios();
      print('📋 Socios en la BD: ${socios.length}');
      for (var socio in socios) {
        print('   - ${socio.nombreCompleto} (${socio.dni})');
      }
      
      // Probar autenticación
      final authResult = await DatabaseHelper.instance.autenticarUsuario('admin', 'admin');
      print('🔐 Resultado autenticación: ${authResult != null ? "ÉXITO" : "FALLO"}');
      
    } catch (e) {
      print('❌ Error en diagnóstico: $e');
    }
  }
  
  static Future<void> createAdminIfMissing() async {
    try {
      final usuarios = await DatabaseHelper.instance.getUsuarios();
      final adminExists = usuarios.any((user) => user.dni == 'admin');
      
      if (!adminExists) {
        print('🔧 Creando usuario admin...');
        // Crear admin
        await DatabaseHelper.instance.insertarUsuario(Usuario(
          nombreCompleto: 'Administrador',
          email: 'admin@gym.com',
          telefono: 'admin',
          dni: 'admin',
          rol: 'admin',
          fechaCreacion: DateTime.now(),
        ));
        print('✅ Admin creado exitosamente');
      }
    } catch (e) {
      print('❌ Error creando admin: $e');
    }
  }
}