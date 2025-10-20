import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/blocs/socios_bloc.dart';
import 'package:gym/models/socio.dart';


class AgregarSocioScreen extends StatefulWidget {
    const AgregarSocioScreen({super.key});

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
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Agregar Socio'),
                backgroundColor: Colors.blue,
            ),
            body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    children:[
                        TextField(
                            controller: _nombreController,
                            decoration: const InputDecoration(
                                labelText: 'Nombre Completo *',
                                border: OutlineInputBorder(),
                            ),
                        ),

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

    void _guardarSocio() {
        final nombre = _nombreController.text;
        final dni = _dniController.text;

        if (nombre.isEmpty || dni.isEmpty) {
            //Mostramos un SnackBar o dialogo de error
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nombre y DNI son obligatorios'),
                backgroundColor: Colors.red
                ),
            );
            return;
        }

        //Crear el socio con los datos del usuario
        final nuevoSocio = Socio(
            nombreCompleto: nombre,
            dni: dni,
            telefono: _telefonoController.text.trim(),
            fechaInicio: DateTime.now(),
            fechaVencimiento: DateTime.now().add(const Duration(days: 30)),
            precioMensual: double.tryParse(_precioController.text)?? 0.0,
            tipoPlan: 'Mensual', // <-- de momento lo dejamos fijo --
        );

        // Guardamos en DB usando el BloC
        context.read<SociosBloc>().add(AgregarSocioEvent(nuevoSocio));

        // y volvemos a la pantalla anterior
        Navigator.pop(context);

        @override
        void dispose() {
            // Limpiamos los controladores cuando se cierre la pantalla
            _nombreController.dispose();
            _dniController.dispose();
            _telefonoController.dispose();
            _precioController.dispose();
            super.dispose();
        }
    }

}