import 'package:flutter/material.dart';
import 'package:gym/features/rutinas/models/ejercicio.dart';
import 'package:gym/features/rutinas/services/rutinas_service.dart';

class FormularioEjercicioScreen extends StatefulWidget {
  final Ejercicio? ejercicio;

  const FormularioEjercicioScreen({super.key, this.ejercicio});

  @override
  State<FormularioEjercicioScreen> createState() => _FormularioEjercicioScreenState();
}

class _FormularioEjercicioScreenState extends State<FormularioEjercicioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _grupoMuscularController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final RutinasService _rutinasService = RutinasService();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    if (widget.ejercicio != null) {
      _nombreController.text = widget.ejercicio!.nombre;
      _descripcionController.text = widget.ejercicio!.descripcion ?? '';
      _grupoMuscularController.text = widget.ejercicio!.grupoMuscular ?? '';
      _videoUrlController.text = widget.ejercicio!.videoUrl ?? '';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _grupoMuscularController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final ejercicio = Ejercicio(
        id: widget.ejercicio?.id,
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        grupoMuscular: _grupoMuscularController.text.trim(),
        videoUrl: _videoUrlController.text.trim(),
        activo: true,
      );

      if (widget.ejercicio == null) {
        await _rutinasService.crearEjercicio(ejercicio);
      } else {
        await _rutinasService.actualizarEjercicio(ejercicio);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ejercicio guardado correctamente')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.ejercicio != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar Ejercicio' : 'Nuevo Ejercicio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Ejercicio *',
                  prefixIcon: Icon(Icons.fitness_center),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _grupoMuscularController,
                decoration: const InputDecoration(
                  labelText: 'Grupo Muscular',
                  hintText: 'Ej: Pecho, Espalda, Piernas',
                  prefixIcon: Icon(Icons.accessibility_new),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción / Instrucciones',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _videoUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL de Video (Opcional)',
                  hintText: 'Ej: https://youtube.com/...',
                  prefixIcon: Icon(Icons.video_library),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                icon: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(_guardando ? 'Guardando...' : 'Guardar Ejercicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
