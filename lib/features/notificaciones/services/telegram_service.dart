import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gym/core/database/database_helper.dart';
import 'package:gym/features/socios/models/socio.dart';
import 'package:gym/features/planes/models/plan.dart';
import 'package:gym/features/planes/services/plan_service.dart';

class TelegramService {
  static const String _botToken = '8597219422:AAEvMJE6tE8-3RnUHSq3MVZvsErLN7_Dw5E';
  static const String _baseUrl = 'https://api.telegram.org/bot$_botToken';
  
  // Mapa para guardar registros en proceso
  static final Map<String, Map<String, dynamic>> _registrosPendientes = {};
  static int _lastUpdateId = 0;

  static Future<bool> sendMessage({
    required String chatId,
    required String message,
  }) async {
    try {
      print('🤖 [TelegramService] Enviando mensaje:');
      print('   ├─ ChatID: $chatId');
      print('   ├─ Mensaje: ${message.substring(0, 50)}...');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/sendMessage'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'chat_id': chatId,
          'text': message,
          'parse_mode': 'HTML',
        }),
      );

      if (response.statusCode == 200) {
        print('   ✅ Respuesta exitosa de Telegram API (status 200)');
        return true;
      } else {
        print('   ❌ Error en respuesta: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('   ❌ Excepción en TelegramService: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getUpdates() async {
    try {
      _limpiarRegistrosAntiguos();
      
      // Usar offset para obtener solo mensajes nuevos
      final url = '$_baseUrl/getUpdates${_lastUpdateId > 0 ? '?offset=${_lastUpdateId + 1}' : ''}';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['result'] ?? [];
        
        if (results.isNotEmpty) {
          _lastUpdateId = results.last['update_id'];
          
          for (final update in results) {
            await _procesarMensaje(update);
          }
        }
        
        return results;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> _procesarMensaje(dynamic update) async {
    final message = update['message'];
    if (message != null) {
      final text = message['text']?.toString()?.trim() ?? '';
      final chatId = message['chat']['id'].toString();
      final from = message['from'];
      final nombre = from['first_name'] ?? 'Usuario';
      final userId = from['id'].toString();

      final registroPendiente = _registrosPendientes[userId];
      
      // LIMPIAR REGISTROS ANTIGUOS PRIMERO
      _limpiarRegistrosAntiguos();

      // SOLO PROCESAR /start O mensajes dentro de un registro pendiente
      if (text == '/start') {
        _registrosPendientes[userId] = {
          'chatId': chatId,
          'nombreTelegram': nombre,
          'paso': 'esperando_nombre', // NUEVO: Cambiamos a esperar nombre primero
          'timestamp': DateTime.now().millisecondsSinceEpoch
        };
        await _solicitarNombre(chatId); // NUEVO: Método para pedir nombre
      } 
      else if (registroPendiente != null) {
        final pasoActual = registroPendiente['paso'];
        
        // NUEVO: Paso para pedir nombre completo
        if (pasoActual == 'esperando_nombre') {
          final nombreCompleto = text.trim();
          if (nombreCompleto.length >= 3) { // Validación: al menos 3 caracteres
            _registrosPendientes[userId] = {
              'chatId': chatId,
              'nombreTelegram': registroPendiente['nombreTelegram'],
              'nombreCompleto': nombreCompleto, // Guardar nombre completo
              'paso': 'esperando_telefono',
              'timestamp': DateTime.now().millisecondsSinceEpoch
            };
            await _solicitarTelefono(chatId, nombreCompleto); // NUEVO: Método para pedir teléfono
          } else {
            await sendMessage(
              chatId: chatId,
              message: '❌ Nombre muy corto. Por favor, envía tu nombre completo real',
            );
          }
        }
        else if (pasoActual == 'esperando_telefono') {
          final telefono = _extraerSoloNumeros(text);
          if (telefono != null && _esNumeroTelefonoValido(telefono)) {
            _registrosPendientes[userId] = {
              'chatId': chatId,
              'nombreTelegram': registroPendiente['nombreTelegram'],
              'nombreCompleto': registroPendiente['nombreCompleto'],
              'telefono': telefono,
              'paso': 'esperando_dni',
              'timestamp': DateTime.now().millisecondsSinceEpoch
            };
            await _solicitarDNI(chatId, telefono);
          } else {
            await sendMessage(
              chatId: chatId,
              message: '❌ Número inválido. Envía solo números, ejemplo: 3625123456',
            );
          }
        }
        else if (pasoActual == 'esperando_dni') {
          final dni = _extraerSoloNumeros(text);
          if (dni != null && _esDNIValido(dni)) {
            _registrosPendientes[userId] = {
              'chatId': chatId,
              'nombreTelegram': registroPendiente['nombreTelegram'],
              'nombreCompleto': registroPendiente['nombreCompleto'],
              'telefono': registroPendiente['telefono'],
              'dni': dni,
              'paso': 'esperando_email',
              'timestamp': DateTime.now().millisecondsSinceEpoch
            };
            await _solicitarEmail(chatId);
          } else {
            await sendMessage(
              chatId: chatId,
              message: '❌ DNI inválido. Ejemplo: 40123456',
            );
          }
        }
        else if (pasoActual == 'esperando_email') {
          final email = text.trim();
          if (_esEmailValido(email)) {
            _registrosPendientes[userId] = {
              ...registroPendiente,
              'email': email,
              'paso': 'esperando_plan',
              'fechaConsultaPlanes': DateTime.now().toIso8601String(),
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            };
            final fechaConsultaPrevia = registroPendiente['fechaConsultaPlanes'] != null 
                ? DateTime.parse(registroPendiente['fechaConsultaPlanes']) 
                : null;
            await _solicitarPlan(chatId, fechaConsultaPrevia: fechaConsultaPrevia);
          } else {
            await sendMessage(
              chatId: chatId,
              message: '❌ Email inválido. Ejemplo: nombre@email.com',
            );
          }
        }
        else if (pasoActual == 'esperando_plan') {
          final planes = await DatabaseHelper.instance.getPlanes(soloActivos: true);
          final opcion = int.tryParse(text.trim());
          
          // Obtener planes actualizados para asegurar que tenemos los precios más recientes
          final planService = PlanService();
          final planesActualizados = await planService.obtenerPlanesActivos();
          
          if (opcion != null && opcion >= 1 && opcion <= planesActualizados.length) {
            final planSeleccionado = planesActualizados[opcion - 1];
            final nombreCompleto = registroPendiente['nombreCompleto'];
            final telefono = registroPendiente['telefono'];
            final dni = registroPendiente['dni'];
            final email = registroPendiente['email'];
            
            await _completarRegistro(
              userId, 
              chatId, 
              nombreCompleto, 
              telefono, 
              dni, 
              email,
              planId: planSeleccionado.id,
              planNombre: planSeleccionado.nombre,
              planPrecio: planSeleccionado.precio,
              duracionDias: planSeleccionado.duracionDias ?? 30, // Valor por defecto de 30 días
            );
          } else {
            await sendMessage(
              chatId: chatId,
              message: '❌ Opción inválida. Por favor, selecciona un número de la lista.',
            );
          }
        }
      }
    }
  }

  // NUEVO: Método para solicitar nombre completo
  static Future<void> _solicitarNombre(String chatId) async {
    await sendMessage(
      chatId: chatId,
      message: '''
🎉 *¡Bienvenido al Gym!*

Para registrarte, primero envía tu *nombre completo*:

*Ejemplo:* Juan Pérez
      ''',
    );
  }

  // NUEVO: Método para solicitar teléfono (reemplaza _enviarInstrucciones)
  static Future<void> _solicitarTelefono(String chatId, String nombreCompleto) async {
    await sendMessage(
      chatId: chatId,
      message: '''
✅ *Nombre recibido: $nombreCompleto*

Ahora envía tu *número de teléfono*:

*Ejemplo:* 3625123456
      ''',
    );
  }

  static Future<void> _solicitarDNI(String chatId, String telefono) async {
    await sendMessage(
      chatId: chatId,
      message: '''
✅ *Teléfono recibido: $telefono*

Ahora envía tu DNI:

*Ejemplo:* 40123456
      ''',
    );
  }

  static Future<void> _solicitarEmail(String chatId) async {
    await sendMessage(
      chatId: chatId,
      message: '''
✅ *DNI recibido*

Ahora envía tu email:

*Ejemplo:* nombre@email.com
      ''',
    );
  }

  static Future<void> _solicitarPlan(String chatId, {DateTime? fechaConsultaPrevia}) async {
    try {
      final planService = PlanService();
      
      // Verificar si hay cambios en los planes desde la última consulta
      if (fechaConsultaPrevia != null) {
        final hayCambios = await planService.hanCambiadoLosPlanes(fechaConsultaPrevia);
        if (hayCambios) {
          await sendMessage(
            chatId: chatId,
            message: 'ℹ️ *¡Atención!* Los planes han sido actualizados recientemente. Aquí tienes la información más reciente:',
          );
        }
      }

      // Obtener planes con información de actualización
      final ahora = DateTime.now();
      final planesConEstado = await planService.getPlanesConEstadoActualizacion(fechaConsultaPrevia);
      
      if (planesConEstado.isEmpty) {
        await sendMessage(
          chatId: chatId,
          message: '⚠️ No hay planes disponibles. Contacta al administrador.',
        );
        return;
      }

      final buffer = StringBuffer('''
✅ *Email recibido*\n\nSelecciona tu plan de entrenamiento:\n\n''');

      for (var i = 0; i < planesConEstado.length; i++) {
        final item = planesConEstado[i];
        final plan = item['plan'] as Plan;
        final haCambiado = item['haCambiado'] as bool;
        
        buffer.write('${i + 1}. *${plan.nombre}* - \$${plan.precio.toStringAsFixed(2)} (${plan.duracionDias} días)');
        
        if (haCambiado) {
          buffer.write(' 🔄');
        }
        
        buffer.write('\n');
      }
      
      // Agregar información de actualización
      if (fechaConsultaPrevia != null) {
        buffer.write('\n*Última actualización:* ${ahora.toString().substring(0, 16)}\n');
      }
      
      buffer.write('\n_Selecciona el número correspondiente al plan que deseas contratar._');

      await sendMessage(
        chatId: chatId,
        message: buffer.toString(),
      );
    } catch (e) {
      print('❌ Error en _solicitarPlan: $e');
      await sendMessage(
        chatId: chatId,
        message: '❌ Error al cargar los planes. Por favor, inténtalo de nuevo más tarde.',
      );
    }
  }

  static Future<void> _completarRegistro(
    String userId, 
    String chatId, 
    String nombreCompleto, 
    String telefono, 
    String dni, 
    String email, {
    int? planId,
    String planNombre = 'Mensual',
    double planPrecio = 5000.0,
    int duracionDias = 30,
  }) async {
    try {
      print('═══════════════════════════════════════════════');
      print('📝 COMPLETANDO REGISTRO DE TELEGRAM');
      print('├─ UserID: $userId');
      print('├─ ChatID: $chatId');
      print('├─ Nombre: $nombreCompleto');
      print('├─ Teléfono: $telefono');
      print('├─ DNI: $dni');
      print('├─ Email: $email');
      print('═══════════════════════════════════════════════');
      
      _registrosPendientes.remove(userId);
      
      final socios = await DatabaseHelper.instance.getSocios();
      Socio? socioExistente;
      
      for (final socio in socios) {
        final telefonoSocioLimpio = socio.telefono.replaceAll(RegExp(r'[^\d]'), '');
        final telefonoMensajeLimpio = telefono.replaceAll(RegExp(r'[^\d]'), '');
        
        if (telefonoSocioLimpio == telefonoMensajeLimpio || socio.dni == dni) {
          socioExistente = socio;
          print('✅ Socio existente encontrado: ${socio.nombreCompleto} (ID: ${socio.id})');
          break;
        }
      }

      if (socioExistente != null) {
        final socioActualizado = socioExistente.copyWith(telegramChatId: chatId);
        await DatabaseHelper.instance.updateSocio(socioActualizado);
        print('✅ ChatID actualizado en socio existente (ID: ${socioExistente.id})');
        
        await sendMessage(
          chatId: chatId,
          message: '''
✅ *¡Ya estás registrado!*

Hola ${socioExistente.nombreCompleto}, 
ahora recibirás recordatorios de pago.
          ''',
        );
      } else {
        final ahora = DateTime.now();
        final nuevoSocio = Socio(
          nombreCompleto: nombreCompleto,
          dni: dni,
          telefono: telefono,
          email: email,
          fechaInicio: ahora,
          fechaVencimiento: ahora.add(Duration(days: duracionDias)),
          precioMensual: planPrecio,
          tipoPlan: planNombre,
          telegramChatId: chatId,
          pendienteAprobacion: true,
          fechaRegistroTelegram: ahora,
          planId: planId,
        );
        
        // Registrar también el pago inicial
        try {
          await DatabaseHelper.instance.insertarPago(
            nuevoSocio.id!,
            planPrecio,
            ahora,
            'Efectivo',
            usuarioId: 1, // ID del usuario administrador por defecto
          );
        } catch (e) {
          print('⚠️ No se pudo registrar el pago inicial: $e');
        }

        await DatabaseHelper.instance.insertarSocio(nuevoSocio);
        print('✅ Nuevo socio creado con ChatID: $chatId');
        
        await sendMessage(
          chatId: chatId,
          message: '''
🎉 *¡Registro completado!*

👤 Nombre: $nombreCompleto
📱 Teléfono: $telefono
🆔 DNI: $dni
📧 Email: $email
💳 Plan: $planNombre (\$${planPrecio.toStringAsFixed(2)})
📅 Vencimiento: ${DateTime.now().add(Duration(days: duracionDias)).toString().split(' ')[0]}

*Estado:* Pendiente de aprobación
🔔 Recibirás un mensaje cuando estés activo
          ''',
        );
      }
    } catch (e) {
      print('❌ Error en _completarRegistro: $e');
      await sendMessage(
        chatId: chatId,
        message: '❌ Error. Contacta al administrador.',
      );
    }
  }

  // MÉTODOS AUXILIARES
  static String? _extraerSoloNumeros(String texto) {
    final soloNumeros = texto.replaceAll(RegExp(r'[^\d]'), '');
    return soloNumeros.isNotEmpty ? soloNumeros : null;
  }

  static bool _esNumeroTelefonoValido(String numero) {
    return numero.length >= 8 && numero.length <= 12;
  }

  static bool _esDNIValido(String dni) {
    return dni.length >= 7 && dni.length <= 9;
  }

  static bool _esEmailValido(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }

  static void _limpiarRegistrosAntiguos() {
    final ahora = DateTime.now().millisecondsSinceEpoch;
    final keysToRemove = <String>[];
    
    _registrosPendientes.forEach((userId, registro) {
      final timestamp = registro['timestamp'] ?? 0;
      if (ahora - timestamp > 300000) { // 5 minutos
        keysToRemove.add(userId);
      }
    });
    
    keysToRemove.forEach(_registrosPendientes.remove);
  }

  static Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/getMe'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}