import 'package:flutter/foundation.dart';
import 'package:gym/core/database/database_helper.dart';
import 'package:gym/services/email_service.dart';
import 'package:gym/features/notificaciones/services/telegram_service.dart';
import 'package:gym/services/whatsapp_service.dart';
import 'package:gym/services/gym_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class RecordatoriosService {
  static final RecordatoriosService _instance = RecordatoriosService._internal();
  factory RecordatoriosService() => _instance;
  RecordatoriosService._internal();

  final _db = DatabaseHelper.instance;
  final _emailService = EmailService();
  final _whatsappService = WhatsAppService();

  // Claves de configuración
  static const String _keyRecordatoriosEnabled = 'recordatorios_enabled';
  static const String _keyDiasAnticipacion = 'recordatorios_dias_anticipacion';
  static const String _keyCanalEmail = 'recordatorios_canal_email';
  static const String _keyCanalTelegram = 'recordatorios_canal_telegram';
  static const String _keyCanalWhatsApp = 'recordatorios_canal_whatsapp';
  static const String _keyEnviarCumpleanos = 'recordatorios_cumpleanos';

  // Guardar configuración
  Future<void> saveConfig({
    required bool enabled,
    required int diasAnticipacion,
    required bool canalEmail,
    required bool canalTelegram,
    required bool canalWhatsApp,
    required bool enviarCumpleanos,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRecordatoriosEnabled, enabled);
    await prefs.setInt(_keyDiasAnticipacion, diasAnticipacion);
    await prefs.setBool(_keyCanalEmail, canalEmail);
    await prefs.setBool(_keyCanalTelegram, canalTelegram);
    await prefs.setBool(_keyCanalWhatsApp, canalWhatsApp);
    await prefs.setBool(_keyEnviarCumpleanos, enviarCumpleanos);
  }

  // Obtener configuración
  Future<Map<String, dynamic>> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool(_keyRecordatoriosEnabled) ?? false,
      'diasAnticipacion': prefs.getInt(_keyDiasAnticipacion) ?? 3,
      'canalEmail': prefs.getBool(_keyCanalEmail) ?? true,
      'canalTelegram': prefs.getBool(_keyCanalTelegram) ?? false,
      'canalWhatsApp': prefs.getBool(_keyCanalWhatsApp) ?? false,
      'enviarCumpleanos': prefs.getBool(_keyEnviarCumpleanos) ?? true,
    };
  }

  // Verificar si está habilitado
  Future<bool> isEnabled() async {
    final config = await getConfig();
    return config['enabled'] as bool;
  }

  // Enviar recordatorio manual a un socio específico
  Future<Map<String, dynamic>> enviarRecordatorioManual(Map<String, dynamic> socio) async {
    debugPrint('🔔 Enviando recordatorio manual a ${socio['nombreCompleto']}...');
    
    final config = await getConfig();
    
    // Determinar estado de cuota
    final estadoCuota = socio['estadoCuota'] as String? ?? 'Por Vencer'; // Default seguro
    
    if (estadoCuota == 'Vencido') {
      return await _enviarRecordatorioCuotaVencida(socio, config);
    } else if (estadoCuota == 'Por Vencer') {
      // Calcular días restantes si no existen
      if (!socio.containsKey('diasRestantes')) {
        final fechaVencimiento = DateTime.parse(socio['fechaVencimiento'] as String);
        final now = DateTime.now();
        final hoy = DateTime(now.year, now.month, now.day);
        final venc = DateTime(fechaVencimiento.year, fechaVencimiento.month, fechaVencimiento.day);
        final diasRestantes = venc.difference(hoy).inDays;
        socio['diasRestantes'] = diasRestantes;
      }
      return await _enviarRecordatorioCuotaProxima(socio, config);
    } else {
      // Si está al día, enviar un mensaje genérico o de próximo vencimiento
      // Por ahora tratamos como "Por Vencer" para informar la fecha
       if (!socio.containsKey('diasRestantes')) {
        final fechaVencimiento = DateTime.parse(socio['fechaVencimiento'] as String);
        final now = DateTime.now();
        final hoy = DateTime(now.year, now.month, now.day);
        final venc = DateTime(fechaVencimiento.year, fechaVencimiento.month, fechaVencimiento.day);
        final diasRestantes = venc.difference(hoy).inDays;
        socio['diasRestantes'] = diasRestantes;
      }
      return await _enviarRecordatorioCuotaProxima(socio, config);
    }
  }

  // Ejecutar envío de recordatorios (método principal)
  Future<Map<String, dynamic>> enviarRecordatorios({bool forzarEnvio = false}) async {
    debugPrint('🔔 Iniciando envío de recordatorios (Forzar: $forzarEnvio)...');
    
    final config = await getConfig();
    if (!(config['enabled'] as bool) && !forzarEnvio) {
      debugPrint('⚠️ Recordatorios deshabilitados');
      return {
        'enviados': 0, 
        'errores': 0,
        'enlacesWhatsApp': <Map<String, String>>[],
      };
    }

    int enviados = 0;
    int errores = 0;
    List<Map<String, String>> enlacesWhatsApp = [];

    try {
      // Primero obtener socios con cumpleaños hoy para excluirlos de recordatorios de cuota
      Set<int> sociosConCumpleanosHoy = {};
      if (config['enviarCumpleanos'] as bool) {
        final sociosCumpleanos = await _db.getSociosCumpleanosHoy();
        sociosConCumpleanosHoy = sociosCumpleanos.map((s) => s['id'] as int).toSet();
      }

      // 1. Recordatorios de cuota próxima a vencer
      final sociosCuotaProxima = await _db.getSociosCuotaPorVencer(
        diasAnticipacion: config['diasAnticipacion'] as int,
      );
      
      for (final socio in sociosCuotaProxima) {
        final socioId = socio['id'] as int;
        
        // PRIORIDAD: Si es cumpleaños, NO enviar recordatorio de cuota
        if (sociosConCumpleanosHoy.contains(socioId)) {
          debugPrint('🎂 Hoy es cumpleaños de ${socio['nombreCompleto']}, se omite recordatorio de cuota');
          continue;
        }
        
        // Verificar si ya se envió hoy (si no es forzado)
        if (!forzarEnvio && await _db.yaSeEnvioHoy(socioId: socioId, tipo: 'cuota_proxima')) {
          debugPrint('⏭️ Ya se envió recordatorio hoy a ${socio['nombreCompleto']}');
          continue;
        }

        final resultado = await _enviarRecordatorioCuotaProxima(socio, config);
        if (resultado['exito'] as bool) {
          enviados++;
        } else {
          errores++;
        }
        
        // Añadir enlace de WhatsApp si existe
        if (resultado['enlaceWhatsApp'] != null) {
          enlacesWhatsApp.add(resultado['enlaceWhatsApp'] as Map<String, String>);
        }
      }

      // 2. Recordatorios de cuota vencida
      final sociosCuotaVencida = await _db.getSociosCuotaVencida();
      
      for (final socio in sociosCuotaVencida) {
        final socioId = socio['id'] as int;
        
        // PRIORIDAD: Si es cumpleaños, NO enviar recordatorio de cuota
        if (sociosConCumpleanosHoy.contains(socioId)) {
          debugPrint('🎂 Hoy es cumpleaños de ${socio['nombreCompleto']}, se omite recordatorio de cuota vencida');
          continue;
        }
        
        if (!forzarEnvio && await _db.yaSeEnvioHoy(socioId: socioId, tipo: 'cuota_vencida')) {
          continue;
        }

        final resultado = await _enviarRecordatorioCuotaVencida(socio, config);
        if (resultado['exito'] as bool) {
          enviados++;
        } else {
          errores++;
        }
        
        // Añadir enlace de WhatsApp si existe
        if (resultado['enlaceWhatsApp'] != null) {
          enlacesWhatsApp.add(resultado['enlaceWhatsApp'] as Map<String, String>);
        }
      }

      // 3. Cumpleaños (si está habilitado) - SIEMPRE SE ENVÍA
      if (config['enviarCumpleanos'] as bool) {
        final sociosCumpleanos = await _db.getSociosCumpleanosHoy();
        
        for (final socio in sociosCumpleanos) {
          final socioId = socio['id'] as int;
          
          if (!forzarEnvio && await _db.yaSeEnvioHoy(socioId: socioId, tipo: 'cumpleanos')) {
            continue;
          }

          final resultado = await _enviarRecordatorioCumpleanos(socio, config);
          if (resultado['exito'] as bool) {
            enviados++;
          } else {
            errores++;
          }
          
          // Añadir enlace de WhatsApp si existe
          if (resultado['enlaceWhatsApp'] != null) {
            enlacesWhatsApp.add(resultado['enlaceWhatsApp'] as Map<String, String>);
          }
        }
      }

      debugPrint('✅ Recordatorios completados: $enviados enviados, $errores errores');
    } catch (e) {
      debugPrint('❌ Error en envío de recordatorios: $e');
    }

    return {
      'enviados': enviados, 
      'errores': errores,
      'enlacesWhatsApp': enlacesWhatsApp,
    };
  }

  // Enviar recordatorio de cuota próxima a vencer
  Future<Map<String, dynamic>> _enviarRecordatorioCuotaProxima(
    Map<String, dynamic> socio,
    Map<String, dynamic> config,
  ) async {
    try {
      final socioId = socio['id'] as int;
      final nombre = socio['nombreCompleto'] as String;
      final email = socio['email'] as String?;
      final telefono = socio['telefono'] as String?;
      final fechaVencimiento = DateTime.parse(socio['fechaVencimiento'] as String);
      final diasRestantes = socio['diasRestantes'] as int;

      // Obtener alias de transferencia (para Email y Telegram)
      final gymConfig = await GymConfigService().getConfig();
      final alias = gymConfig['aliasTransferencia'] as String;

      bool exitoEmail = false;
      bool exitoTelegram = false;
      bool exitoWhatsApp = false;
      String canal = '';
      Map<String, String>? enlaceWhatsApp;

      // Enviar por Email
      if (config['canalEmail'] as bool && email != null && email.isNotEmpty) {
        final htmlBody = _emailService.getTemplateRecordatorioCuota(
          nombreSocio: nombre,
          fechaVencimiento: DateFormat('dd/MM/yyyy').format(fechaVencimiento),
          diasRestantes: diasRestantes,
          aliasTransferencia: alias,
        );

        exitoEmail = await _emailService.sendEmail(
          to: email,
          subject: '🏋️ Recordatorio: Tu cuota vence en $diasRestantes días',
          body: htmlBody,
          isHtml: true,
        );

        if (exitoEmail) {
          canal = 'email';
          debugPrint('✅ Email enviado a $nombre ($email)');
        }
      }

      // Enviar por Telegram
      if (config['canalTelegram'] as bool && telefono != null && telefono.isNotEmpty) {
        final aliasTexto = alias.isNotEmpty 
            ? '\n\n💳 *Podés transferir a:* $alias' 
            : '';
        
        final mensaje = '''
🏋️ *Recordatorio de Cuota*

Hola $nombre,

Tu cuota de gimnasio vence en *$diasRestantes días* (el ${DateFormat('dd/MM/yyyy').format(fechaVencimiento)}).

Para continuar disfrutando de nuestras instalaciones sin interrupciones, te sugerimos realizar el pago antes de la fecha de vencimiento.$aliasTexto

Si ya realizaste el pago, por favor ignora este mensaje.

¡Gracias por ser parte de nuestra comunidad! 💪
        ''';

        exitoTelegram = await TelegramService.enviarMensajeATelefono(
          telefono: telefono,
          mensaje: mensaje,
        );

        if (exitoTelegram) {
          canal = canal.isEmpty ? 'telegram' : 'email+telegram';
          debugPrint('✅ Telegram enviado a $nombre ($telefono)');
        }
      }

      // Generar enlace de WhatsApp
      if (config['canalWhatsApp'] as bool && telefono != null && telefono.isNotEmpty) {
        if (_whatsappService.esNumeroValido(telefono)) {
          final mensaje = _whatsappService.getMensajeRecordatorioCuota(
            nombreSocio: nombre,
            fechaVencimiento: DateFormat('dd/MM/yyyy').format(fechaVencimiento),
            diasRestantes: diasRestantes,
            aliasTransferencia: alias,
          );
          
          final enlace = _whatsappService.generarEnlaceWhatsApp(
            telefono: telefono,
            mensaje: mensaje,
          );
          
          enlaceWhatsApp = {
            'nombre': nombre,
            'telefono': telefono,
            'enlace': enlace,
            'tipo': 'Cuota Próxima',
          };
          
          exitoWhatsApp = true;
          canal = canal.isEmpty ? 'whatsapp' : '$canal+whatsapp';
          debugPrint('✅ Enlace WhatsApp generado para $nombre');
        }
      }

      final exitoGeneral = exitoEmail || exitoTelegram || exitoWhatsApp;

      // Registrar en base de datos
      await _db.registrarRecordatorio(
        socioId: socioId,
        tipo: 'cuota_proxima',
        canal: canal.isEmpty ? 'ninguno' : canal,
        exitoso: exitoGeneral,
        detalles: exitoGeneral 
          ? 'Enviado correctamente' 
          : 'No se pudo enviar (email: $exitoEmail, telegram: $exitoTelegram, whatsapp: $exitoWhatsApp)',
      );

      return {
        'exito': exitoGeneral,
        'enlaceWhatsApp': enlaceWhatsApp,
      };
    } catch (e) {
      debugPrint('❌ Error enviando recordatorio cuota próxima: $e');
      return {
        'exito': false,
        'enlaceWhatsApp': null,
      };
    }
  }

  // Enviar recordatorio de cuota vencida
  Future<Map<String, dynamic>> _enviarRecordatorioCuotaVencida(
    Map<String, dynamic> socio,
    Map<String, dynamic> config,
  ) async {
    try {
      final socioId = socio['id'] as int;
      final nombre = socio['nombreCompleto'] as String;
      final email = socio['email'] as String?;
      final telefono = socio['telefono'] as String?;
      final fechaVencimiento = DateTime.parse(socio['fechaVencimiento'] as String);

      // Obtener alias de transferencia (para Email y Telegram)
      final gymConfig = await GymConfigService().getConfig();
      final alias = gymConfig['aliasTransferencia'] as String;

      bool exitoEmail = false;
      bool exitoTelegram = false;
      bool exitoWhatsApp = false;
      String canal = '';
      Map<String, String>? enlaceWhatsApp;

      // Enviar por Email
      if (config['canalEmail'] as bool && email != null && email.isNotEmpty) {
        final htmlBody = _emailService.getTemplateCuotaVencida(
          nombreSocio: nombre,
          fechaVencimiento: DateFormat('dd/MM/yyyy').format(fechaVencimiento),
          aliasTransferencia: alias,
        );

        exitoEmail = await _emailService.sendEmail(
          to: email,
          subject: '⚠️ Tu cuota de gimnasio está vencida',
          body: htmlBody,
          isHtml: true,
        );

        if (exitoEmail) {
          canal = 'email';
        }
      }

      // Enviar por Telegram
      if (config['canalTelegram'] as bool && telefono != null && telefono.isNotEmpty) {
        final aliasTexto = alias.isNotEmpty 
            ? '\n\n💳 *Podés transferir a:* $alias' 
            : '';
        
        final mensaje = '''
⚠️ *Cuota Vencida*

Hola $nombre,

Tu cuota venció el ${DateFormat('dd/MM/yyyy').format(fechaVencimiento)}.

Para continuar utilizando nuestras instalaciones, te pedimos que regularices tu situación a la brevedad.$aliasTexto

Si ya realizaste el pago, por favor comunícate con nosotros para actualizar tu estado.

¡Esperamos verte pronto! 🏋️
        ''';

        exitoTelegram = await TelegramService.enviarMensajeATelefono(
          telefono: telefono,
          mensaje: mensaje,
        );

        if (exitoTelegram) {
          canal = canal.isEmpty ? 'telegram' : 'email+telegram';
        }
      }

      // Generar enlace de WhatsApp
      if (config['canalWhatsApp'] as bool && telefono != null && telefono.isNotEmpty) {
        if (_whatsappService.esNumeroValido(telefono)) {
          final mensaje = _whatsappService.getMensajeRecordatorioCuotaVencida(
            nombreSocio: nombre,
            fechaVencimiento: DateFormat('dd/MM/yyyy').format(fechaVencimiento),
          );
          
          final enlace = _whatsappService.generarEnlaceWhatsApp(
            telefono: telefono,
            mensaje: mensaje,
          );
          
          enlaceWhatsApp = {
            'nombre': nombre,
            'telefono': telefono,
            'enlace': enlace,
            'tipo': 'Cuota Vencida',
          };
          
          exitoWhatsApp = true;
          canal = canal.isEmpty ? 'whatsapp' : '$canal+whatsapp';
        }
      }

      final exitoGeneral = exitoEmail || exitoTelegram || exitoWhatsApp;

      await _db.registrarRecordatorio(
        socioId: socioId,
        tipo: 'cuota_vencida',
        canal: canal.isEmpty ? 'ninguno' : canal,
        exitoso: exitoGeneral,
      );

      return {
        'exito': exitoGeneral,
        'enlaceWhatsApp': enlaceWhatsApp,
      };
    } catch (e) {
      debugPrint('❌ Error enviando recordatorio cuota vencida: $e');
      return {
        'exito': false,
        'enlaceWhatsApp': null,
      };
    }
  }

  // Enviar recordatorio de cumpleaños
  Future<Map<String, dynamic>> _enviarRecordatorioCumpleanos(
    Map<String, dynamic> socio,
    Map<String, dynamic> config,
  ) async {
    try {
      final socioId = socio['id'] as int;
      final nombre = socio['nombreCompleto'] as String;
      final email = socio['email'] as String?;
      final telefono = socio['telefono'] as String?;

      bool exitoEmail = false;
      bool exitoTelegram = false;
      bool exitoWhatsApp = false;
      String canal = '';
      Map<String, String>? enlaceWhatsApp;

      // Enviar por Email
      if (config['canalEmail'] as bool && email != null && email.isNotEmpty) {
        final htmlBody = _emailService.getTemplateCumpleanos(
          nombreSocio: nombre,
        );

        exitoEmail = await _emailService.sendEmail(
          to: email,
          subject: '🎉 ¡Feliz Cumpleaños, $nombre!',
          body: htmlBody,
          isHtml: true,
        );

        if (exitoEmail) {
          canal = 'email';
        }
      }

      // Enviar por Telegram
      if (config['canalTelegram'] as bool && telefono != null && telefono.isNotEmpty) {
        final mensaje = '''
🎉🎂🎈 *¡Feliz Cumpleaños!*

¡Feliz cumpleaños, $nombre!

Todo el equipo del gimnasio te desea un día increíble lleno de alegría y salud.

¡Gracias por ser parte de nuestra familia fitness!

🎁 *Sorpresa:* Consulta en recepción por tu regalo de cumpleaños 😊
        ''';

        exitoTelegram = await TelegramService.enviarMensajeATelefono(
          telefono: telefono,
          mensaje: mensaje,
        );

        if (exitoTelegram) {
          canal = canal.isEmpty ? 'telegram' : 'email+telegram';
        }
      }

      // Generar enlace de WhatsApp
      if (config['canalWhatsApp'] as bool && telefono != null && telefono.isNotEmpty) {
        if (_whatsappService.esNumeroValido(telefono)) {
          final mensaje = _whatsappService.getMensajeCumpleanos(
            nombreSocio: nombre,
          );
          
          final enlace = _whatsappService.generarEnlaceWhatsApp(
            telefono: telefono,
            mensaje: mensaje,
          );
          
          enlaceWhatsApp = {
            'nombre': nombre,
            'telefono': telefono,
            'enlace': enlace,
            'tipo': 'Cumpleaños',
          };
          
          exitoWhatsApp = true;
          canal = canal.isEmpty ? 'whatsapp' : '$canal+whatsapp';
        }
      }

      final exitoGeneral = exitoEmail || exitoTelegram || exitoWhatsApp;

      await _db.registrarRecordatorio(
        socioId: socioId,
        tipo: 'cumpleanos',
        canal: canal.isEmpty ? 'ninguno' : canal,
        exitoso: exitoGeneral,
      );

      return {
        'exito': exitoGeneral,
        'enlaceWhatsApp': enlaceWhatsApp,
      };
    } catch (e) {
      debugPrint('❌ Error enviando recordatorio cumpleaños: $e');
      return {
        'exito': false,
        'enlaceWhatsApp': null,
      };
    }
  }
}
