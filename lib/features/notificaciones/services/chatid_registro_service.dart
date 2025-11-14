import 'package:gym/core/database/database_helper.dart';
import 'package:gym/features/socios/models/socio.dart';
import 'package:gym/features/notificaciones/services/notificacion_service.dart';
import 'telegram_service.dart';

class ChatIdRegistroService {
  // Verificar nuevos Chat IDs y asociarlos automáticamente
  static Future<void> procesarNuevosChatIds() async {
    try {
      final updates = await TelegramService.getUpdates();
      final nuevosChats = _extraerNuevosChatIds(updates);
      
      for (final chatData in nuevosChats) {
        await _asociarChatIdConSocio(chatData['chatId'], chatData['telefono'], chatData['nombre']);
      }
    } catch (e) {
      // Log silencioso para producción
    }
  }

  static List<Map<String, dynamic>> _extraerNuevosChatIds(List<dynamic> updates) {
    final nuevosChats = <Map<String, dynamic>>[];
    
    for (final update in updates) {
      final message = update['message'];
      if (message != null) {
        final chat = message['chat'];
        final text = message['text']?.toString() ?? '';
        final chatId = chat['id'].toString();
        
        // Buscar número de teléfono en el mensaje
        final telefono = _extraerTelefonoDelMensaje(text);
        
        if (telefono != null) {
          nuevosChats.add({
            'chatId': chatId,
            'telefono': telefono,
            'nombre': chat['first_name'] ?? 'Usuario',
          });
        }
      }
    }
    
    return nuevosChats;
  }

  static String? _extraerTelefonoDelMensaje(String mensaje) {
    // Buscar solo números (sin texto)
    final soloNumeros = mensaje.replaceAll(RegExp(r'[^\d]'), '');
    
    // Manejar diferentes formatos:
    if (soloNumeros.length == 10) {
        // Formato: 3624856916 (10 dígitos)
        return soloNumeros;
    } else if (soloNumeros.length == 12 && soloNumeros.startsWith('549')) {
        // Formato: 5493624856916 (12 dígitos con 54)
        return soloNumeros.substring(2); // Quita "54"
    } else if (soloNumeros.length == 13 && soloNumeros.startsWith('549')) {
        // Formato: 5493624856916? (por si acaso)
        final numeroLimpio = soloNumeros.substring(2);
        if (numeroLimpio.length == 11) {
          return numeroLimpio.substring(1); // Quita el "9"
        }
    } else if (soloNumeros.length == 11 && soloNumeros.startsWith('9')) {
        // Formato: 93624856916 (11 dígitos con 9)
        return soloNumeros.substring(1); // Quita el "9"
    }
    
    return null;
  }

  static Future<void> _enviarConfirmacionRegistro(String chatId, String nombreSocio) async {
    try {
      await TelegramService.sendMessage(
        chatId: chatId,
        message: '''
✅ *Registro exitoso*

Hola $nombreSocio, ¡has sido registrado exitosamente!

A partir de ahora recibirás recordatorios de pago por este medio.

*Gym Manager*
        ''',
      );
    } catch (e) {
      // Log silencioso para producción
    }
  }

  // Método para que los socios se registren fácilmente
  static String generarInstruccionesRegistro(Socio socio) {
    return '''
Para recibir notificaciones por Telegram:

1. 📱 Abre Telegram en tu celular
2. 🔍 Busca *@gym_25_bot*
3. 💬 Envíale este mensaje exactamente:

*Mi teléfono es: ${socio.telefono}*

4. ✅ Recibirás una confirmación de registro

¡Listo! A partir de ese momento recibirás todos los recordatorios automáticamente.
    ''';
  }

  // Obtener estadísticas de registros
  static Future<Map<String, dynamic>> obtenerEstadisticasRegistros() async {
    try {
      final socios = await DatabaseHelper.instance.getSocios();
      
      final totalSocios = socios.length;
      final sociosRegistrados = socios.where((s) => s.telegramChatId != null && s.telegramChatId!.isNotEmpty).length;
      final sociosSinRegistrar = totalSocios - sociosRegistrados;
      
      return {
        'total': totalSocios,
        'registrados': sociosRegistrados,
        'sinRegistrar': sociosSinRegistrar,
        'porcentaje': totalSocios > 0 ? (sociosRegistrados / totalSocios * 100).round() : 0,
      };
    } catch (e) {
      return {'total': 0, 'registrados': 0, 'sinRegistrar': 0, 'porcentaje': 0};
    }
  }

    // ========== NUEVOS MÉTODOS PARA SISTEMA DE APROBACIÓN ==========

    // Método principal modificado para manejar socios existentes y nuevos
    static Future<void> _asociarChatIdConSocio(String chatId, String telefono, String nombreUsuario) async {
    try {
        final socios = await DatabaseHelper.instance.getSocios();
        
        // Buscar socio por teléfono (comparar solo números)
        Socio? socioEncontrado;
        for (final socio in socios) {
        final telefonoSocioLimpio = socio.telefono.replaceAll(RegExp(r'\D'), '');
        final telefonoMensajeLimpio = telefono.replaceAll(RegExp(r'\D'), '');
        
        if (telefonoSocioLimpio == telefonoMensajeLimpio) {
            socioEncontrado = socio;
            break;
        }
        }
        
        if (socioEncontrado != null) {
        // Socio existe: actualizar chatId
        await _actualizarSocioExistente(socioEncontrado, chatId);
        } else {
        // Socio no existe: crear nuevo pendiente de aprobación
        await _crearSocioPendiente(chatId, telefono, nombreUsuario);
        }
    } catch (e) {
        // Log silencioso para producción
    }
    }

