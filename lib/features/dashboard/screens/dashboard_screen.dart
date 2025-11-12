
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DASHBOARD DEBUG'),
        backgroundColor: Colors.red, // Color imposible de no ver
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => print('Refresh pressed'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => print('Notifications pressed'),
          ),
        ],
      ),
      body: Container(
        color: Colors.yellow, // Fondo imposible de no ver
        child: const Center(
          child: Text(
            '¡DASHBOARD FUNCIONANDO!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  //Boton de prueba
  // En algún lugar del Dashboard, agrega:
  /*
  ElevatedButton(
    onPressed: () async {
      print('🔍 DIAGNÓSTICO TELEGRAM INICIADO...');
      final updates = await TelegramService.getUpdates();
      print('🔍 Mensajes en Telegram: ${updates.length}');
      
      for (final update in updates) {
        final message = update['message'];
        if (message != null) {
          final text = message['text']?.toString() ?? 'VACÍO';
          final chatId = message['chat']['id'].toString();
          print('🔍 Mensaje: "$text" -> Chat ID: $chatId');
        }
      }
    },
    child: Text('Diagnóstico Telegram'),
  ),
  */

}

/*import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/features/socios/bloc/socios_bloc.dart';
import 'package:gym/features/socios/bloc/auth_bloc.dart'; // IMPORT AGREGADO
import 'package:gym/features/notificaciones/services/notificacion_service.dart';
import 'package:gym/features/notificaciones/services/chatid_registro_service.dart';
import 'package:gym/features/notificaciones/screens/gestion_plantillas_screen.dart';
import 'package:gym/features/socios/models/socio.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _notificacionesVerificadas = false;

  @override
  void initState() {
    super.initState();
    _verificarNotificacionesPendientes();
  }

  void _verificarNotificacionesPendientes() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    try {
      final sociosBloc = context.read<SociosBloc>();
      final sociosState = sociosBloc.state;
      
      if (sociosState is SociosCargadosState) {
        final sociosParaNotificar = NotificacionService.obtenerSociosParaNotificar(sociosState.sociosFiltrados);
        
        if (sociosParaNotificar.isNotEmpty && !_notificacionesVerificadas) {
          _mostrarDialogoNotificacionesPendientes(sociosParaNotificar.length, sociosState.sociosFiltrados);
        }
      }
    } catch (e) {
      print('Error verificando notificaciones: $e');
    }
    
    setState(() {
      _notificacionesVerificadas = true;
    });
  }

  void _mostrarDialogoNotificacionesPendientes(int cantidad, List<Socio> socios) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('📅 Recordatorios Pendientes'),
        content: Text('Hay $cantidad socios que necesitan recordatorios de pago. ¿Quieres enviarlos ahora?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Puedes enviar recordatorios desde la lista de socios')),
              );
            },
            child: const Text('Más Tarde'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _enviarNotificacionesAutomaticas(socios);
            },
            child: const Text('Enviar Ahora'),
          ),
        ],
      ),
    );
  }

  void _enviarNotificacionesAutomaticas(List<Socio> socios) async {
    final messenger = ScaffoldMessenger.of(context);
    
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Enviando recordatorios automáticos...'),
        duration: Duration(seconds: 3),
      ),
    );

    try {
      final resultados = await NotificacionService.enviarNotificacionesAutomaticas(socios);
      final exitosas = resultados.where((r) => r['exitoso'] == true).length;
      
      messenger.showSnackBar(
        SnackBar(
          content: Text('✅ $exitosas de ${resultados.length} recordatorios enviados'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Error enviando recordatorios: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _procesarRegistrosAutomaticos() async {
    final messenger = ScaffoldMessenger.of(context);
    
    messenger.showSnackBar(
      const SnackBar(content: Text('🔄 Procesando registros de Telegram...')),
    );

    try {
      await ChatIdRegistroService.procesarNuevosChatIds();
      
      final stats = await ChatIdRegistroService.obtenerEstadisticasRegistros();
      
      messenger.showSnackBar(
        SnackBar(
          content: Text('✅ ${stats['registrados']}/${stats['total']} socios registrados en Telegram'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

  @override
  Widget build(BuildContext context) {
    print('🔍 DEBUG: DashboardScreen build ejecutándose');
    
    return Scaffold(
      appBar: null, // ← PRUEBA ESTO: AppBar nulo para ver si hay espacio
      body: Container(
        color: Colors.pink, // ← Color IMPOSIBLE de ignorar
        child: const Center(
          child: Text(
            '¡ESTE ES EL DASHBOARD!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
    /*return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🔥 DASHBOARD DEBUG 🔥', // DEBUG: Título llamativo
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red, // DEBUG: Rojo brillante
        elevation: 10, // DEBUG: Sombra pronunciada
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.yellow, size: 30), // DEBUG: Amarillo y grande
            onPressed: _procesarRegistrosAutomaticos,
            tooltip: 'Actualizar registros Telegram',
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.yellow, size: 30), // DEBUG: Amarillo y grande
            onPressed: _verificarNotificacionesPendientes,
            tooltip: 'Verificar recordatorios',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.yellow, size: 30), // DEBUG: Amarillo y grande
            onPressed: () => _logout(context),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Container( // DEBUG: Container con color de fondo
        color: Colors.yellow[100], // DEBUG: Fondo amarillo claro para verificar
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // DEBUG: Texto grande y visible
              const Text(
                '🚀 DASHBOARD FUNCIONANDO', // DEBUG: Texto de verificación
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red, // DEBUG: Color rojo para destacar
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text('PANEL PRINCIPAL - EN CONSTRUCCIÓN'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/socios'),
                child: const Text('Gestionar Socios'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GestionPlantillasScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.message),
                label: const Text('Gestionar Plantillas de Mensajes'),
              ),
            ],
          ),
        ),
      ),
    );*/
  }
}*/