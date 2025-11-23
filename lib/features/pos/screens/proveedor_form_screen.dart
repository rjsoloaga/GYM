import 'package:flutter/material.dart';
import 'package:gym/features/pos/models/proveedor.dart';
import 'package:gym/features/pos/services/productos_repository.dart';

class ProveedorFormScreen extends StatefulWidget {
  final Proveedor? proveedor;

  const ProveedorFormScreen({super.key, this.proveedor});

  @override
  State<ProveedorFormScreen> createState() => _ProveedorFormScreenState();
}

class _ProveedorFormScreenState extends State<ProveedorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductosRepository _repository = ProductosRepository();

  // Controllers
  final _nombreController = TextEditingController();
  final _razonSocialController = TextEditingController();
  final _cuitController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();
  final _contactoController = TextEditingController();
  final _notasController = TextEditingController();

  bool _activo = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.proveedor != null) {
      _cargarProveedorExistente();
    }
  }

  void _cargarProveedorExistente() {
    final prov = widget.proveedor!;
    _nombreController.text = prov.nombre;
    _razonSocialController.text = prov.razonSocial ?? '';
    _cuitController.text = prov.cuit ?? '';
    _telefonoController.text = prov.telefono ?? '';
    _emailController.text = prov.email ?? '';
    _direccionController.text = prov.direccion ?? '';
    _contactoController.text = prov.contacto ?? '';
    _notasController.text = prov.notas ?? '';
    _activo = prov.activo;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final proveedor = Proveedor(
        id: widget.proveedor?.id,
        nombre: _nombreController.text.trim(),
        razonSocial: _razonSocialController.text.trim().isEmpty 
            ? null 
            : _razonSocialController.text.trim(),
        cuit: _cuitController.text.trim().isEmpty 
            ? null 
            : _cuitController.text.trim(),
        telefono: _telefonoController.text.trim().isEmpty 
            ? null 
            : _telefonoController.text.trim(),
        email: _emailController.text.trim().isEmpty 
            ? null 
            : _emailController.text.trim(),
        direccion: _direccionController.text.trim().isEmpty 
            ? null 
            : _direccionController.text.trim(),
        contacto: _contactoController.text.trim().isEmpty 
            ? null 
            : _contactoController.text.trim(),
        notas: _notasController.text.trim().isEmpty 
            ? null 
            : _notasController.text.trim(),
        activo: _activo,
        fechaCreacion: widget.proveedor?.fechaCreacion ?? DateTime.now(),
      );

      if (widget.proveedor == null) {
        await _repository.crearProveedor(proveedor);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Proveedor creado correctamente'), backgroundColor: Colors.green),
          );
        }
      } else {
        await _repository.actualizarProveedor(proveedor);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Proveedor actualizado correctamente'), backgroundColor: Colors.green),
          );
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error guardando proveedor: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.proveedor == null ? 'Nuevo Proveedor' : 'Editar Proveedor'),
        actions: [
          if (widget.proveedor != null)
            IconButton(
              icon: Icon(_activo ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() => _activo = !_activo);
              },
              tooltip: _activo ? 'Proveedor activo' : 'Proveedor inactivo',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Información Básica
                  _buildSectionTitle('Información Básica'),
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Comercial *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                      hintText: 'Ej: Distribuidora XYZ',
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _razonSocialController,
                    decoration: const InputDecoration(
                      labelText: 'Razón Social',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance),
                      hintText: 'Ej: XYZ S.A.',
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _cuitController,
                    decoration: const InputDecoration(
                      labelText: 'CUIT/CUIL',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                      hintText: '20-12345678-9',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),

                  // Contacto
                  _buildSectionTitle('Información de Contacto'),
                  TextFormField(
                    controller: _contactoController,
                    decoration: const InputDecoration(
                      labelText: 'Persona de Contacto',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      hintText: 'Ej: Juan Pérez',
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _telefonoController,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(value)) {
                                return 'Email inválido';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _direccionController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Notas
                  _buildSectionTitle('Notas Adicionales'),
                  TextFormField(
                    controller: _notasController,
                    decoration: const InputDecoration(
                      labelText: 'Notas',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes),
                      hintText: 'Información adicional sobre el proveedor',
                    ),
                    maxLines: 4,
                  ),

                  const SizedBox(height: 32),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _guardar,
                          icon: const Icon(Icons.save),
                          label: Text(widget.proveedor == null ? 'Crear Proveedor' : 'Guardar Cambios'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _razonSocialController.dispose();
    _cuitController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    _contactoController.dispose();
    _notasController.dispose();
    super.dispose();
  }
}