    // Actualizar socio existente (sin cambios)
    static Future<void> _actualizarSocioExistente(Socio socio, String chatId) async {
    // Verificar si ya tiene Chat ID
    if (socio.telegramChatId != null && socio.telegramChatId!.isNotEmpty) {
        return;
    }
    
    // Actualizar socio con Chat ID
    final socioActualizado = socio.copyWith(telegramChatId: chatId);
    await DatabaseHelper.instance.updateSocio(socioActualizado);
    
    // Enviar mensaje de confirmación
    await _enviarConfirmacionRegistro(chatId, socio.nombreCompleto);
    }

    // NUEVO: Crear socio pendiente de aprobación
    static Future<void> _crearSocioPendiente(String chatId, String telefono, String nombreUsuario) async {
    // Crear socio pendiente de aprobación
    final nuevoSocio = Socio(
        nombreCompleto: nombreUsuario,
        dni: 'TG-${DateTime.now().millisecondsSinceEpoch}', // DNI temporal único
        telefono: telefono,
        email: '$telefono@telegram.com',
        fechaInicio: DateTime.now(),
        fechaVencimiento: DateTime.now().add(Duration(days: 30)),
        precioMensual: 0.0,
        tipoPlan: 'Pendiente',
        telegramChatId: chatId,
        pendienteAprobacion: true, // MARCADO COMO PENDIENTE
        fechaRegistroTelegram: DateTime.now(),
    );

    await DatabaseHelper.instance.insertarSocio(nuevoSocio);
    
    await TelegramService.sendMessage(
        chatId: chatId,
        message: '''
    📋 *Registro Recibido*

    Hola $nombreUsuario, tu solicitud de registro ha sido recibida.

    ✅ *Estado:* Pendiente de aprobación
    ⏰ *Próximo paso:* Un administrador revisará tu información
    🔔 *Notificación:* Recibirás un mensaje cuando tu cuenta esté activa

    *Gym Manager*
        ''',
    );
    }

    // NUEVO: Obtener socios pendientes de aprobación
    static Future<List<Socio>> obtenerSociosPendientes() async {
    try {
        final socios = await DatabaseHelper.instance.getSocios();
        return socios.where((socio) => socio.pendienteAprobacion).toList();
    } catch (e) {
        return [];
    }
    }

    // NUEVO: Aprobar socio pendiente
    static Future<bool> aprobarSocio(Socio socio) async {
    try {
        // Mantener el plan y precio originales del socio
        final socioAprobado = socio.copyWith(
          pendienteAprobacion: false,
          // No sobrescribir tipoPlan ni precioMensual para mantener los valores originales
        );
        
        await DatabaseHelper.instance.updateSocio(socioAprobado);
        
        // Notificar al socio por Telegram
        if (socio.telegramChatId != null) {
          await TelegramService.sendMessage(
            chatId: socio.telegramChatId!,
            message: '''
    🎉 *¡Cuenta Aprobada!*

    Hola ${socio.nombreCompleto}, tu cuenta ha sido aprobada.

    ✅ *Estado:* Activo
    📅 *Plan:* ${socio.tipoPlan}
    💰 *Precio:* \$${socio.precioMensual.toStringAsFixed(2)}
    📱 *Próximo pago:* ${socio.fechaVencimiento.day}/${socio.fechaVencimiento.month}/${socio.fechaVencimiento.year}

    ¡Bienvenido al gym!

    *Gym Manager*
            ''',
          );
        }
        
        // Notificar a la aplicación sobre la aprobación
        NotificacionService.notificarAprobacionSocio(socioAprobado);
        
        return true;
    } catch (e) {
        return false;
    }
    }

    // NUEVO: Rechazar socio pendiente
    static Future<bool> rechazarSocio(Socio socio, {String? motivo}) async {
    try {
        // Eliminar socio rechazado
        await DatabaseHelper.instance.deleteSocio(socio.id!);
        
        // Notificar al socio por Telegram
        if (socio.telegramChatId != null) {
        await TelegramService.sendMessage(
            chatId: socio.telegramChatId!,
            message: '''
    ❌ *Solicitud Rechazada*

    Hola ${socio.nombreCompleto}, tu solicitud de registro ha sido rechazada.

    ${motivo != null ? '📝 *Motivo:* $motivo' : ''}

    💡 *Solución:* Contacta al administrador para más información.

    *Gym Manager*
            ''',
        );
        }
        
        return true;
    } catch (e) {
        return false;
    }
    }

    // NUEVO: Obtener estadísticas de aprobaciones
    static Future<Map<String, dynamic>> obtenerEstadisticasAprobacion() async {
    try {
        final socios = await DatabaseHelper.instance.getSocios();
        
        final totalSocios = socios.length;
        final sociosPendientes = socios.where((s) => s.pendienteAprobacion).length;
        final sociosAprobados = socios.where((s) => !s.pendienteAprobacion).length;
        
        return {
        'total': totalSocios,
        'pendientes': sociosPendientes,
        'aprobados': sociosAprobados,
        'porcentajePendientes': totalSocios > 0 ? (sociosPendientes / totalSocios * 100).round() : 0,
        };
    } catch (e) {
        return {'total': 0, 'pendientes': 0, 'aprobados': 0, 'porcentajePendientes': 0};
    }
    }
  
}