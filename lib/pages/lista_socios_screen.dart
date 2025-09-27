import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/repositories/database_helper.dart';
import 'package:gym/models/socio.dart';
import 'package:gym/blocs/socios_bloc.dart';


class ListaSociosScreen extends StatefulWidget {
  const ListaSociosScreen({super.key});

  @override
  State<ListaSociosScreen> createState() => _ListaSociosScreenState();
}
class _ListaSociosScreenState extends State<ListaSociosScreen> {
  @override
  Widget build(BuildContext context) {
    // Proveemos el BLoC a toda la pantalla
    return BlocProvider(
      create: (context) =>
          SociosBloc(DatabaseHelper.instance)..add(CargarSociosEvent()),
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gestion de Socios'),
            backgroundColor:
                Colors.blue, // Este es el color de la barra superior
          ),
          body: _buildBody(),
          floatingActionButton: _buildFloatingActionButton(context),
        );
      }),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<SociosBloc, SociosState>(
      builder: (context, state) {
        // Diferentes widgets segun el estado
        if (state is SociosCargandoState) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is SociosErrorState) {
          return Center(child: Text('Error: ${state.error} '));
        } else if (state is SociosCargadosState) {
          return _buildListaSocios(state.socios);
        } else {
          return const Center(child: Text('Presiona el boton para cargar socios'));
        }
      },
    );
  }

  Widget _buildListaSocios(List<Socio> socios) {
    return ListView.builder(
      itemCount: socios.length,
      itemBuilder: (context, index) {
          final socio = socios[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getColorByEstado(socio.estadoCuota),
                child: Text(socio.nombreCompleto[0]), // Primer letra del nombre
              ),
              title: Text(socio.nombreCompleto),
              subtitle: Text('DNI: ${socio.dni} - Vence: ${_formatDate(socio.fechaVencimiento)}'),
              trailing: Text(
                socio.estadoCuota,
                style: TextStyle(
                  color: _getColorByEstado(socio.estadoCuota),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                // Aqui luego navegaremos a la pantalla de edicion
                print('Editar socio: ${socio.nombreCompleto}');
              },
            ),
          );
      },
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _agregarSocio(context),
      child: const Icon(Icons.add),
    );
  }
  void _agregarSocio(BuildContext context) {
    // Aqui luego navegaremos a la pantalla de agregar socio
    print('Agregar nuevo socio');

    // Ejemplo de como agregar un socio de prueba
    final nuevoSocio = Socio(
      nombreCompleto: "Nuevo Socio",
      dni: "99999999",
      telefono: "123456789",
      fechaInicio: DateTime.now(),
      fechaVencimiento: DateTime.now().add(const Duration(days: 30)),
      precioMensual: 5000.0,
      tipoPlan: "Mensual",
    );

    // Disparar evento para agregar socio
    context.read<SociosBloc>().add(AgregarSocioEvent(nuevoSocio));
  }

  // Metodo para convertir el estado en color
  Color _getColorByEstado(String estado) {
    switch (estado) {
      case 'Verde':
        return Colors.green;
      case 'Ambar':
        return Colors.amber;
      case 'Rojo':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Metodo para formatear la fecha
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }



}