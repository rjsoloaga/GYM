import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/features/socios/bloc/socios_bloc.dart';
import 'package:gym/features/socios/bloc/auth_bloc.dart';
import 'package:gym/features/socios/models/socio.dart';
import 'package:intl/intl.dart';

class ListaSociosInactivosScreen extends StatefulWidget {
  const ListaSociosInactivosScreen({super.key});

  @override
  State<ListaSociosInactivosScreen> createState() => _ListaSociosInactivosScreenState();
}

class _ListaSociosInactivosScreenState extends State<ListaSociosInactivosScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SociosBloc>().add(CargarSociosInactivosEvent());
  }

  void _reactivarSocio(BuildContext context, Socio socio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reactivar Socio'),
        content: Text('¿Deseas reactivar a ${socio.nombreCompleto}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Obtener usuario actual
              final authState = context.read<AuthBloc>().state;
              int? usuarioId;
              String? usuarioNombre;
              
              if (authState is AuthSuccess) {
                usuarioId = authState.usuario.id;
                usuarioNombre = authState.usuario.nombreCompleto;
              } else if (authState is AuthAuthenticatedState) {
                final user = authState.user;
                usuarioId = user['id'] as int?;
                usuarioNombre = user['nombreCompleto'] as String?;
              }
              
              // Reactivar el socio con información de usuario
              context.read<SociosBloc>().add(
                ReactivarSocioEvent(
                  socio.id!,
                  usuarioId: usuarioId,
                  usuarioNombre: usuarioNombre,
                ),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${socio.nombreCompleto} reactivado correctamente'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Al salir de esta pantalla, no hacemos nada especial
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Socios Inactivos'),
          backgroundColor: Colors.grey[800],
        ),
        body: BlocBuilder<SociosBloc, SociosState>(
          builder: (context, state) {
            if (state is SociosCargandoState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SociosInactivosCargadosState) {
              final socios = state.sociosInactivos;
              if (socios.isEmpty) {
                return const Center(
                  child: Text(
                    'No hay socios inactivos',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }
              return ListView.builder(
                itemCount: socios.length,
                itemBuilder: (context, index) {
                  final socio = socios[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Text(
                          socio.nombreCompleto.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        socio.nombreCompleto,
                        style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey),
                      ),
                      subtitle: Text('DNI: ${socio.dni}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.restore, color: Colors.green),
                        onPressed: () => _reactivarSocio(context, socio),
                        tooltip: 'Reactivar socio',
                      ),
                    ),
                  );
                },
              );
            } else if (state is SociosErrorState) {
              return Center(child: Text('Error: ${state.error}'));
            } else {
              // Para cualquier otro estado, mostrar mensaje
              return const Center(child: Text('Cargando...'));
            }
          },
        ),
      ),
    );
  }
}
