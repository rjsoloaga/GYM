import 'package:flutter/material.dart';
import 'package:gym/features/rutinas/models/ejercicio.dart';
import 'package:gym/features/rutinas/models/rutina.dart';
import 'package:gym/features/rutinas/services/rutinas_service.dart';

class FormularioRutinaScreen extends StatefulWidget {
  final Rutina? rutina;

  const FormularioRutinaScreen({super.key, this.rutina});

  @override
  State<FormularioRutinaScreen> createState() => _FormularioRutinaScreenState();
}

class _FormularioRutinaScreenState extends State<FormularioRutinaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final RutinasService _rutinasService = RutinasService();
  
  String? _nivelSeleccionado;
  List<RutinaEjercicio> _ejerciciosSeleccionados = [];
  List<Ejercicio> _ejerciciosDisponibles = [];
  bool _guardando = false;
  bool _cargandoEjercicios = true;

  final List<String> _niveles = ['Principiante', 'Intermedio', 'Avanzado'];

  @override
  void initState() {
    super.initState();
    _cargarEjercicios();
    if (widget.rutina != null) {
      _nombreController.text = widget.rutina!.nombre;
      _descripcionController.text = widget.rutina!.descripcion ?? '';
      _nivelSeleccionado = widget.rutina!.nivel;
      _ejerciciosSeleccionados = List.from(widget.rutina!.ejercicios);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _cargarEjercicios() async {
    try {
      final ejercicios = await _rutinasService.getEjercicios();
      setState(() {
        _ejerciciosDisponibles = ejercicios;
        _cargandoEjercicios = false;
      });
    } catch (e) {
      setState(() => _cargandoEjercicios = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando ejercicios: $e')),
        );
      }
    }
  }

  Future<void> _mostrarSelectorEjercicios() async {
    if (_ejerciciosDisponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero debes crear ejercicios desde el menú "Ejercicios"'),
        ),
      );
      return;
    }

    final ejercicioSeleccionado = await showDialog<Ejercicio>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Ejercicio'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _ejerciciosDisponibles.length,
            itemBuilder: (context, index) {
              final ejercicio = _ejerciciosDisponibles[index];
              return ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(ejercicio.nombre),
                subtitle: Text(ejercicio.grupoMuscular ?? ''),
                onTap: () => Navigator.pop(context, ejercicio),
              );
            },
          ),
        ),
      ),
    );

    if (ejercicioSeleccionado != null) {
      _mostrarConfiguracionEjercicio(ejercicioSeleccionado);
    }
  }

  Future<void> _mostrarConfiguracionEjercicio(Ejercicio ejercicio, {RutinaEjercicio? itemExistente}) async {
    final seriesController = TextEditingController(text: itemExistente?.series?.toString() ?? '3');
    final repsController = TextEditingController(text: itemExistente?.repeticiones?.toString() ?? '10');
    final descansoController = TextEditingController(text: itemExistente?.descansoSegundos?.toString() ?? '60');
    final notasController = TextEditingController(text: itemExistente?.notas ?? '');

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ejercicio.nombre),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: seriesController,
                decoration: const InputDecoration(
                  labelText: 'Series',
                  prefixIcon: Icon(Icons.repeat),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: repsController,
                decoration: const InputDecoration(
                  labelText: 'Repeticiones',
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descansoController,
                decoration: const InputDecoration(
                  labelText: 'Descanso (segundos)',
                  prefixIcon: Icon(Icons.timer),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notasController,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'series': int.tryParse(seriesController.text),
                'repeticiones': int.tryParse(repsController.text),
                'descanso': int.tryParse(descansoController.text),
                'notas': notasController.text.trim(),
              });
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (resultado != null) {
      setState(() {
        if (itemExistente != null) {
          // Editar existente
          final index = _ejerciciosSeleccionados.indexOf(itemExistente);
          _ejerciciosSeleccionados[index] = RutinaEjercicio(
            id: itemExistente.id,
            rutinaId: itemExistente.rutinaId,
            ejercicioId: ejercicio.id!,
            orden: itemExistente.orden,
            series: resultado['series'],
            repeticiones: resultado['repeticiones'],
            descansoSegundos: resultado['descanso'],
            notas: resultado['notas'].isEmpty ? null : resultado['notas'],
            ejercicio: ejercicio,
          );
        } else {
          // Agregar nuevo
          _ejerciciosSeleccionados.add(
            RutinaEjercicio(
              ejercicioId: ejercicio.id!,
              orden: _ejerciciosSeleccionados.length + 1,
              series: resultado['series'],
              repeticiones: resultado['repeticiones'],
              descansoSegundos: resultado['descanso'],
              notas: resultado['notas'].isEmpty ? null : resultado['notas'],
              ejercicio: ejercicio,
            ),
          );
        }
      });
    }
  }

  void _eliminarEjercicio(int index) {
    setState(() {
      _ejerciciosSeleccionados.removeAt(index);
      // Reordenar
      for (int i = 0; i < _ejerciciosSeleccionados.length; i++) {
        _ejerciciosSeleccionados[i] = RutinaEjercicio(
          id: _ejerciciosSeleccionados[i].id,
          rutinaId: _ejerciciosSeleccionados[i].rutinaId,
          ejercicioId: _ejerciciosSeleccionados[i].ejercicioId,
          orden: i + 1,
          series: _ejerciciosSeleccionados[i].series,
          repeticiones: _ejerciciosSeleccionados[i].repeticiones,
          descansoSegundos: _ejerciciosSeleccionados[i].descansoSegundos,
          notas: _ejerciciosSeleccionados[i].notas,
          ejercicio: _ejerciciosSeleccionados[i].ejercicio,
        );
      }
    });
  }

  void _moverEjercicio(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _ejerciciosSeleccionados.removeAt(oldIndex);
      _ejerciciosSeleccionados.insert(newIndex, item);
      // Reordenar
      for (int i = 0; i < _ejerciciosSeleccionados.length; i++) {
        _ejerciciosSeleccionados[i] = RutinaEjercicio(
          id: _ejerciciosSeleccionados[i].id,
          rutinaId: _ejerciciosSeleccionados[i].rutinaId,
          ejercicioId: _ejerciciosSeleccionados[i].ejercicioId,
          orden: i + 1,
          series: _ejerciciosSeleccionados[i].series,
          repeticiones: _ejerciciosSeleccionados[i].repeticiones,
          descansoSegundos: _ejerciciosSeleccionados[i].descansoSegundos,
          notas: _ejerciciosSeleccionados[i].notas,
          ejercicio: _ejerciciosSeleccionados[i].ejercicio,
        );
      }
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ejerciciosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes agregar al menos un ejercicio')),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final rutina = Rutina(
        id: widget.rutina?.id,
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        nivel: _nivelSeleccionado,
        activo: true,
        fechaCreacion: widget.rutina?.fechaCreacion ?? DateTime.now(),
        ejercicios: _ejerciciosSeleccionados,
      );

      if (widget.rutina == null) {
        await _rutinasService.crearRutina(rutina);
      } else {
        await _rutinasService.actualizarRutina(rutina);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rutina guardada correctamente')),
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
    final esEdicion = widget.rutina != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar Rutina' : 'Nueva Rutina'),
      ),
      body: _cargandoEjercicios
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la Rutina *',
                        prefixIcon: Icon(Icons.assignment),
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
                    DropdownButtonFormField<String>(
                      value: _nivelSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Nivel',
                        prefixIcon: Icon(Icons.trending_up),
                        border: OutlineInputBorder(),
                      ),
                      items: _niveles.map((nivel) {
                        return DropdownMenuItem(
                          value: nivel,
                          child: Text(nivel),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _nivelSeleccionado = value),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ejercicios',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          onPressed: _mostrarSelectorEjercicios,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_ejerciciosSeleccionados.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'No hay ejercicios agregados',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      )
                    else
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _ejerciciosSeleccionados.length,
                        onReorder: _moverEjercicio,
                        itemBuilder: (context, index) {
                          final item = _ejerciciosSeleccionados[index];
                          return Card(
                            key: ValueKey(item.ejercicioId.toString() + index.toString()),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple.withOpacity(0.2),
                                child: Text(
                                  '${item.orden}',
                                  style: const TextStyle(color: Colors.deepPurple),
                                ),
                              ),
                              title: Text(item.ejercicio?.nombre ?? 'Ejercicio'),
                              subtitle: Text(
                                '${item.series ?? '-'} series × ${item.repeticiones ?? '-'} reps'
                                '${item.descansoSegundos != null ? ' • ${item.descansoSegundos}s' : ''}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _mostrarConfiguracionEjercicio(
                                      item.ejercicio!,
                                      itemExistente: item,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => _eliminarEjercicio(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
                      label: Text(_guardando ? 'Guardando...' : 'Guardar Rutina'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
