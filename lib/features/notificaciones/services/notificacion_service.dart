import 'package:gym/features/socios/models/socio.dart';
import 'telegram_service.dart';
import 'package:gym/features/notificaciones/services/plantilla_service.dart';
import 'package:gym/features/notificaciones/models/plantilla_notificacion.dart';
import 'package:gym/core/database/database_helper.dart';
import 'package:gym/services/recordatorios_service.dart';
import 'dart:async';

class NotificacionService {
  // Stream para notificar cuando se acepta una solicitud
  static final StreamController<Map<String, dynamic>> _solicitudesController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Stream público para escuchar solicitudes aceptadas
  static Stream<Map<String, dynamic>> get onSolicitudAceptada => _solicitudesController.stream;
  
  // Método para notificar cuando se aprueba un socio
  static void notificarAprobacionSocio(Socio socio) {
    if (!_solicitudesController.isClosed) {
      _solicitudesController.add({
        'tipo': 'socio_aprobado',
        'socio': socio.toMap(),
        'fecha': DateTime.now().toIso8601String(),
      });
    }
  }
  static List<Map<String, dynamic>> _historialNotificaciones = [];
  
  // Método para cerrar los controladores de flujo cuando ya no sean necesarios
  static void dispose() {
    if (!_solicitudesController.isClosed) {
      _solicitudesController.close();
    }
  }

  static List<Socio> obtenerSociosParaNotificar(List<Socio> todosLosSocios) {
    return todosLosSocios.where((socio) => socio.necesitaNotificacion).toList();
  }


  static Future<Map<String, dynamic>> enviarNotificacionManual(Socio socio, {String? mensajePersonalizado}) async {
    // Si NO hay mensaje personalizado, usar el servicio de recordatorios multicanal
    if (mensajePersonalizado == null) {
      try {
        final recordatoriosService = RecordatoriosService();
        // Agregar estadoCuota al mapa ya que toMap() no lo incluye por defecto
        final socioMap = socio.toMap();
        socioMap['estadoCuota'] = socio.estadoCuota;
        
        final resultado = await recordatoriosService.enviarRecordatorioManual(socioMap);
        
        return {
          'socio': socio.nombreCompleto,
          'mensaje': 'Recordatorio enviado por múltiples canales',
          'timestamp': DateTime.now(),
          'exitoso': resultado['exito'] as bool,
          'tipo': 'multicanal',
          'error': resultado['exito'] ? null : 'Falló el envío multicanal',
          'estadoCuota': socio.estadoCuota,
        };
      } catch (e) {
        print('❌ Error en envío multicanal: $e');
        return {
          'socio': socio.nombreCompleto,
          'mensaje': 'Error en envío',
          'timestamp': DateTime.now(),
          'exitoso': false,
          'tipo': 'multicanal',
          'error': e.toString(),
          'estadoCuota': socio.estadoCuota,
        };
      }
    }

    // Si HAY mensaje personalizado, seguimos usando solo Telegram por ahora (o lo que estaba antes)
    final String mensaje = mensajePersonalizado;
    final timestamp = DateTime.now();
    
    bool enviadoPorTelegram = false;
    bool exitoso = false;
    String? detalleError;

    // VERIFICACIÓN MEJORADA - Solo enviar si tiene chatId REAL
    String? chatIdParaUsar = socio.telegramChatId;
    
    // Si el chatId es temporal, NO enviar
    if (chatIdParaUsar == null || 
        chatIdParaUsar.isEmpty || 
        chatIdParaUsar.startsWith('temp_')) {
      print('❌ ENVIADO: NO - El socio no está registrado en Telegram');
      return {
        'socio': socio.nombreCompleto,
        'mensaje': mensaje,
        'timestamp': timestamp,
        'exitoso': false,
        'tipo': 'telegram',
        'telegramChatId': chatIdParaUsar,
        'error': 'Socio no registrado en Telegram',
        'estadoCuota': socio.estadoCuota,
      };
    }

    // INTENTAR ENVÍO SOLO si tiene chatId real
    try {
      enviadoPorTelegram = true;
      print('📤 Intentando enviar a Telegram (ChatID: $chatIdParaUsar)');
      exitoso = await TelegramService.sendMessage(
        chatId: chatIdParaUsar,
        message: mensaje,
      );
      
      if (exitoso) {
        print('✅ Mensaje enviado a Telegram exitosamente');
      } else {
        print('❌ Error al enviar a Telegram (respuesta 200 pero sin éxito)');
        detalleError = 'Error al enviar por Telegram - ChatId puede ser inválido';
      }
    } catch (e) {
      print('❌ Excepción al enviar a Telegram: $e');
      exitoso = false;
      detalleError = 'Excepción: $e';
    }
    
    final resultado = {
      'socio': socio.nombreCompleto,
      'mensaje': mensaje,
      'timestamp': timestamp,
      'exitoso': exitoso,
      'tipo': enviadoPorTelegram ? 'telegram' : 'manual',
      'telegramChatId': chatIdParaUsar,
      'error': detalleError,
      'estadoCuota': socio.estadoCuota,
    };
    
    _historialNotificaciones.add(resultado);
    return resultado;
  }

