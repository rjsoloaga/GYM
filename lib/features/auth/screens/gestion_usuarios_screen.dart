import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/core/database/database_helper.dart';
import 'package:gym/features/auth/models/usuario.dart';
import 'package:gym/features/socios/bloc/auth_bloc.dart';

class GestionUsuariosScreen extends StatefulWidget {
  @override
  _GestionUsuariosScreenState createState() => _GestionUsuariosScreenState();
}

class _GestionUsuariosScreenState extends State<GestionUsuariosScreen> {
  List<Usuario> _usuarios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _cargando = true);
    final usuarios = await DatabaseHelper.instance.getUsuarios();
    setState(() {
      _usuarios = usuarios;
      _cargando = false;
    });
  }

  void _mostrarDialogoNuevoUsuario() {
    showDialog(
      context: context,
      builder: (context) => DialogNuevoUsuario(
        onUsuarioCreado: _cargarUsuarios,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtener id del usuario autenticado para evitar que se elimine a sí mismo
    final authState = context.read<AuthBloc>().state;
    int? currentUserId;
    if (authState is AuthAuthenticatedState) {
      final user = authState.user;
      if (user is Map && user['id'] != null) currentUserId = user['id'] as int?;
    } else if (authState is AuthSuccess) {
      final user = authState.usuario;
      if (user is Map && user['id'] != null) currentUserId = user['id'] as int?;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Usuarios'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _mostrarDialogoNuevoUsuario,
          ),
        ],
      ),
      body: _cargando
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _usuarios.length,
              itemBuilder: (context, index) {
                final usuario = _usuarios[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(_obtenerIconoRol(usuario.rol)),
                  ),
                  title: Text(usuario.nombreCompleto),
                  subtitle: Text('${usuario.rol} • ${usuario.dni}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                            // Permitir editar cualquier usuario (incluyendo admins)
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editarUsuario(usuario),
                            ),
                            // Permitir eliminar cualquier usuario excepto al propio usuario autenticado
                            if (usuario.id != currentUserId)
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _eliminarUsuario(usuario),
                              ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  IconData _obtenerIconoRol(String rol) {
    switch (rol) {
      case 'admin': return Icons.admin_panel_settings;
      case 'operador': return Icons.supervisor_account;
      case 'socio': return Icons.person;
      default: return Icons.person;
    }
  }

  void _editarUsuario(Usuario usuario) {
    // Mostrar diálogo para editar usuario
    final _formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: usuario.nombreCompleto);
    final dniController = TextEditingController(text: usuario.dni);
    final telefonoController = TextEditingController(text: usuario.telefono);
    final emailController = TextEditingController(text: usuario.email);
    String rolSeleccionado = usuario.rol;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Usuario'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration: InputDecoration(labelText: 'Nombre Completo'),
                  validator: (value) => value!.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: dniController,
                  decoration: InputDecoration(labelText: 'DNI'),
                  validator: (value) => value!.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: telefonoController,
                  decoration: InputDecoration(labelText: 'Teléfono'),
                  validator: (value) => value!.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: (value) => value!.isEmpty ? 'Requerido' : null,
                ),
                DropdownButtonFormField<String>(
                  value: rolSeleccionado,
                  items: ['socio', 'operador', 'admin']
                      .map((rol) => DropdownMenuItem(
                            value: rol,
                            child: Text(rol.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) => rolSeleccionado = value ?? rolSeleccionado,
                  decoration: InputDecoration(labelText: 'Rol'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final usuarioActualizado = usuario.copyWith(
                  nombreCompleto: nombreController.text.trim(),
                  dni: dniController.text.trim(),
                  telefono: telefonoController.text.trim(),
                  email: emailController.text.trim(),
                  rol: rolSeleccionado,
                );

                await DatabaseHelper.instance.updateUsuario(usuarioActualizado);
                _cargarUsuarios();
                Navigator.pop(context);
              }
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _eliminarUsuario(Usuario usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Usuario'),
        content: Text('¿Está seguro de eliminar a ${usuario.nombreCompleto}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteUsuario(usuario.id!);
              _cargarUsuarios();
              Navigator.pop(context);
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class DialogNuevoUsuario extends StatefulWidget {
  final VoidCallback onUsuarioCreado;

  const DialogNuevoUsuario({required this.onUsuarioCreado});

  @override
  _DialogNuevoUsuarioState createState() => _DialogNuevoUsuarioState();
}

class _DialogNuevoUsuarioState extends State<DialogNuevoUsuario> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _dniController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  String _rolSeleccionado = 'socio';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nuevo Usuario'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(labelText: 'Nombre Completo'),
              validator: (value) => value!.isEmpty ? 'Requerido' : null,
            ),
            TextFormField(
              controller: _dniController,
              decoration: InputDecoration(labelText: 'DNI'),
              validator: (value) => value!.isEmpty ? 'Requerido' : null,
            ),
            TextFormField(
              controller: _telefonoController,
              decoration: InputDecoration(labelText: 'Teléfono'),
              validator: (value) => value!.isEmpty ? 'Requerido' : null,
            ),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              validator: (value) => value!.isEmpty ? 'Requerido' : null,
            ),
            DropdownButtonFormField<String>(
              value: _rolSeleccionado,
              items: ['socio', 'operador', 'admin']
                  .map((rol) => DropdownMenuItem(
                        value: rol,
                        child: Text(rol.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _rolSeleccionado = value!),
              decoration: InputDecoration(labelText: 'Rol'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _crearUsuario,
          child: Text('Crear'),
        ),
      ],
    );
  }

  void _crearUsuario() async {
    if (_formKey.currentState!.validate()) {
      final nuevoUsuario = Usuario(
        nombreCompleto: _nombreController.text,
        dni: _dniController.text,
        telefono: _telefonoController.text,
        email: _emailController.text,
        rol: _rolSeleccionado,
        fechaCreacion: DateTime.now(),
      );

      await DatabaseHelper.instance.insertarUsuario(nuevoUsuario);
      widget.onUsuarioCreado();
      Navigator.pop(context);
    }
  }
}