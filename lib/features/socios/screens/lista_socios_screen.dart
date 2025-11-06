import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/features/socios/bloc/socios_bloc.dart';
import 'package:gym/features/socios/screens/agregar_socio_screen.dart';
import 'package:gym/features/socios/models/socio.dart';
import '../widgets/socio_card.dart';
import 'package:gym/features/notificaciones/services/notificacion_service.dart';
import 'package:gym/features/payments/services/pago_service.dart';


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

  // Metodo para recargar socios deslizando hacia abajo, en moviles
  Future<void> _recargarSocios() async {
    context.read<SociosBloc>().add(CargarSociosEvent());
  }

  void _enviarNotificacion(BuildContext context, Socio socio) {
    // Guardar el context antes de entrar en operaciones async
    final messenger = ScaffoldMessenger.of(context);
    
    // Mostrar loading inmediatamente
    messenger.showSnackBar(
      SnackBar(
        content: Text('Enviando recordatorio a ${socio.nombreCompleto}...'),
        backgroundColor: Colors.blue,
      ),
    );

    // Usar then en lugar de await para evitar problemas de context
    NotificacionService.enviarNotificacionManual(socio).then((resultado) {
      // Remover el snackbar anterior y mostrar resultado
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(resultado['exitoso'] 
              ? '✅ Recordatorio enviado a ${socio.nombreCompleto}'
              : '❌ Error al enviar notificación'),
          backgroundColor: resultado['exitoso'] ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }).catchError((error) {
      // Manejar errores
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _pagarCuota(BuildContext context, Socio socio) {
    final messenger = ScaffoldMessenger.of(context);
    final bloc = context.read<SociosBloc>(); // ← Guardar BLoC antes del async
    
    // Mostrar loading
    messenger.showSnackBar(
      SnackBar(
        content: Text('Procesando pago de ${socio.nombreCompleto}...'),
        backgroundColor: Colors.blue,
      ),
    );

    // Usar then sin problemas de contexto
    PagoService.procesarPago(socio).then((pagoExitoso) {
      // Remover loading
      messenger.removeCurrentSnackBar();
      
      if (pagoExitoso) {
        // Calcular y actualizar fecha
        final nuevaFecha = PagoService.calcularNuevaFechaVencimiento(socio);
        final socioActualizado = socio.copyWith(fechaVencimiento: nuevaFecha);
        bloc.add(ActualizarSocioEvent(socioActualizado)); // ← Usar BLoC guardado
        
        messenger.showSnackBar(
          SnackBar(
            content: Text('✅ Pago exitoso - Vence: ${nuevaFecha.day}/${nuevaFecha.month}/${nuevaFecha.year}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('❌ Error en el pago'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, DNI o teléfono...',
                  border: InputBorder.none,
                  hintStyle: const TextStyle(color: Colors.white70),

                  // NUEVO: Icono de búsqueda
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  
                  // NUEVO: Botón para limpiar búsqueda
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            _searchController.clear();
                            context.read<SociosBloc>().add(BuscarSociosEvent(''));
                          },
                        )
                      : null,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (texto) {
                  context.read<SociosBloc>().add(BuscarSociosEvent(texto));
                },
              ),
            ),
          ],
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

  // Metodo para cuando no hay socios registrados
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline, 
            size: 80, 
            color: Colors.grey[400]
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay socios registrados',
            style: TextStyle(
              fontSize: 18, 
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Presiona el botón + para agregar el primero',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListaSocios(List<Socio> socios) {
    if (socios.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: _recargarSocios,
      child: ListView.builder(
        itemCount: socios.length,
        itemBuilder:(context, index) {
          final socio = socios[index];
          return SocioCard(
            socio: socio,
            onEdit: () => _editarSocio(context, socio),
            onDelete: () => _eliminarSocio(context, socio),
            onNotificar: () => _enviarNotificacion(context, socio),
            onPagarCuota: () => _pagarCuota(context, socio),
          );
        },
      ),
    );
  }
}