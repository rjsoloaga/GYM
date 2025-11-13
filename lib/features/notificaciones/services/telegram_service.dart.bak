import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gym/core/database/database_helper.dart';
import 'package:gym/features/socios/models/socio.dart';

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
            final nombreCompleto = registroPendiente['nombreCompleto'];
            final telefono = registroPendiente['telefono'];
            final dni = registroPendiente['dni'];
            await _completarRegistro(userId, chatId, nombreCompleto, telefono, dni, email);
          } else {
            await sendMessage(
              chatId: chatId,
              message: '❌ Email inválido. Ejemplo: nombre@email.com',
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

  static Future<void> _completarRegistro(String userId, String chatId, String nombreCompleto, String telefono, String dni, String email) async {
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
        final nuevoSocio = Socio(
          nombreCompleto: nombreCompleto,
          dni: dni,
          telefono: telefono,
          email: email,
          fechaInicio: DateTime.now(),
          fechaVencimiento: DateTime.now().add(Duration(days: 30)),
          precioMensual: 5000.0,
          tipoPlan: 'Pendiente',
          telegramChatId: chatId,
          pendienteAprobacion: true,
          fechaRegistroTelegram: DateTime.now(),
        );

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