import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static final WhatsAppService _instance = WhatsAppService._internal();
  factory WhatsAppService() => _instance;
  WhatsAppService._internal();

  String generarEnlaceWhatsApp({
    required String telefono,
    required String mensaje,
  }) {
    final telefonoLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    final telefonoSinMas = telefonoLimpio.startsWith('+') 
        ? telefonoLimpio.substring(1) 
        : telefonoLimpio;
    final mensajeCodificado = Uri.encodeComponent(mensaje);
    return 'https://wa.me/$telefonoSinMas?text=$mensajeCodificado';
  }

  Future<bool> enviarMensaje({
    required String telefono,
    required String mensaje,
  }) async {
    try {
      final enlace = generarEnlaceWhatsApp(
        telefono: telefono,
        mensaje: mensaje,
      );
      
      final uri = Uri.parse(enlace);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('✅ WhatsApp abierto correctamente');
        return true;
      } else {
        debugPrint('❌ No se puede abrir WhatsApp');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error abriendo WhatsApp: $e');
      return false;
    }
  }

  String getMensajeRecordatorioCuota({
    required String nombreSocio,
    required String fechaVencimiento,
    required int diasRestantes,
    String? aliasTransferencia,
    String? gimnasio,
  }) {
    final aliasTexto = (aliasTransferencia != null && aliasTransferencia.isNotEmpty)
        ? '\n\n💳 *Podés transferir a:* $aliasTransferencia'
        : '';
    
    return '''
🏋️ *Recordatorio de Cuota*

Hola $nombreSocio,

Tu cuota vence en *$diasRestantes días* (el $fechaVencimiento).

Para continuar disfrutando de nuestras instalaciones sin interrupciones, te sugerimos realizar el pago antes de la fecha de vencimiento.$aliasTexto

Si ya realizaste el pago, por favor ignora este mensaje.

${gimnasio != null ? '¡Gracias por ser parte de $gimnasio! 💪' : '¡Gracias! 💪'}
''';
  }

  String getMensajeRecordatorioCuotaVencida({
    required String nombreSocio,
    required String fechaVencimiento,
    String? aliasTransferencia,
    String? gimnasio,
  }) {
    final aliasTexto = (aliasTransferencia != null && aliasTransferencia.isNotEmpty)
        ? '\n\n💳 *Podés transferir a:* $aliasTransferencia'
        : '';
    
    return '''
⚠️ *Recordatorio de Cuota Vencida*

Hola $nombreSocio,

Tu cuota venció el $fechaVencimiento.

Para continuar usando nuestras instalaciones, por favor regulariza tu pago lo antes posible.$aliasTexto

${gimnasio != null ? 'Gracias por tu comprensión. - $gimnasio' : 'Gracias por tu comprensión.'}
''';
  }

  String getMensajeCumpleanos({
    required String nombreSocio,
    String? gimnasio,
  }) {
    return '''
🎉🎂 *¡Feliz Cumpleaños!*

¡Feliz cumpleaños $nombreSocio!

${gimnasio != null ? 'Todo el equipo de $gimnasio' : 'Todo el equipo'} te desea un día increíble lleno de alegría y bendiciones.

¡Que cumplas muchos más! 🎈🎊

💪 ¡Sigamos entrenando juntos!
''';
  }

  bool esNumeroValido(String telefono) {
    final telefonoLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    final telefonoSinMas = telefonoLimpio.startsWith('+') 
        ? telefonoLimpio.substring(1) 
        : telefonoLimpio;
    return telefonoSinMas.length >= 10;
  }

  String formatearTelefono(String telefono) {
    final telefonoLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    if (telefonoLimpio.isEmpty) return telefono;
    if (!telefonoLimpio.startsWith('+')) {
      return '+$telefonoLimpio';
    }
    return telefonoLimpio;
  }
}
