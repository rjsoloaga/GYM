import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/blocs/socios_bloc.dart';
import 'package:gym/blocs/auth_bloc.dart';
import 'package:gym/pages/agregar_socio_screen.dart';
import 'package:gym/pages/historial_pagos_screen.dart';
import 'package:gym/models/socio.dart';

class ListaSociosScreen extends StatefulWidget {
  const ListaSociosScreen({super.key});

  @override
  State<ListaSociosScreen> createState() => _ListaSociosScreenState();
}

class _ListaSociosScreenState extends State<ListaSociosScreen> {
  final _searchController = TextEditingController();
  late final VoidCallback _searchListener;

  @override
  void initState() {
    super.initState();
    _searchListener = () {
      setState(() {}); // Actualizar UI cuando cambia el texto
    };
    _searchController.addListener(_searchListener);
  }

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
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFCF6679)),
            SizedBox(width: 8),
            Text('Eliminar Socio', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar a ${socio.nombreCompleto}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<SociosBloc>().add(EliminarSocioEvent(socio.id!));
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${socio.nombreCompleto} eliminado correctamente'),
                  backgroundColor: const Color(0xFF4CAF50),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCF6679)),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
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

  void _verHistorialPagos(BuildContext context, Socio socio) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistorialPagosScreen(socio: socio),
      ),
    );
  }

  void _logoutUnused(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthBloc>().add(LogoutEvent());
              Navigator.pop(context);
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  String _diasRestantes(DateTime fechaVencimiento) {
    final diferencia = fechaVencimiento.difference(DateTime.now()).inDays;
    if (diferencia < 0) {
      return 'Vencida hace ${diferencia.abs()} días';
    } else if (diferencia == 0) {
      return 'Vence hoy';
    } else {
      return '$diferencia días restantes';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticatedState) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticatedState) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

        return Scaffold(
          appBar: null, // Remover AppBar aquí porque lo maneja MainNavigationScreen
          body: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF121212),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // AppBar personalizado
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.asset(
                                  'lobo.png',
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Gym Manager',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Hola, ${authState.nombre}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          ],
                        ),
                        const SizedBox(height: 12),
                        // Barra de búsqueda
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF3A3A3A),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Buscar por nombre, DNI, teléfono o correo...',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.grey),
                                      onPressed: () {
                                        _searchController.clear();
                                        context.read<SociosBloc>().add(BuscarSociosEvent(''));
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onChanged: (texto) {
                              // Disparar evento de búsqueda al BLoC
                              if (mounted) {
                                context.read<SociosBloc>().add(BuscarSociosEvent(texto));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Lista de socios
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ),
                        floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _agregarSocio(context),
                backgroundColor: const Color(0xFF2196F3),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Nuevo Socio',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
        );
        },
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<SociosBloc, SociosState>(
      builder: (context, state) {
        if (state is SociosCargandoState) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (state is SociosErrorState) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Color(0xFFCF6679)),
                const SizedBox(height: 16),
                Text(
                  'Error: ${state.error}',
                  style: const TextStyle(fontSize: 16, color: Color(0xFFCF6679)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        } else if (state is SociosCargadosState) {
          return _buildListaSocios(state.sociosFiltrados);
        } else {
          return Center(
            child: Text('No hay socios cargados', style: TextStyle(color: Colors.grey.shade400)),
          );
        }
      },
    );
  }

  Widget _buildListaSocios(List<Socio> socios) {
    if (socios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No hay socios registrados'
                  : 'No se encontraron resultados',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade400),
            ),
            if (_searchController.text.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Presiona el botón + para agregar uno',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: socios.length,
      itemBuilder: (context, index) {
        final socio = socios[index];
        return _buildSocioCard(socio);
      },
    );
  }

  Widget _buildSocioCard(Socio socio) {
    final colorEstado = _getColorByEstado(socio.estadoCuota);
    final iconEstado = _getIconByEstado(socio.estadoCuota);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3A3A3A),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _editarSocio(context, socio),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Indicador de estado
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colorEstado.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: colorEstado, width: 2),
                  ),
                  child: Icon(iconEstado, color: colorEstado, size: 28),
                ),
                const SizedBox(width: 16),
                
                // Información del socio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                                                      Expanded(
                            child: Text(
                              socio.nombreCompleto,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.badge, size: 16, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            'DNI: ${socio.dni}',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 16, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            socio.telefono,
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          ),
                        ],
                      ),
                      if (socio.correo.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.email, size: 16, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                socio.correo,
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorEstado.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(iconEstado, size: 14, color: colorEstado),
                            const SizedBox(width: 4),
                            Text(
                              _diasRestantes(socio.fechaVencimiento),
                              style: TextStyle(
                                color: colorEstado,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Botones de acción
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.payments, color: Color(0xFF4CAF50)),
                      onPressed: () => _verHistorialPagos(context, socio),
                      tooltip: 'Historial de pagos',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF2196F3)),
                      onPressed: () => _editarSocio(context, socio),
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Color(0xFFCF6679)),
                      onPressed: () => _eliminarSocio(context, socio),
                      tooltip: 'Eliminar',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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

  IconData _getIconByEstado(String estado) {
    switch (estado) {
      case 'Verde':
        return Icons.check_circle;
      case 'Ambar':
        return Icons.warning;
      case 'Rojo':
        return Icons.error;
      default:
        return Icons.help;
    }
  }



  @override
  void dispose() {
    _searchController.removeListener(_searchListener);
    _searchController.dispose();
    super.dispose();
  }
}