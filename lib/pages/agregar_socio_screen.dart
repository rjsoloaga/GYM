import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/blocs/socios_bloc.dart';
import 'package:gym/models/socio.dart';

class AgregarSocioScreen extends StatefulWidget {
  final Socio? socioParaEditar;

  const AgregarSocioScreen({super.key, this.socioParaEditar});

  @override
  State<AgregarSocioScreen> createState() => _AgregarSocioScreenState();
}

class _AgregarSocioScreenState extends State<AgregarSocioScreen> {
  //Controladores para los campos de texto
  final _nombreController = TextEditingController();
  final _dniController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _precioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Si vamos a editar primero cargamos los datos existentes
    if (widget.socioParaEditar != null) {
      _cargarDatosExistente();
    }
  }

  void _cargarDatosExistente() {
    final socio = widget.socioParaEditar!;
    _nombreController.text = socio.nombreCompleto;
    _dniController.text = socio.dni;
    _telefonoController.text = socio.telefono;
    _precioController.text = socio.precioMensual.toString();
  }

  void _guardarSocio() {
    final nombre = _nombreController.text;
    final dni = _dniController.text;

    if (nombre.isEmpty || dni.isEmpty) {
      //Mostramos un SnackBar o dialogo de error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nombre y DNI son obligatorios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Crear el socio con los datos del usuario
    final socio = Socio(
      id: widget.socioParaEditar?.id, // Si es para editar mantenemos el ID
      nombreCompleto: nombre,
      dni: dni,
      telefono: _telefonoController.text.trim(),
      fechaInicio: widget.socioParaEditar?.fechaInicio ?? DateTime.now(), // Mantenemos la fecha original
      fechaVencimiento: widget.socioParaEditar?.fechaVencimiento ?? DateTime.now().add(const Duration(days: 30)),
      precioMensual: double.tryParse(_precioController.text) ?? 0.0,
      tipoPlan: "Mensual", // <-- de momento lo dejamos fijo --
    );

    print('debug: socio final a guardar - ID: ${socio.id}');

    // Condicional para saber si es agregar(Create) o editar(Update)
    if (widget.socioParaEditar == null) {
      // Si esta vacio creamos nuevo socio
      context.read<SociosBloc>().add(AgregarSocioEvent(socio));
      print('Creando nuevo socio');
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Socio agregado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Si no, actualizamos el existente
      context.read<SociosBloc>().add(ActualizarSocioEvent(socio));
      print('Actualizando socio ID: ${socio.id}');
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Socio actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }

    Navigator.pop(context);
  }

  @override
  void dispose() {
    // Limpiamos los controladores cuando se cierre la pantalla
    _nombreController.dispose();
    _dniController.dispose();
    _telefonoController.dispose();
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
              decoration: InputDecoration(
                labelText: 'DNI *',
                border: const OutlineInputBorder(),
                enabled: widget.socioParaEditar == null, // DNI solo editable en nuevo socio
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
              controller: _precioController,
              decoration: const InputDecoration(
                labelText: 'Precio Mensual',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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