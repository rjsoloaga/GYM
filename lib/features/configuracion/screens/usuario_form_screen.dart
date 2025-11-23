import 'package:flutter/material.dart';
import 'package:gym/features/auth/models/usuario.dart';
import 'package:gym/features/configuracion/services/usuarios_repository.dart';

class UsuarioFormScreen extends StatefulWidget {
  final Usuario? usuario;

  const UsuarioFormScreen({super.key, this.usuario});

  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = UsuariosRepository();
  
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late TextEditingController _dniController;
  String _rol = 'operador';
  
  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.usuario?.nombreCompleto ?? '');
    _emailController = TextEditingController(text: widget.usuario?.email ?? '');
    _telefonoController = TextEditingController(text: widget.usuario?.telefono ?? '');
    _dniController = TextEditingController(text: widget.usuario?.dni ?? '');
    _rol = widget.usuario?.rol ?? 'operador';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_formKey.currentState!.validate()) {
      final usuario = Usuario(
        id: widget.usuario?.id,
        nombreCompleto: _nombreController.text,
        email: _emailController.text,
        telefono: _telefonoController.text,
        dni: _dniController.text,
        rol: _rol,
        fechaCreacion: widget.usuario?.fechaCreacion ?? DateTime.now(),
        activo: widget.usuario?.activo ?? true,
        telegramChatId: widget.usuario?.telegramChatId,
      );

      try {
        if (widget.usuario == null) {
          await _repository.crear(usuario);
        } else {
          await _repository.actualizar(usuario);
        }
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.usuario == null ? 'Nuevo Usuario' : 'Editar Usuario')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre Completo'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dniController,
                decoration: const InputDecoration(labelText: 'DNI / Usuario (Login)'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (Contraseña)',
                  helperText: 'Se usará como contraseña inicial',
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _rol,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                  DropdownMenuItem(value: 'operador', child: Text('Operador')),
                  DropdownMenuItem(value: 'socio', child: Text('Socio')),
                ],
                onChanged: (v) => setState(() => _rol = v!),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _guardar,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
