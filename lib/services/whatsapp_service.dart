import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static final WhatsAppService _instance = WhatsAppService._internal();
  factory WhatsAppService() => _instance;
  WhatsAppService._internal();

  /// Genera un enlace wa.me para abrir WhatsApp con un mensaje pre-escrito
  /// 
  /// [telefono] debe estar en formato internacional sin el símbolo +
  /// Ejemplo: "5491112345678" para Argentina
  String generarEnlaceWhatsApp({
    required String telefono,
    required String mensaje,
  }) {
    // Limpiar el teléfono (quitar espacios, guiones, paréntesis, etc.)
    final telefonoLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Quitar el + inicial si existe
    final telefonoSinMas = telefonoLimpio.startsWith('+') 
        ? telefonoLimpio.substring(1) 
        : telefonoLimpio;
    
    // Codificar el mensaje para URL
    final mensajeCodificado = Uri.encodeComponent(mensaje);
    
    // Generar enlace wa.me
    return 'https://wa.me/$telefonoSinMas?text=$mensajeCodificado';
  }

  /// Abre WhatsApp con un mensaje pre-escrito
  /// 
  /// Retorna true si se pudo abrir, false si no
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

  /// Genera mensaje de recordatorio de cuota próxima a vencer
  String getMensajeRecordatorioCuota({
    required String nombreSocio,
    required String fechaVencimiento,
    required int diasRestantes,
    String? gimnasio,
  }) {
    return '''
🏋️ *Recordatorio de Cuota*

Hola $nombreSocio,

Tu cuota vence en *$diasRestantes días* (el $fechaVencimiento).

Para continuar disfrutando de nuestras instalaciones sin interrupciones, te sugerimos realizar el pago antes de la fecha de vencimiento.

Si ya realizaste el pago, por favor ignora este mensaje.

${gimnasio != null ? '¡Gracias por ser parte de $gimnasio! 💪' : '¡Gracias! 💪'}
''';
  }

  /// Genera mensaje de recordatorio de cuota vencida
  String getMensajeRecordatorioCuotaVencida({
    required String nombreSocio,
    required String fechaVencimiento,
    String? gimnasio,
  }) {
    return '''
⚠️ *Recordatorio de Cuota Vencida*

Hola $nombreSocio,

Tu cuota venció el $fechaVencimiento.

Para continuar usando nuestras instalaciones, por favor regulariza tu pago lo antes posible.

${gimnasio != null ? 'Gracias por tu comprensión. - $gimnasio' : 'Gracias por tu comprensión.'}
''';
  }

  /// Genera mensaje de felicitación de cumpleaños
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

  /// Valida si un número de teléfono es válido para WhatsApp
  /// 
  /// Debe tener al menos 10 dígitos
  bool esNumeroValido(String telefono) {
    final telefonoLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    final telefonoSinMas = telefonoLimpio.startsWith('+') 
        ? telefonoLimpio.substring(1) 
        : telefonoLimpio;
    
    return telefonoSinMas.length >= 10;
  }

  /// Formatea un número de teléfono para mostrar
  /// 
  /// Ejemplo: "5491112345678" -> "+54 9 11 1234-5678"
  String formatearTelefono(String telefono) {
    final telefonoLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (telefonoLimpio.isEmpty) return telefono;
    
    // Si no tiene +, agregarlo
    if (!telefonoLimpio.startsWith('+')) {
      return '+$telefonoLimpio';
    }
    
    return telefonoLimpio;
  }
}