  // NUEVO MÉTODO MEJORADO para mensajes específicos por estado de cuota
  static String _generarMensajePorEstadoCuota(Socio socio) {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final venc = DateTime(
      socio.fechaVencimiento.year,
      socio.fechaVencimiento.month,
      socio.fechaVencimiento.day,
    );
    final diasHastaVencimiento = venc.difference(hoy).inDays;
    
    switch (socio.estadoCuota) {
      case 'Vencido':
        final diasVencidos = diasHastaVencimiento.abs();
        return '''
⚠️ *CUOTA VENCIDA* ⚠️

Hola *${socio.nombreCompleto}*

Tu cuota está *VENCIDA hace $diasVencidos días*.
*Venció el:* ${socio.fechaVencimiento.day}/${socio.fechaVencimiento.month}/${socio.fechaVencimiento.year}

📍 Por favor, acércate a regularizar tu situación.

¡Te esperamos! 🏋️‍♂️
        ''';
        
      case 'Por Vencer':
        final mensajeDias = diasHastaVencimiento == 0
            ? 'Tu cuota *vence HOY*.'
            : diasHastaVencimiento == 1
                ? 'Tu cuota *vence MAÑANA*.'
                : 'Tu cuota *vence en $diasHastaVencimiento días*.';
        return '''
🔔 *RECORDATORIO AMIGABLE* 🔔

Hola *${socio.nombreCompleto}*

$mensajeDias
*Fecha de vencimiento:* ${socio.fechaVencimiento.day}/${socio.fechaVencimiento.month}/${socio.fechaVencimiento.year}

💳 Podés pagar en efectivo o transferencia.

¡No dejes que venza! 💪
        ''';
        
      case 'Al Día':
        return '''
✅ *TODO EN ORDEN* ✅

Hola *${socio.nombreCompleto}*

Confirmamos que tu cuota está *AL DÍA*.
*Próximo vencimiento:* ${socio.fechaVencimiento.day}/${socio.fechaVencimiento.month}/${socio.fechaVencimiento.year}

¡Gracias por tu puntualidad! 🏋️‍♂️

Sigue entrenando fuerte! 💥
        ''';
        
      default:
        return _generarMensajeDefault(socio);
    }
  }

