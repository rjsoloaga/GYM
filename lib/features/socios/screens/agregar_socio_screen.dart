import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/features/planes/services/plan_service.dart';
import 'package:gym/features/planes/models/plan.dart';
import 'package:gym/features/socios/bloc/socios_bloc.dart';
import 'package:gym/features/socios/models/socio.dart';

class AgregarSocioScreen extends StatefulWidget {
  final Socio? socioParaEditar;

  const AgregarSocioScreen({super.key, this.socioParaEditar});

  @override
  State<AgregarSocioScreen> createState() => _AgregarSocioScreenState();
}

class _AgregarSocioScreenState extends State<AgregarSocioScreen> {
  //final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _dniController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _precioController = TextEditingController();

  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaVencimiento = DateTime.now().add(const Duration(days: 30));
  String _tipoPlan = 'Mensual';

  // Lista de opciones válidas para el tipo de plan
  static const List<String> opcionesPlan = ['Pendiente', 'Básico', 'Mensual', 'Trimestral', 'Anual'];
  List<String> _opcionesPlan = List.from(opcionesPlan);
  List<Plan> _planesActivos = [];
  String _mapTipoPlan(String valor) {
    final v = valor.trim().toLowerCase();
    for (final opt in opcionesPlan) {
      if (opt.toLowerCase() == v) return opt;
    }
    return valor.trim();
  }
  
  @override
  void initState() {
    super.initState();
    if (widget.socioParaEditar != null) {
      _cargarDatosExistente();
      // Asegurarse de que _tipoPlan sea un valor válido
      _tipoPlan = _mapTipoPlan(_tipoPlan);
      if (!opcionesPlan.contains(_tipoPlan)) _tipoPlan = 'Mensual';
    } else {
      _tipoPlan = 'Mensual'; // ← Valor por defecto para nuevos socios
    }
    _cargarPlanesActivos();
  }

  void _cargarDatosExistente() {
    final socio = widget.socioParaEditar!;
    _nombreController.text = socio.nombreCompleto;
    _dniController.text = socio.dni;
    _telefonoController.text = socio.telefono;
    _emailController.text = socio.email;
    _precioController.text = socio.precioMensual.toString();
    _fechaInicio = socio.fechaInicio;
    _fechaVencimiento = socio.fechaVencimiento;
    _tipoPlan = _mapTipoPlan(socio.tipoPlan);
  }

  Future<void> _cargarPlanesActivos() async {
    try {
      final service = PlanService();
      final planes = await service.obtenerPlanesActivos();
      if (!mounted) return;
      setState(() {
        _planesActivos = planes;
        _opcionesPlan = planes.isNotEmpty
            ? planes.map((p) => p.nombre).toList()
            : List.from(opcionesPlan);
        if (!_opcionesPlan.contains(_tipoPlan)) {
          _tipoPlan = _opcionesPlan.first;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _opcionesPlan = List.from(opcionesPlan);
        if (!_opcionesPlan.contains(_tipoPlan)) {
          _tipoPlan = _opcionesPlan.first;
        }
      });
    }
  }

  void _guardarSocio() {
    final nombre = _nombreController.text;
    final dni = _dniController.text;

    if (nombre.isEmpty || dni.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nombre y DNI son obligatorios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final socio = widget.socioParaEditar == null
        ? Socio(
            id: null,
            nombreCompleto: nombre,
            dni: dni,
            telefono: _telefonoController.text.trim(),
            email: _emailController.text.trim(),
            fechaInicio: _fechaInicio,
            fechaVencimiento: _fechaVencimiento,
            precioMensual: double.tryParse(_precioController.text) ?? 0.0,
            tipoPlan: _tipoPlan,
          )
        : widget.socioParaEditar!.copyWith(
            nombreCompleto: nombre,
            dni: dni,
            telefono: _telefonoController.text.trim(),
            email: _emailController.text.trim(),
            fechaInicio: _fechaInicio,
            fechaVencimiento: _fechaVencimiento,
            precioMensual: double.tryParse(_precioController.text) ?? 0.0,
            tipoPlan: _tipoPlan,
          );

    debugPrint('debug: socio final a guardar - ID: ${socio.id}');

    if (widget.socioParaEditar == null) {
      context.read<SociosBloc>().add(AgregarSocioEvent(socio));
      debugPrint('Creando nuevo socio');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Socio agregado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      context.read<SociosBloc>().add(ActualizarSocioEvent(socio));
      debugPrint('Actualizando socio ID: ${socio.id}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Socio actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }

    Navigator.pop(context);
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esFechaInicio) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: esFechaInicio ? _fechaInicio : _fechaVencimiento,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        if (esFechaInicio) {
          _fechaInicio = fechaSeleccionada;
        } else {
          _fechaVencimiento = fechaSeleccionada;
        }
      });
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _dniController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.socioParaEditar == null ? 'Agregar Nuevo Socio' : 'Editar Socio'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dniController,
              decoration: const InputDecoration(
                labelText: 'DNI *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _precioController,
              decoration: const InputDecoration(
                labelText: 'Precio Mensual',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _seleccionarFecha(context, true),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Fecha de Inicio',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
                ),
                child: Text(
                  _formatearFecha(_fechaInicio),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _seleccionarFecha(context, false),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Fecha de Vencimiento',
                  prefixIcon: const Icon(Icons.event_busy),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
                ),
                child: Text(
                  _formatearFecha(_fechaVencimiento),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _opcionesPlan.contains(_tipoPlan) ? _tipoPlan : (_opcionesPlan.isNotEmpty ? _opcionesPlan.first : null),
              decoration: InputDecoration(
                labelText: 'Tipo de Plan',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
              ),
              items: _opcionesPlan
                  .map<DropdownMenuItem<String>>((String plan) => DropdownMenuItem<String>(
                        value: plan,
                        child: Text(plan),
                      ))
                  .toList(),
              onChanged: (String? value) {
                if (value != null && _opcionesPlan.contains(value)) {
                  setState(() {
                    _tipoPlan = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _guardarSocio,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Guardar Socio'),
            ),
          ],
        ),
      ),
    );
  }
}