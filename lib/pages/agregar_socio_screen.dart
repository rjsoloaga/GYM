import 'package:flutter/material.dart';
import 'package:gym/models/socio.dart';


class AgregarSocioScreen extends StatefulWidget {
    const AgregarSocioScree({super.key});

    @override
    State<AgregarSocioScreen> createState() => _AgregarSocioScreenState();
}

class _AgregarSocioScreenState estend State<AgregarSocioScreen> {
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
                                labelText: 'Nombre Completo',
                                border: outlineInputBorder(),
                            ),
                        ),

                        textField(
                            controller: _dniController,
                            decoration: const InputDecoration(
                                labelText; 'DNI',
                                border:outlineInputBorder(),
                            ),
                            keyboardType: TextInputTipe.number,
                        ),

                        textField(
                            controller: _telefonoController,
                            decoration: const InputDecoration(
                                labelText: 'Teléfono',
                                border: outlineInputBorder(),
                            ),
                        ),

                        textField(
                            controller: _precioController
                            decoration: const InputDecoration(
                                labelText: 'Precio Mensual',
                                border: outlineInputBorder(),
                            ),
                        ),

                        cont SizedBox(height: 24),
                        ElevatedButton(
                            onPressed: _guardarSocio,
                            child: const Text('Guardar Socio'),
                        ),
                    ],
                ),
            ),
        );
    }

    void _guardarSocio() {
        final nombre = _nombreController.text;
        final dni = _ dniController.text;

        if (nombre.isEmpty || dni.isEmpty) {
            //Mostramos un SnackBar o dialogo de error
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(Content: Text('Nombre y DNI son obligatorios')),
            );
            return;
        }

        //Crear el socio con los datos del usuario
        final nuevoSocio = Socio(
            nombreCompleto: nombre,
            dni: dni,
            telefono: _telefonoController.text,
            fechaInicio: DateTime.now(),
            fechaVencimiento: DateTime.now().add(const Duration(days: 30)),
            ptecioMensual: double.tryParse(_ptecioController.text)?? 0.0,
            tipoPlan: 'Mensual', // <-- de momento lo dejamos fijo --
        );

        // Guardamos en DB usando el BloC
        context.read<SociosBloc>().add(AgregarSocioEvent(nuevoSocio));

        // y volvemos a la pantalla anterior
        Navigator.pop(context);
    }

}