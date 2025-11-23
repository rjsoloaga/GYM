import 'package:gym/core/database/database_helper.dart';
import 'package:gym/features/auth/models/usuario.dart';

class UsuariosRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Usuario>> obtenerTodos() async {
    return await _dbHelper.getUsuarios();
  }

  Future<Usuario?> obtenerPorId(int id) async {
    return await _dbHelper.getUsuario(id);
  }

  Future<int> crear(Usuario usuario) async {
    return await _dbHelper.insertarUsuario(usuario);
  }

  Future<int> actualizar(Usuario usuario) async {
    return await _dbHelper.updateUsuario(usuario);
  }

  Future<void> eliminar(int id) async {
    // Soft delete: cambiar activo a false
    final usuario = await _dbHelper.getUsuario(id);
    if (usuario != null) {
      final usuarioInactivo = usuario.copyWith(activo: false);
      await _dbHelper.updateUsuario(usuarioInactivo);
    }
  }
  
  Future<void> reactivar(int id) async {
    final usuario = await _dbHelper.getUsuario(id);
    if (usuario != null) {
      final usuarioActivo = usuario.copyWith(activo: true);
      await _dbHelper.updateUsuario(usuarioActivo);
    }
  }
}