  // Método auxiliar para obtener socio desde la base de datos
  static Future<Socio?> _getSocioFromDatabase(int? id) async {
    if (id == null) return null;
    try {
      final socios = await DatabaseHelper.instance.getSocios();
      return socios.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  // MÉTODO ESPECÍFICO PARA VERIFICAR Y ACTUALIZAR CHAT ID
  static Future<bool> verificarYActualizarChatId(Socio socio) async {
    try {
      if (socio.telefono.isEmpty) {
        return false;
      }

      // Buscar en la base de datos de Telegram por el teléfono
      final chatIdActualizado = await _buscarChatIdPorTelefono(socio.telefono);
      
      if (chatIdActualizado != null && chatIdActualizado.isNotEmpty) {
        // Actualizar en la base de datos
        await _actualizarChatIdEnDatabase(socio.id, chatIdActualizado);
        return true;
      }
      return false;
    } catch (e) {
      print('Error verificando chatId: $e');
      return false;
    }
  }

  // Método auxiliar para actualizar chatId en la base de datos
  static Future<void> _actualizarChatIdEnDatabase(int? id, String chatId) async {
    if (id == null) return;
    try {
      final socio = await _getSocioFromDatabase(id);
      if (socio != null) {
        final socioActualizado = socio.copyWith(telegramChatId: chatId);
        await DatabaseHelper.instance.updateSocio(socioActualizado);
      }
    } catch (e) {
      print('Error actualizando chatId en DB: $e');
    }
  }

  // Método auxiliar para buscar chatId por teléfono
  static Future<String?> _buscarChatIdPorTelefono(String telefono) async {
    try {
      // Obtener todos los updates de Telegram
      final updates = await TelegramService.getUpdates();
      
      for (final update in updates) {
        final message = update['message'];
        if (message != null) {
          final text = message['text']?.toString() ?? '';
          final chatId = message['chat']['id'].toString();
          
          // Buscar el teléfono en el mensaje
          if (_contieneTelefono(text, telefono)) {
            return chatId;
          }
        }
      }
      return null;
    } catch (e) {
      print('Error buscando chatId por teléfono: $e');
      return null;
    }
  }

  // Verificar si el texto contiene el teléfono
  static bool _contieneTelefono(String texto, String telefono) {
    // Limpiar ambos teléfonos para comparación
    final telefonoLimpio = telefono.replaceAll(RegExp(r'[+\-\s()]'), '');
    final textoLimpio = texto.replaceAll(RegExp(r'[+\-\s()]'), '');
    
    return textoLimpio.contains(telefonoLimpio);
  }

  // NUEVO: Enviar con plantilla específica
  static Future<Map<String, dynamic>> enviarNotificacionConPlantilla(
    Socio socio, 
    PlantillaNotificacion plantilla,
  ) async {
    final mensaje = plantilla.aplicarVariables(socio);
    return await enviarNotificacionManual(socio, mensajePersonalizado: mensaje);
  }

  // NUEVO: Notificaciones automáticas con verificación mejorada
  static Future<List<Map<String, dynamic>>> enviarNotificacionesAutomaticas(List<Socio> socios) async {
    final resultados = <Map<String, dynamic>>[];
    final sociosParaNotificar = obtenerSociosParaNotificar(socios);
    
    for (final socio in sociosParaNotificar) {
      // Verificar y actualizar chatId antes de enviar
      await verificarYActualizarChatId(socio);
      
      final resultado = await enviarNotificacionManual(socio);
      resultados.add(resultado);
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    return resultados;
  }

  // Mantener compatibilidad con método antiguo
  static String generarMensajeRecordatorio(Socio socio) {
    final plantilla = PlantillaService.obtenerPlantillaParaSocio(socio);
    return plantilla?.aplicarVariables(socio) ?? _generarMensajeDefault(socio);
  }

  static String _generarMensajeDefault(Socio socio) {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final venc = DateTime(
      socio.fechaVencimiento.year,
      socio.fechaVencimiento.month,
      socio.fechaVencimiento.day,
    );
    final diasHastaVencimiento = venc.difference(hoy).inDays;
    
    if (diasHastaVencimiento > 1) {
      return 'Hola ${socio.nombreCompleto}. Recordatorio: Tu cuota vence en $diasHastaVencimiento días.';
    } else if (diasHastaVencimiento == 1) {
      return 'Hola ${socio.nombreCompleto}. Recordatorio: Tu cuota vence MAÑANA.';
    } else if (diasHastaVencimiento == 0) {
      return 'Hola ${socio.nombreCompleto}. ATENCIÓN: Tu cuota vence HOY.';
    } else {
      final diasVencidos = diasHastaVencimiento.abs();
      return 'Hola ${socio.nombreCompleto}. URGENTE: Tu cuota está vencida hace $diasVencidos días.';
    }
  }

  // NUEVO: Método específico para recordatorios de cuotas
  static Future<Map<String, dynamic>> enviarRecordatorioCuota(Socio socio) async {
    return await enviarNotificacionManual(socio); // Usará automáticamente _generarMensajePorEstadoCuota
  }

  static Future<List<Map<String, dynamic>>> enviarNotificacionMasiva(List<Socio> socios) async {
    final resultados = <Map<String, dynamic>>[];
    
    for (final socio in socios) {
      // Verificar chatId antes de enviar
      await verificarYActualizarChatId(socio);
      
      final resultado = await enviarNotificacionManual(socio);
      resultados.add(resultado);
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    return resultados;
  }

  static Future<bool> verificarConexionTelegram() async {
    return await TelegramService.testConnection();
  }

  static Future<List<dynamic>> obtenerUpdatesTelegram() async {
    return await TelegramService.getUpdates();
  }

  static List<Map<String, dynamic>> obtenerHistorial() {
    return List.from(_historialNotificaciones);
  }

  static void limpiarHistorial() {
    _historialNotificaciones.clear();
  }

  static int get totalNotificacionesEnviadas {
    return _historialNotificaciones.length;
  }

  static Map<String, int> obtenerEstadisticas() {
    final telegramCount = _historialNotificaciones.where((n) => n['tipo'] == 'telegram').length;
    final manualCount = _historialNotificaciones.where((n) => n['tipo'] == 'manual').length;
    final exitosasCount = _historialNotificaciones.where((n) => n['exitoso'] == true).length;
    
    return {
      'total': _historialNotificaciones.length,
      'telegram': telegramCount,
      'manual': manualCount,
      'exitosas': exitosasCount,
    };
  }

  // NUEVO: Estadísticas por estado de cuota
  static Map<String, int> obtenerEstadisticasPorEstadoCuota() {
    final vencidos = _historialNotificaciones.where((n) => n['estadoCuota'] == 'Vencido').length;
    final porVencer = _historialNotificaciones.where((n) => n['estadoCuota'] == 'Por Vencer').length;
    final alDia = _historialNotificaciones.where((n) => n['estadoCuota'] == 'Al Día').length;
    
    return {
      'vencidos': vencidos,
      'porVencer': porVencer,
      'alDia': alDia,
    };
  }

  // NUEVO MÉTODO: Verificar si un socio está registrado en Telegram
  static Future<bool> verificarRegistroTelegram(Socio socio) async {
    try {
      // 1. Si ya tiene chatId, verificar si es válido
      if (socio.telegramChatId != null && socio.telegramChatId!.isNotEmpty) {
        // Verificar enviando un mensaje de prueba silencioso
        final resultado = await TelegramService.sendMessage(
          chatId: socio.telegramChatId!,
          message: '✅ Verificación de conexión - ${DateTime.now()}',
        );
        return resultado;
      }
      
      // 2. Si no tiene chatId, intentar buscar por teléfono
      if (socio.telefono.isNotEmpty) {
        final chatIdEncontrado = await _buscarChatIdPorTelefono(socio.telefono);
        if (chatIdEncontrado != null) {
          // Actualizar el socio con el chatId encontrado
          await _actualizarChatIdEnDatabase(socio.id, chatIdEncontrado);
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('Error verificando Telegram para ${socio.nombreCompleto}: $e');
      return false;
    }
  }


  // MÉTODO TEMPORAL: Recuperar chatIds de socios existentes
  static Future<void> recuperarChatIds() async {
    final socios = await DatabaseHelper.instance.getSocios();
    final updates = await TelegramService.getUpdates();
    
    print('🔄 Buscando chatIds para ${socios.length} socios en ${updates.length} mensajes...');
    
    for (final socio in socios) {
      if (socio.telegramChatId == null || socio.telegramChatId!.isEmpty) {
        print('🔍 Buscando chatId para: ${socio.nombreCompleto} - Tel: ${socio.telefono}');
        
        for (final update in updates) {
          final message = update['message'];
          if (message != null) {
            final text = message['text']?.toString() ?? '';
            final chatId = message['chat']['id'].toString();
            final user = message['from'];
            final userName = user['first_name'] ?? '';
            
            // DEBUG: Mostrar qué estamos comparando
            print('   📱 Mensaje: ${text.length > 30 ? text.substring(0, 30) + '...' : text}');
            print('   👤 Usuario: $userName - ChatId: $chatId');
            
            // Búsqueda MÁS FLEXIBLE por múltiples campos
            if (_coincideConSocioMejorado(socio, text, userName)) {
              print('✅ ✅ ✅ ENCONTRADO chatId para ${socio.nombreCompleto}: $chatId');
              final socioActualizado = socio.copyWith(telegramChatId: chatId);
              await DatabaseHelper.instance.updateSocio(socioActualizado);
              break;
            }
          }
        }
      } else {
        print('✅ ${socio.nombreCompleto} ya tiene chatId: ${socio.telegramChatId}');
      }
    }
    
    print('🎯 Búsqueda de chatIds completada');
  }

  static bool _coincideConSocioMejorado(Socio socio, String texto, String userName) {
    final textoLimpio = texto.toLowerCase();
    final telefonoLimpio = socio.telefono.replaceAll(RegExp(r'[^\d]'), '');
    final textoTelefonoLimpio = textoLimpio.replaceAll(RegExp(r'[^\d]'), '');
    
    // Buscar coincidencias más flexibles
    final coincideTelefono = textoTelefonoLimpio.contains(telefonoLimpio);
    final coincideNombre = textoLimpio.contains(socio.nombreCompleto.toLowerCase());
    final coincidePrimerNombre = userName.toLowerCase().contains(socio.nombreCompleto.split(' ').first.toLowerCase());
    final coincideEmail = textoLimpio.contains(socio.email.toLowerCase());
    final coincideDNI = textoLimpio.contains(socio.dni);
    
    print('   🔍 Coincidencias - Tel: $coincideTelefono, Nom: $coincideNombre, PrimerNom: $coincidePrimerNombre, Email: $coincideEmail, DNI: $coincideDNI');
    
    return coincideTelefono || coincideNombre || coincidePrimerNombre || coincideEmail || coincideDNI;
  }
  //**************************Fin Temporal***************** */


  static bool _coincideConSocio(Socio socio, String texto, String userName) {
    final textoLimpio = texto.toLowerCase();
    final telefonoLimpio = socio.telefono.replaceAll(RegExp(r'[^\d]'), '');
    final textoTelefonoLimpio = textoLimpio.replaceAll(RegExp(r'[^\d]'), '');
    
    return textoTelefonoLimpio.contains(telefonoLimpio) ||
          textoLimpio.contains(socio.nombreCompleto.toLowerCase()) ||
          textoLimpio.contains(socio.email.toLowerCase()) ||
          textoLimpio.contains(socio.dni) ||
          userName.toLowerCase().contains(socio.nombreCompleto.split(' ').first.toLowerCase());
  }
  //**************************Fin Temporal***************** */

  /// Envía notificación de pago exitoso al socio por Telegram
  static Future<bool> notificarPagoExitoso(
    Socio socio, {
    required double monto,
    required DateTime fechaVencimiento,
  }) async {
    try {
      // Verificar que el socio tenga chatId válido
      if (socio.telegramChatId == null || 
          socio.telegramChatId!.isEmpty || 
          socio.telegramChatId!.startsWith('temp_')) {
        print('❌ Notificación de pago: ${socio.nombreCompleto} no tiene chatId válido');
        return false;
      }

      final mensaje = '''
✅ *PAGO CONFIRMADO* ✅

Hola *${socio.nombreCompleto}*

Tu pago de *\$${monto.toStringAsFixed(2)}* ha sido registrado exitosamente.

📅 *Nueva fecha de vencimiento:*
${fechaVencimiento.day}/${fechaVencimiento.month}/${fechaVencimiento.year}

Gracias por mantener tu cuota al día. 💪

¡Sigue entrenando fuerte! 🏋️‍♂️
      ''';

      final resultado = await TelegramService.sendMessage(
        chatId: socio.telegramChatId!,
        message: mensaje,
      );

      if (resultado) {
        print('✅ Notificación de pago enviada a ${socio.nombreCompleto}');
      } else {
        print('❌ Error al enviar notificación de pago a ${socio.nombreCompleto}');
      }

      return resultado;
    } catch (e) {
      print('❌ Excepción enviando notificación de pago: $e');
      return false;
    }
  }
}