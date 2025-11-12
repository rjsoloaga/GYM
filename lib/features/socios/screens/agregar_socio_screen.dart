import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  void initState() {
    super.initState();
    if (widget.socioParaEditar != null) {
      _cargarDatosExistente();
    } else {
      _tipoPlan = 'Mensual'; // ← Valor por defecto para nuevos socios
    }
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
    _tipoPlan = socio.tipoPlan;
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
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Fecha de Inicio'),
              subtitle: Text(_formatearFecha(_fechaInicio)),
              onTap: () => _seleccionarFecha(context, true),
              tileColor: Colors.grey[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.event_busy),
              title: const Text('Fecha de Vencimiento'),
              subtitle: Text(_formatearFecha(_fechaVencimiento)),
              onTap: () => _seleccionarFecha(context, false),
              tileColor: Colors.grey[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _tipoPlan,
              decoration: const InputDecoration(
                labelText: 'Tipo de Plan',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: ['Pendiente', 'Mensual', 'Trimestral', 'Anual'] 
                  .map((plan) => DropdownMenuItem(
                        value: plan,
                        child: Text(plan),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _tipoPlan = value!;
                });
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