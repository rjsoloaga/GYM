import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  final _secureStorage = const FlutterSecureStorage();
  
  // Claves para almacenamiento
  static const String _keySmtpHost = 'smtp_host';
  static const String _keySmtpPort = 'smtp_port';
  static const String _keySmtpUsername = 'smtp_username';
  static const String _keySmtpPassword = 'smtp_password';
  static const String _keySmtpFromName = 'smtp_from_name';
  static const String _keySmtpFromEmail = 'smtp_from_email';
  static const String _keySmtpUseSsl = 'smtp_use_ssl';
  static const String _keyEmailEnabled = 'email_enabled';

  // Guardar configuración SMTP
  Future<void> saveSmtpConfig({
    required String host,
    required int port,
    required String username,
    required String password,
    required String fromName,
    required String fromEmail,
    bool useSsl = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Guardar datos no sensibles en SharedPreferences
    await prefs.setString(_keySmtpHost, host);
    await prefs.setInt(_keySmtpPort, port);
    await prefs.setString(_keySmtpUsername, username);
    await prefs.setString(_keySmtpFromName, fromName);
    await prefs.setString(_keySmtpFromEmail, fromEmail);
    await prefs.setBool(_keySmtpUseSsl, useSsl);
    
    // Guardar contraseña de forma segura
    await _secureStorage.write(key: _keySmtpPassword, value: password);
  }

  // Obtener configuración SMTP
  Future<Map<String, dynamic>?> getSmtpConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final host = prefs.getString(_keySmtpHost);
      
      if (host == null) return null;
      
      final password = await _secureStorage.read(key: _keySmtpPassword);
      
      return {
        'host': host,
        'port': prefs.getInt(_keySmtpPort) ?? 587,
        'username': prefs.getString(_keySmtpUsername) ?? '',
        'password': password ?? '',
        'fromName': prefs.getString(_keySmtpFromName) ?? '',
        'fromEmail': prefs.getString(_keySmtpFromEmail) ?? '',
        'useSsl': prefs.getBool(_keySmtpUseSsl) ?? true,
      };
    } catch (e) {
      debugPrint('Error obteniendo configuración SMTP: $e');
      return null;
    }
  }

  // Verificar si el email está configurado
  Future<bool> isConfigured() async {
    final config = await getSmtpConfig();
    return config != null && config['host'] != null && config['host'].toString().isNotEmpty;
  }

  // Habilitar/deshabilitar envío de emails
  Future<void> setEmailEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEmailEnabled, enabled);
  }

  // Verificar si el envío de emails está habilitado
  Future<bool> isEmailEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEmailEnabled) ?? false;
  }

  // Enviar email
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String body,
    bool isHtml = true,
  }) async {
    try {
      // Validar email del destinatario
      if (!_isValidEmail(to)) {
        debugPrint('❌ Email inválido o ficticio: $to');
        return false;
      }

      // Verificar si está habilitado
      final enabled = await isEmailEnabled();
      if (!enabled) {
        debugPrint('Envío de emails deshabilitado');
        return false;
      }

      // Obtener configuración
      final config = await getSmtpConfig();
      if (config == null) {
        debugPrint('No hay configuración SMTP guardada');
        return false;
      }

      // Configurar servidor SMTP
      SmtpServer smtpServer;
      
      // Usar configuración específica para Gmail
      if (config['host'].toString().toLowerCase().contains('gmail')) {
        smtpServer = gmail(config['username'], config['password']);
      } else {
        // Para otros proveedores, usar configuración manual
        smtpServer = SmtpServer(
          config['host'],
          port: config['port'],
          username: config['username'],
          password: config['password'],
          ssl: config['port'] == 465, // SSL solo para puerto 465
          allowInsecure: false,
        );
      }

      // Crear mensaje
      final message = Message()
        ..from = Address(config['fromEmail'], config['fromName'])
        ..recipients.add(to)
        ..subject = subject;

      if (isHtml) {
        message.html = body;
      } else {
        message.text = body;
      }

      // Enviar
      final sendReport = await send(message, smtpServer);
      debugPrint('✅ Email enviado exitosamente a: $to');
      return true;
    } catch (e) {
      debugPrint('❌ Error enviando email a $to: $e');
      return false;
    }
  }

  // Validar formato de email
  bool _isValidEmail(String email) {
    // Regex para validar email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(email)) {
      return false;
    }
    
    // Lista de dominios ficticios comunes
    final fictitiousDomains = [
      'example.com',
      'test.com',
      'fake.com',
      'ficticio.com',
      'prueba.com',
      'demo.com',
      'localhost',
      'invalid.com',
      'noemail.com',
      'sinmail.com',
    ];
    
    final domain = email.split('@').last.toLowerCase();
    if (fictitiousDomains.contains(domain)) {
      return false;
    }
    
    return true;
  }

  // Probar conexión SMTP
  Future<bool> testConnection() async {
    try {
      final config = await getSmtpConfig();
      if (config == null) return false;

      // Configurar servidor SMTP
      SmtpServer smtpServer;
      
      // Usar configuración específica para Gmail
      if (config['host'].toString().toLowerCase().contains('gmail')) {
        smtpServer = gmail(config['username'], config['password']);
      } else {
        // Para otros proveedores, usar configuración manual
        smtpServer = SmtpServer(
          config['host'],
          port: config['port'],
          username: config['username'],
          password: config['password'],
          ssl: config['port'] == 465, // SSL solo para puerto 465
          allowInsecure: false,
        );
      }

      // Intentar conectar
      final connection = PersistentConnection(smtpServer);
      await connection.send(Message()
        ..from = Address(config['fromEmail'], config['fromName'])
        ..recipients.add(config['fromEmail'])
        ..subject = 'Test de Conexión'
        ..text = 'Este es un email de prueba para verificar la configuración SMTP.');
      
      await connection.close();
      return true;
    } catch (e) {
      debugPrint('Error probando conexión: $e');
      return false;
    }
  }

  // Plantillas de email predefinidas
  String getTemplateRecordatorioCuota({
    required String nombreSocio,
    required String fechaVencimiento,
    required int diasRestantes,
    String? aliasTransferencia,
  }) {
    final aliasHtml = (aliasTransferencia != null && aliasTransferencia.isNotEmpty) 
        ? '''
        <div style="background-color: #e3f2fd; padding: 15px; border-radius: 5px; margin-top: 15px; border-left: 4px solid #2196f3;">
            <strong>💳 Podés transferir a:</strong> <br>
            <span style="font-family: monospace; font-size: 1.2em; color: #0d47a1;">$aliasTransferencia</span>
        </div>
        ''' 
        : '';

    return '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .button { display: inline-block; padding: 12px 30px; background: #667eea; color: white; text-decoration: none; border-radius: 5px; margin-top: 20px; }
        .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🏋️ Recordatorio de Cuota</h1>
        </div>
        <div class="content">
            <h2>Hola $nombreSocio,</h2>
            <p>Te recordamos que tu cuota de gimnasio vence en <strong>$diasRestantes días</strong> (el $fechaVencimiento).</p>
            <p>Para continuar disfrutando de nuestras instalaciones sin interrupciones, te sugerimos realizar el pago antes de la fecha de vencimiento.</p>
            
            $aliasHtml
            
            <p>Si ya realizaste el pago, por favor ignora este mensaje.</p>
            <p>¡Gracias por ser parte de nuestra comunidad!</p>
        </div>
        <div class="footer">
            <p>Este es un mensaje automático. Por favor no respondas a este email.</p>
        </div>
    </div>
</body>
</html>
    ''';
  }

  String getTemplateCuotaVencida({
    required String nombreSocio,
    required String fechaVencimiento,
    String? aliasTransferencia,
  }) {
    final aliasHtml = (aliasTransferencia != null && aliasTransferencia.isNotEmpty) 
        ? '''
        <div style="background-color: #e3f2fd; padding: 15px; border-radius: 5px; margin-top: 15px; border-left: 4px solid #2196f3;">
            <strong>💳 Podés transferir a:</strong> <br>
            <span style="font-family: monospace; font-size: 1.2em; color: #0d47a1;">$aliasTransferencia</span>
        </div>
        ''' 
        : '';

    return '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .alert { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
        .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>⚠️ Cuota Vencida</h1>
        </div>
        <div class="content">
            <h2>Hola $nombreSocio,</h2>
            <div class="alert">
                <strong>Tu cuota venció el $fechaVencimiento</strong>
            </div>
            <p>Para continuar utilizando nuestras instalaciones, te pedimos que regularices tu situación a la brevedad.</p>
            
            $aliasHtml
            
            <p>Si ya realizaste el pago, por favor comunícate con nosotros para actualizar tu estado.</p>
            <p>¡Esperamos verte pronto!</p>
        </div>
        <div class="footer">
            <p>Este es un mensaje automático. Por favor no respondas a este email.</p>
        </div>
    </div>
</body>
</html>
    ''';
  }

  String getTemplateCumpleanos({
    required String nombreSocio,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%); color: #333; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; text-align: center; }
        .emoji { font-size: 48px; }
        .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="emoji">🎉🎂🎈</div>
            <h1>¡Feliz Cumpleaños!</h1>
        </div>
        <div class="content">
            <h2>¡Feliz cumpleaños, $nombreSocio!</h2>
            <p>Todo el equipo del gimnasio te desea un día increíble lleno de alegría y salud.</p>
            <p>¡Gracias por ser parte de nuestra familia fitness!</p>
            <p>🎁 <strong>Sorpresa:</strong> Consulta en recepción por tu regalo de cumpleaños 😊</p>
        </div>
        <div class="footer">
            <p>Este es un mensaje automático. Por favor no respondas a este email.</p>
        </div>
    </div>
</body>
</html>
    ''';
  }
}
