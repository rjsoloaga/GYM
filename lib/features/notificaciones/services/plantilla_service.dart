import 'package:gym/features/socios/models/socio.dart';
import 'package:gym/features/notificaciones/models/plantilla_notificacion.dart';

class PlantillaService {
  static final List<PlantillaNotificacion> _plantillasPredeterminadas = [
    PlantillaNotificacion(
      id: 1,
      nombre: 'Recordatorio 7 días antes',
      mensaje: 'Hola {nombre}. Recordatorio: Tu cuota del plan {plan} vence en {dias_restantes} días (el {fecha_vencimiento}).',
      diasAntes: 7,
      fechaCreacion: DateTime.now(),
    ),
    PlantillaNotificacion(
      id: 2,
      nombre: 'Vencimiento hoy',
      mensaje: 'Hola {nombre}. ATENCIÓN: Tu cuota vence HOY ({fecha_vencimiento}). Por favor acércate a regularizar.',
      diasAntes: 0,
      fechaCreacion: DateTime.now(),
    ),
    PlantillaNotificacion(
      id: 3,
      nombre: 'Cuota vencida',
      mensaje: 'Hola {nombre}. URGENTE: Tu cuota está vencida hace {dias_vencidos} días. Regulariza tu situación para continuar con los beneficios.',
      diasAntes: -1, // Negativo indica días vencidos
      fechaCreacion: DateTime.now(),
    ),
  ];

  static List<PlantillaNotificacion> get plantillasPredeterminadas {
    return List.from(_plantillasPredeterminadas);
  }

  static PlantillaNotificacion? obtenerPlantillaParaSocio(Socio socio) {
    final hoy = DateTime.now();
    final diasHastaVencimiento = socio.fechaVencimiento.difference(hoy).inDays;

    for (final plantilla in _plantillasPredeterminadas) {
      if (plantilla.diasAntes == diasHastaVencimiento) {
        return plantilla;
      }
      // Para cuotas vencidas
      if (plantilla.diasAntes == -1 && diasHastaVencimiento < 0) {
        return plantilla;
      }
    }

    return null;
  }

  static String generarMensajePersonalizado(Socio socio, String plantillaMensaje) {
    final plantillaTemporal = PlantillaNotificacion(
      id: 0,
      nombre: 'Temporal',
      mensaje: plantillaMensaje,
      diasAntes: 0,
      fechaCreacion: DateTime.now(),
    );
    
    return plantillaTemporal.aplicarVariables(socio);
  }
}