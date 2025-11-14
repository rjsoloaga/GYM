import 'package:flutter/material.dart';
import 'package:gym/features/planes/models/plan.dart';
import 'package:gym/features/planes/services/plan_service.dart';

class PlanFormScreen extends StatefulWidget {
  static const routeName = '/planes/form';
  final Plan? plan;

  const PlanFormScreen({
    Key? key,
    this.plan,
  }) : super(key: key);

  @override
  _PlanFormScreenState createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends State<PlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _planService = PlanService();
  bool _isLoading = false;
  bool _isEditMode = false;

  // Controladores
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _duracionDiasController = TextEditingController();
  bool _activo = true;
  bool _tiempoIndeterminado = false;
  Plan? _planExistente;

  @override
  void initState() {
    super.initState();
    // Usar el plan proporcionado directamente o intentar obtenerlo de los argumentos de la ruta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.plan != null) {
        _cargarDatosPlanExistente(widget.plan!);
      } else {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args != null && args is Plan) {
          _cargarDatosPlanExistente(args);
        }
      }
    });
  }

  void _cargarDatosPlanExistente(Plan plan) {
    setState(() {
      _isEditMode = true;
      _planExistente = plan;
      _nombreController.text = plan.nombre;
      _precioController.text = plan.precio.toStringAsFixed(2);
      _duracionDiasController.text = plan.duracionDias?.toString() ?? '';
      _tiempoIndeterminado = plan.tiempoIndeterminado;
      _activo = plan.activo;
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _duracionDiasController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final plan = Plan(
        id: _planExistente?.id,
        nombre: _nombreController.text.trim(),
        precio: double.parse(_precioController.text),
        duracionDias: _tiempoIndeterminado ? null : int.tryParse(_duracionDiasController.text),
        tiempoIndeterminado: _tiempoIndeterminado,
        activo: _activo,
        fechaCreacion: _planExistente?.fechaCreacion ?? DateTime.now(),
      );

      if (_isEditMode) {
        await _planService.actualizarPlan(plan);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plan actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _planService.crearPlan(plan);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plan creado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        // Devolver true para indicar que el guardado fue exitoso
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget _buildPrecioField() {
    return TextFormField(
      controller: _precioController,
      decoration: const InputDecoration(
        labelText: 'Precio',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.attach_money),
        prefixText: '\$ ',
      ),
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: false,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa un precio';
        }
        final precio = double.tryParse(value);
        if (precio == null || precio <= 0) {
          return 'Ingresa un precio válido';
        }
        return null;
      },
    );
  }

  Widget _buildTiempoIndeterminadoSwitch() {
    return SwitchListTile(
      title: const Text('Tiempo Indeterminado'),
      subtitle: const Text('El plan no tiene una duración fija'),
      value: _tiempoIndeterminado,
      onChanged: (value) {
        setState(() {
          _tiempoIndeterminado = value;
          if (value) {
            // Limpiar el campo de duración si se marca como tiempo indeterminado
            _duracionDiasController.clear();
          }
        });
      },
      secondary: Icon(
        _tiempoIndeterminado ? Icons.all_inclusive : Icons.calendar_today,
        color: _tiempoIndeterminado ? Colors.blue : null,
      ),
    );
  }

  Widget _buildDuracionDiasField() {
    return TextFormField(
      controller: _duracionDiasController,
      enabled: !_tiempoIndeterminado,
      decoration: const InputDecoration(
        labelText: 'Duración en días',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.calendar_today),
        suffixText: 'días',
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (!_tiempoIndeterminado && (value == null || value.isEmpty)) {
          return 'Por favor ingresa la duración';
        }
        if (!_tiempoIndeterminado && value != null && value.isNotEmpty) {
          final dias = int.tryParse(value);
          if (dias == null || dias <= 0) {
            return 'Ingresa una duración válida';
          }
        }
        return null;
      },
    );
  }

  Widget _buildNombreField() {
    return TextFormField(
      controller: _nombreController,
      decoration: const InputDecoration(
        labelText: 'Nombre del Plan',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.article),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa un nombre';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Plan' : 'Nuevo Plan'),
        actions: [
          if (_isEditMode) ..._buildDeleteButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildNombreField(),
                    const SizedBox(height: 16.0),
                    _buildPrecioField(),
                    const SizedBox(height: 16.0),
                    _buildTiempoIndeterminadoSwitch(),
                    if (!_tiempoIndeterminado) ...[
                      const SizedBox(height: 16.0),
                      _buildDuracionDiasField(),
                    ],
                    const SizedBox(height: 16.0),
                    SwitchListTile(
                      title: const Text('Plan Activo'),
                      value: _activo,
                      onChanged: (value) {
                        setState(() {
                          _activo = value;
                        });
                      },
                      secondary: Icon(
                        _activo ? Icons.check_circle : Icons.remove_circle_outline,
                        color: _activo ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitForm,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isEditMode ? 'Guardar Cambios' : 'Crear Plan'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                    ),
                    if (_isEditMode) ..._buildDeleteButton(),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildDeleteButton() {
    return [
      const SizedBox(height: 16.0),
      OutlinedButton.icon(
        onPressed: _isLoading ? null : _confirmDelete,
        icon: const Icon(Icons.delete, color: Colors.red),
        label: const Text(
          'Eliminar Plan',
          style: TextStyle(color: Colors.red),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          side: const BorderSide(color: Colors.red),
        ),
      ),
    ];
  }

  Future<void> _confirmDelete() async {
    if (_planExistente == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Plan'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este plan? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);
        await _planService.desactivarPlan(_planExistente!.id!);
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plan eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}