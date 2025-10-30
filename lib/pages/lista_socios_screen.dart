import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/blocs/socios_bloc.dart';
import 'package:gym/pages/agregar_socio_screen.dart';
import 'package:gym/repositories/database_helper.dart';
import 'package:gym/models/socio.dart';

class ListaSociosScreen extends StatefulWidget {
  const ListaSociosScreen({super.key});

  @override
  State<ListaSociosScreen> createState() => _ListaSociosScreenState();
}

class _ListaSociosScreenState extends State<ListaSociosScreen> {

  final _searchController = TextEditingController();

  void _editarSocio(BuildContext context, Socio socio) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarSocioScreen(socioParaEditar: socio),
      ),
    );
  }

  void _eliminarSocio(BuildContext context, Socio socio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Socio'),
        content: Text('¿Estás seguro de eliminar a ${socio.nombreCompleto}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Eliminar el socio
              context.read<SociosBloc>().add(EliminarSocioEvent(socio.id!));
              Navigator.pop(context);
              
              // Mostrar confirmación
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${socio.nombreCompleto} eliminado correctamente'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _agregarSocio(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AgregarSocioScreen(),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar socio por nombre, DNI o teléfono...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.white70),
        ),
        style: TextStyle(color: Colors.white),
        onChanged: (texto) {
          // Disparar evento de búsqueda al BLoC
          context.read<SociosBloc>().add(BuscarSociosEvent(texto));
        },
      ),
      backgroundColor: Colors.blue,
    ),
    body: _buildBody(),
    floatingActionButton: FloatingActionButton(
      onPressed: () => _agregarSocio(context),
      child: const Icon(Icons.add),
    ),
  );
}

  Widget _buildBody() {
    return BlocBuilder<SociosBloc, SociosState>(
      builder: (context, state) {
        if (state is SociosCargandoState) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is SociosErrorState) {
          return Center(child: Text('Error: ${state.error}'));
        } else if (state is SociosCargadosState) {
          return _buildListaSocios(state.sociosFiltrados);
        } else {
          return const Center(child: Text('No hay socios cargados'));
        }
      },
    );
  }

  Widget _buildListaSocios(List<Socio> socios) {
    if (socios.isEmpty) {
      return const Center(child: Text('No hay socios registrados'));
    }
    
    return ListView.builder(
      itemCount: socios.length,
      itemBuilder: (context, index) {
        final socio = socios[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getColorByEstado(socio.estadoCuota),
              child: Text(socio.nombreCompleto[0]),
            ),
            title: Text(socio.nombreCompleto),
            subtitle: Text('DNI: ${socio.dni} - Vence: ${_formatDate(socio.fechaVencimiento)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editarSocio(context, socio),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarSocio(context, socio),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}