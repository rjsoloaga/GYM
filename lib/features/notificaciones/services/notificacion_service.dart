import 'package:gym/features/socios/models/socio.dart';

class NotificacionService {
  static final List<Map<String, dynamic>> _historialNotificaciones = [];

  static List<Socio> obtenerSociosParaNotificar(List<Socio> todosLosSocios) {
    return todosLosSocios.where((socio) => socio.necesitaNotificacion).toList();
  }

  static String generarMensajeRecordatorio(Socio socio) {
    final hoy = DateTime.now();
    final diasHastaVencimiento = socio.fechaVencimiento.difference(hoy).inDays;
    
    if (diasHastaVencimiento > 0) {
      return 'Hola ${socio.nombreCompleto}. Recordatorio: Tu cuota vence en $diasHastaVencimiento días.';
    } else if (diasHastaVencimiento == 0) {
      return 'Hola ${socio.nombreCompleto}. ATENCIÓN: Tu cuota vence HOY.';
    } else {
      final diasVencidos = diasHastaVencimiento.abs();
      return 'Hola ${socio.nombreCompleto}. URGENTE: Tu cuota está vencida hace $diasVencidos días.';
    }
  }

  static Future<Map<String, dynamic>> enviarNotificacionManual(Socio socio) async {
    final mensaje = generarMensajeRecordatorio(socio);
    final timestamp = DateTime.now();
    
    // Simular envío
    await Future.delayed(const Duration(seconds: 2));
    
    final resultado = {
      'socio': socio.nombreCompleto,
      'mensaje': mensaje,
      'timestamp': timestamp,
      'exitoso': true,
      'tipo': 'manual'
    };
    
    _historialNotificaciones.add(resultado);
    return resultado;
  }

  static List<Map<String, dynamic>> obtenerHistorial() {
    return List.from(_historialNotificaciones);
  }

  static int get totalNotificacionesEnviadas {
    return _historialNotificaciones.length;
  }
}