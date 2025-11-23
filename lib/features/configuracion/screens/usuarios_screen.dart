import 'package:flutter/material.dart';
import 'package:gym/features/auth/models/usuario.dart';
import 'package:gym/features/configuracion/services/usuarios_repository.dart';
import 'usuario_form_screen.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final UsuariosRepository _repository = UsuariosRepository();
  List<Usuario> _usuarios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final usuarios = await _repository.obtenerTodos();
      setState(() {
        _usuarios = usuarios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar usuarios: $e')),
        );
      }
    }
  }

  Future<void> _eliminarUsuario(Usuario usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(usuario.activo ? 'Desactivar Usuario' : 'Reactivar Usuario'),
        content: Text(usuario.activo 
          ? '¿Estás seguro de que deseas desactivar a ${usuario.nombreCompleto}? No podrá acceder al sistema.'
          : '¿Deseas reactivar a ${usuario.nombreCompleto}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: usuario.activo ? Colors.red : Colors.green),
            child: Text(usuario.activo ? 'Desactivar' : 'Reactivar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      if (usuario.activo) {
        await _repository.eliminar(usuario.id!);
      } else {
        await _repository.reactivar(usuario.id!);
      }
      _cargarUsuarios();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UsuarioFormScreen()),
              );
              if (result == true) _cargarUsuarios();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _usuarios.length,
              itemBuilder: (context, index) {
                final usuario = _usuarios[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: usuario.activo ? Colors.blue : Colors.grey,
                    child: Text(usuario.nombreCompleto.isNotEmpty ? usuario.nombreCompleto[0].toUpperCase() : '?'),
                  ),
                  title: Text(usuario.nombreCompleto),
                  subtitle: Text('${usuario.rol.toUpperCase()} - ${usuario.dni}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!usuario.activo)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Chip(label: Text('Inactivo'), backgroundColor: Colors.grey),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UsuarioFormScreen(usuario: usuario),
                            ),
                          );
                          if (result == true) _cargarUsuarios();
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          usuario.activo ? Icons.delete : Icons.restore,
                          color: usuario.activo ? Colors.red : Colors.green,
                        ),
                        onPressed: () => _eliminarUsuario(usuario),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
