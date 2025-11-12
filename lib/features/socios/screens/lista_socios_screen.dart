import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/features/socios/bloc/socios_bloc.dart';
import 'package:gym/features/socios/screens/agregar_socio_screen.dart';
import 'package:gym/features/socios/models/socio.dart';
import '../widgets/socio_card.dart';
import 'package:gym/features/notificaciones/services/notificacion_service.dart';
import 'package:gym/features/payments/services/pago_service.dart';
import 'dart:developer' as developer;
import 'package:gym/features/notificaciones/screens/gestion_plantillas_screen.dart';
import 'package:gym/features/notificaciones/services/plantilla_service.dart';
import 'package:gym/features/notificaciones/models/plantilla_notificacion.dart';
import 'package:gym/core/database/database_helper.dart';

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

  @override
  void initState() {
    super.initState();
    // SOLO recuperar chatIds reales, NO asignar temporales
    _recuperarChatIdsReales();
  }

  void _recuperarChatIdsReales() async {
    await NotificacionService.recuperarChatIds();
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

  void _mostrarSelectorPlantillas(BuildContext context, Socio socio) {
    final plantillas = PlantillaService.plantillasPredeterminadas;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar plantilla'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: plantillas.length,
            itemBuilder: (context, index) {
              final plantilla = plantillas[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(plantilla.nombre),
                  subtitle: Text(
                    plantilla.mensaje,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _enviarNotificacionConPlantilla(context, socio, plantilla);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          // Opción para mensaje personalizado
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              _mostrarEditorPersonalizado(context, socio);
            },
            child: const Text('Mensaje Personalizado'),
          ),
        ],
      ),
    );
  }

  void _enviarNotificacionConPlantilla(BuildContext context, Socio socio, PlantillaNotificacion plantilla) {
    final messenger = ScaffoldMessenger.of(context);
    
    messenger.showSnackBar(
      SnackBar(
        content: Text('Enviando notificación a ${socio.nombreCompleto}...'),
        backgroundColor: Colors.blue,
      ),
    );

    NotificacionService.enviarNotificacionConPlantilla(socio, plantilla).then((resultado) {
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(resultado['exitoso'] 
              ? '✅ Notificación enviada a ${socio.nombreCompleto}'
              : '❌ Error al enviar notificación'),
          backgroundColor: resultado['exitoso'] ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }).catchError((error) {
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _mostrarEditorPersonalizado(BuildContext context, Socio socio) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mensaje Personalizado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Variables disponibles:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final entry in PlantillaNotificacion.variablesDisponibles.entries)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Tu mensaje personalizado',
                hintText: 'Ej: Hola {nombre}, te recordamos que tu plan {plan} vence pronto...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _enviarNotificacionPersonalizada(context, socio, controller.text);
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _enviarNotificacionPersonalizada(BuildContext context, Socio socio, String mensajePersonalizado) {
    final messenger = ScaffoldMessenger.of(context);
    
    messenger.showSnackBar(
      SnackBar(
        content: Text('Enviando mensaje personalizado a ${socio.nombreCompleto}...'),
        backgroundColor: Colors.blue,
      ),
    );

    NotificacionService.enviarNotificacionManual(
      socio, 
      mensajePersonalizado: mensajePersonalizado
    ).then((resultado) {
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(resultado['exitoso'] 
              ? '✅ Mensaje personalizado enviado'
              : '❌ Error al enviar mensaje'),
          backgroundColor: resultado['exitoso'] ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }).catchError((error) {
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

  // Métodos para probar Telegram - van en tu StatefulWidget
  void _probarConexionTelegram() async {
    final conexionOk = await NotificacionService.verificarConexionTelegram();
    
    if (conexionOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Conexión con Telegram: OK')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error en conexión con Telegram')),
      );
    }
  }

  void _obtenerChatIds() async {
    developer.log('🔍 DEBUG: Botón presionado - Iniciando obtención de Chat IDs');
    
    try {
      final updates = await NotificacionService.obtenerUpdatesTelegram();
      developer.log('🔍 DEBUG: Updates recibidos: ${updates.length}');
      
      if (updates.isNotEmpty) {
        for (final update in updates) {
          final chat = update['message']['chat'];
          developer.log('🔍 CHAT ID ENCONTRADO: ${chat['id']} - Usuario: ${chat['first_name']}');
          
          // Mostrar en snackbar también
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chat ID: ${chat['id']} - ${chat['first_name']}'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        developer.log('🔍 DEBUG: No hay updates - ¿Enviaste mensaje al bot?');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ No hay mensajes en el bot')),
        );
      }
    } catch (e) {
      developer.log('🔍 DEBUG: Error en _obtenerChatIds: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  void _enviarNotificacion(BuildContext context, Socio socio) {
    _enviarRecordatorioCuota(context, socio);
  }

  void _enviarRecordatorioCuota(BuildContext context, Socio socio) async {
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar Recordatorio'),
        content: Text('¿Enviar recordatorio de cuota a ${socio.nombreCompleto}?\n\nEstado: ${socio.estadoCuota}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      // Mostrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📤 Enviando recordatorio a ${socio.nombreCompleto}...'),
          duration: const Duration(seconds: 2),
        ),
      );

      // ✅ ACTUALIZAR chatId antes de enviar (en caso de que se haya registrado recientemente)
      await NotificacionService.verificarYActualizarChatId(socio);
      
      // Obtener el socio actualizado desde la BD
      final sociosActualizados = await DatabaseHelper.instance.getSocios();
      final socioActualizado = sociosActualizados.firstWhere(
        (s) => s.id == socio.id,
        orElse: () => socio,
      );

      // Enviar notificación con el socio actualizado
      final resultado = await NotificacionService.enviarNotificacionManual(socioActualizado);
      
      if (resultado['exitoso'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Recordatorio enviado a ${socio.nombreCompleto}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Si falla por falta de chatId, mostrar mensaje específico
        if (resultado['error'] == 'Socio no registrado en Telegram') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📱 ${socio.nombreCompleto} no está registrado en Telegram'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: ${resultado['error']}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  /*
  void _mostrarInstruccionesRegistro(BuildContext context, Socio socio) {
    final instrucciones = ChatIdRegistroService.generarInstruccionesRegistro(socio);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📱 Registro en Telegram'),
        content: SingleChildScrollView(
          child: Text(instrucciones),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Opcional: Aquí podrías copiar el mensaje al portapapeles
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mensaje listo para copiar')),
              );
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
  */

  // Ordenar socios por estado (Vencido > Por vencer > Al día) y luego alfabéticamente
  List<Socio> _ordenarSocios(List<Socio> socios) {
    // Orden de prioridad de estados
    final ordenEstado = {'Vencido': 1, 'Por vencer': 2, 'Al día': 3};
    
    socios.sort((a, b) {
      // Primero por estado
      final prioridadA = ordenEstado[a.estadoCuota] ?? 4;
      final prioridadB = ordenEstado[b.estadoCuota] ?? 4;
      
      if (prioridadA != prioridadB) {
        return prioridadA.compareTo(prioridadB);
      }
      
      // Si mismo estado, orden alfabético
      return a.nombreCompleto.compareTo(b.nombreCompleto);
    });
    
    return socios;
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
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
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
        actions: [
          // BOTÓN PARA GESTIÓN DE PLANTILLAS
          IconButton(
            icon: Icon(Icons.message),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GestionPlantillasScreen(),
                ),
              );
            },
            tooltip: 'Gestionar plantillas de mensajes',
          ),
        ],
      ),
      body: Column(
        children: [
/*          // BOTONES DE PRUEBA TELEGRAM - TEMPORALES
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.grey[100],
            child: Column(
              children: [
                Text(
                  'Pruebas Telegram:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _probarConexionTelegram,
                        child: Text('Probar Conexión'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _obtenerChatIds,
                        child: Text('Obtener Chat IDs'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),*/         
          // LISTA DE SOCIOS
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
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
    final sociosOrdenados = _ordenarSocios(socios);
    
    if (sociosOrdenados.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: _recargarSocios,
      child: ListView.builder(
        itemCount: sociosOrdenados.length,
        itemBuilder:(context, index) {
          final socio = sociosOrdenados[index];
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