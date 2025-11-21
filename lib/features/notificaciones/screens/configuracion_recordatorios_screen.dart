import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym/services/recordatorios_service.dart';
import 'package:gym/services/email_service.dart';
import 'package:gym/features/notificaciones/services/telegram_service.dart';
import 'package:gym/services/whatsapp_service.dart';
import 'package:gym/core/database/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ConfiguracionRecordatoriosScreen extends StatefulWidget {
  const ConfiguracionRecordatoriosScreen({super.key});

  @override
  State<ConfiguracionRecordatoriosScreen> createState() => _ConfiguracionRecordatoriosScreenState();
}

class _ConfiguracionRecordatoriosScreenState extends State<ConfiguracionRecordatoriosScreen> {
  final _recordatoriosService = RecordatoriosService();
  final _emailService = EmailService();
  final _whatsappService = WhatsAppService();
  final _db = DatabaseHelper.instance;

  bool _loading = true;
  bool _enviando = false;
  
  // Configuración
  bool _recordatoriosEnabled = false;
  int _diasAnticipacion = 3;
  bool _canalEmail = true;
  bool _canalTelegram = false;
  bool _canalWhatsApp = false;
  bool _enviarCumpleanos = true;

  // Estadísticas
  int _totalEnviados = 0;
  int _enviadosHoy = 0;
  List<Map<String, dynamic>> _historialReciente = [];

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    setState(() => _loading = true);

    try {
      final config = await _recordatoriosService.getConfig();
      final historial = await _db.getHistorialRecordatorios(limit: 10);
      
      // Contar envíos de hoy
      final hoy = DateTime.now();
      final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
      final enviosHoy = historial.where((r) {
        final fecha = DateTime.parse(r['fechaEnvio'] as String);
        return fecha.isAfter(inicioHoy);
      }).length;

      setState(() {
        _recordatoriosEnabled = config['enabled'] as bool;
        _diasAnticipacion = config['diasAnticipacion'] as int;
        _canalEmail = config['canalEmail'] as bool;
        _canalTelegram = config['canalTelegram'] as bool;
        _canalWhatsApp = config['canalWhatsApp'] as bool;
        _enviarCumpleanos = config['enviarCumpleanos'] as bool;
        _historialReciente = historial;
        _totalEnviados = historial.length;
        _enviadosHoy = enviosHoy;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando configuración: $e')),
        );
      }
    }
  }

  Future<void> _guardarConfiguracion() async {
    try {
      await _recordatoriosService.saveConfig(
        enabled: _recordatoriosEnabled,
        diasAnticipacion: _diasAnticipacion,
        canalEmail: _canalEmail,
        canalTelegram: _canalTelegram,
        canalWhatsApp: _canalWhatsApp,
        enviarCumpleanos: _enviarCumpleanos,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Configuración guardada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _enviarAhora() async {
    // Verificar configuraciones
    final emailConfigured = await _emailService.isConfigured();
    final telegramConfigured = await TelegramService.isConfigured();

    if (_canalEmail && !emailConfigured) {
      _mostrarError('Email no configurado. Ve a "Configuración de Email" primero.');
      return;
    }

    if (_canalTelegram && !telegramConfigured) {
      _mostrarError('Telegram no configurado. Ve a "Configuración de Telegram" primero.');
      return;
    }

    if (!_canalEmail && !_canalTelegram) {
      _mostrarError('Debes activar al menos un canal (Email o Telegram).');
      return;
    }

    // Confirmar
    bool forzarEnvio = false;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF2a2a2a),
          title: const Row(
            children: [
              Icon(Icons.send, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text('Enviar Recordatorios', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '¿Deseas enviar los recordatorios ahora?\n\n'
                'Se enviarán a todos los socios que cumplan las condiciones configuradas.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Forzar reenvío', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Enviar incluso si ya se envió hoy', style: TextStyle(color: Colors.white60)),
                value: forzarEnvio,
                onChanged: (value) => setState(() => forzarEnvio = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.deepPurple,
                checkColor: Colors.white,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
              ),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.send, size: 18),
              label: const Text('Enviar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true) return;

    setState(() => _enviando = true);

    try {
      final resultado = await _recordatoriosService.enviarRecordatorios(forzarEnvio: forzarEnvio);
      final enviados = resultado['enviados'] as int;
      final errores = resultado['errores'] as int;
      final enlacesWhatsApp = resultado['enlacesWhatsApp'] as List<Map<String, String>>?;

      await _cargarConfiguracion(); // Recargar historial

      if (mounted) {
        // Mostrar resultado general
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Proceso completado: $enviados enviados, $errores errores'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        // Si hay enlaces de WhatsApp, mostrarlos en un diálogo
        if (enlacesWhatsApp != null && enlacesWhatsApp.isNotEmpty) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF2a2a2a),
              title: const Row(
                children: [
                  Icon(Icons.chat_bubble, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Enviar WhatsApp', style: TextStyle(color: Colors.white)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Haz clic en cada socio para abrir WhatsApp con el mensaje listo:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: enlacesWhatsApp.length,
                        itemBuilder: (context, index) {
                          final item = enlacesWhatsApp[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(Icons.send, color: Colors.white, size: 16),
                            ),
                            title: Text(
                              item['nombre'] ?? 'Socio',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '${item['tipo']} • ${item['telefono']}',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.content_copy, color: Colors.white70),
                              tooltip: 'Copiar enlace',
                              onPressed: () async {
                                final enlace = item['enlace'];
                                if (enlace != null) {
                                  await Clipboard.setData(ClipboardData(text: enlace));
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('📋 Enlace copiado: ${item['nombre']}'),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            onTap: () async {
                              final enlace = item['enlace'];
                              if (enlace != null) {
                                try {
                                  final uri = Uri.parse(enlace);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  } else {
                                    // Si no se puede abrir, copiar al portapapeles
                                    if (mounted) {
                                      await Clipboard.setData(ClipboardData(text: enlace));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('📋 Enlace copiado al portapapeles'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  // En caso de error, copiar al portapapeles
                                  if (mounted) {
                                    await Clipboard.setData(ClipboardData(text: enlace));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('📋 Enlace copiado al portapapeles. Pégalo en tu navegador.'),
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          );
        } else {
          // Si no hay WhatsApp, mostrar diálogo normal
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF2a2a2a),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Envío Completado', style: TextStyle(color: Colors.white)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ Enviados: $enviados', style: const TextStyle(color: Colors.white)),
                  Text('❌ Errores: $errores', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  if (enviados == 0)
                    const Text(
                      'No hay socios que cumplan las condiciones configuradas.',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white70),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Configuración de Recordatorios'),
          backgroundColor: Colors.deepPurple,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Recordatorios'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _mostrarAyuda(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a1a),
              Colors.black,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === ESTADO GENERAL ===
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: _recordatoriosEnabled ? Colors.green.shade700 : Colors.grey.shade800,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text(
                          'Recordatorios Automáticos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          _recordatoriosEnabled
                              ? 'Los recordatorios se enviarán automáticamente cada día'
                              : 'Los recordatorios están desactivados',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        value: _recordatoriosEnabled,
                        onChanged: (value) {
                          setState(() => _recordatoriosEnabled = value);
                          _guardarConfiguracion();
                        },
                        secondary: Icon(
                          _recordatoriosEnabled ? Icons.notifications_active : Icons.notifications_off,
                          color: Colors.white,
                          size: 32,
                        ),
                        activeColor: Colors.white,
                        activeTrackColor: Colors.white70,
                      ),
                      if (_recordatoriosEnabled) ...[
                        const Divider(color: Colors.white30),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard('Enviados Hoy', _enviadosHoy.toString(), Icons.today, Colors.white),
                            _buildStatCard('Total', _totalEnviados.toString(), Icons.email, Colors.white),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // === CONFIGURACIÓN DE CUOTAS ===
              Text(
                'Recordatorios de Cuotas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade300,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: const Color(0xFF2a2a2a),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Días de anticipación',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _diasAnticipacion.toDouble(),
                              min: 1,
                              max: 14,
                              divisions: 13,
                              label: '$_diasAnticipacion días',
                              activeColor: Colors.deepPurple.shade300,
                              inactiveColor: Colors.grey.shade700,
                              onChanged: (value) {
                                setState(() => _diasAnticipacion = value.toInt());
                              },
                              onChangeEnd: (value) => _guardarConfiguracion(),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_diasAnticipacion días',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Se enviará un recordatorio $_diasAnticipacion días antes del vencimiento',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // === CANALES DE ENVÍO ===
              Text(
                'Canales de Envío',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade300,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: const Color(0xFF2a2a2a),
                child: Column(
                  children: [
                    CheckboxListTile(
                      title: const Text(
                        'Email',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Enviar recordatorios por correo electrónico',
                        style: TextStyle(color: Colors.white70),
                      ),
                      secondary: const Icon(Icons.email, color: Colors.blue, size: 28),
                      value: _canalEmail,
                      activeColor: Colors.deepPurple,
                      checkColor: Colors.white,
                      onChanged: (value) {
                        setState(() => _canalEmail = value ?? false);
                        _guardarConfiguracion();
                      },
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    CheckboxListTile(
                      title: const Text(
                        'Telegram',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Enviar recordatorios por Telegram',
                        style: TextStyle(color: Colors.white70),
                      ),
                      secondary: const Icon(Icons.telegram, color: Colors.blue, size: 28),
                      value: _canalTelegram,
                      activeColor: Colors.deepPurple,
                      checkColor: Colors.white,
                      onChanged: (value) {
                        setState(() => _canalTelegram = value ?? false);
                        _guardarConfiguracion();
                      },
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    // WhatsApp deshabilitado temporalmente (solo Windows)
                    Opacity(
                      opacity: 0.5,
                      child: CheckboxListTile(
                        title: const Text(
                          'WhatsApp',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        subtitle: const Text(
                          'Disponible solo en Windows',
                          style: TextStyle(color: Colors.orange),
                        ),
                        secondary: const Icon(Icons.chat_bubble, color: Colors.green, size: 28),
                        value: false,
                        enabled: false,
                        onChanged: null,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // === OTROS RECORDATORIOS ===
              Text(
                'Otros Recordatorios',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade300,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: const Color(0xFF2a2a2a),
                child: SwitchListTile(
                  title: const Text(
                    'Cumpleaños',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Enviar felicitaciones de cumpleaños',
                    style: TextStyle(color: Colors.white70),
                  ),
                  secondary: const Icon(Icons.cake, color: Colors.pink, size: 28),
                  value: _enviarCumpleanos,
                  activeColor: Colors.deepPurple,
                  activeTrackColor: Colors.deepPurple.shade300,
                  onChanged: (value) {
                    setState(() => _enviarCumpleanos = value);
                    _guardarConfiguracion();
                  },
                ),
              ),

              const SizedBox(height: 32),

              // === BOTÓN ENVIAR AHORA ===
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.deepPurple.shade700],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _enviando ? null : _enviarAhora,
                  icon: _enviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send, size: 24),
                  label: Text(
                    _enviando ? 'Enviando...' : 'Enviar Recordatorios Ahora',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(18),
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // === HISTORIAL RECIENTE ===
              if (_historialReciente.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Historial Reciente',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade300,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _cargarConfiguracion(),
                      icon: const Icon(Icons.refresh),
                      color: Colors.deepPurple.shade300,
                      tooltip: 'Actualizar',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: const Color(0xFF2a2a2a),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _historialReciente.length > 5 ? 5 : _historialReciente.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white12),
                    itemBuilder: (context, index) {
                      final item = _historialReciente[index];
                      return _buildHistorialItem(item);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildHistorialItem(Map<String, dynamic> item) {
    final tipo = item['tipo'] as String;
    final canal = item['canal'] as String;
    final fecha = DateTime.parse(item['fechaEnvio'] as String);
    final exitoso = (item['exitoso'] as int) == 1;
    final nombreSocio = item['nombreCompleto'] as String;

    IconData tipoIcon;
    Color tipoColor;
    String tipoTexto;

    switch (tipo) {
      case 'cuota_proxima':
        tipoIcon = Icons.schedule;
        tipoColor = Colors.orange;
        tipoTexto = 'Cuota Próxima';
        break;
      case 'cuota_vencida':
        tipoIcon = Icons.warning;
        tipoColor = Colors.red;
        tipoTexto = 'Cuota Vencida';
        break;
      case 'cumpleanos':
        tipoIcon = Icons.cake;
        tipoColor = Colors.pink;
        tipoTexto = 'Cumpleaños';
        break;
      default:
        tipoIcon = Icons.notifications;
        tipoColor = Colors.grey;
        tipoTexto = tipo;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: tipoColor.withOpacity(0.2),
        child: Icon(tipoIcon, color: tipoColor, size: 20),
      ),
      title: Text(
        nombreSocio,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tipoTexto,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            '${DateFormat('dd/MM/yyyy HH:mm').format(fecha)} • $canal',
            style: const TextStyle(fontSize: 11, color: Colors.white54),
          ),
        ],
      ),
      trailing: Icon(
        exitoso ? Icons.check_circle : Icons.error,
        color: exitoso ? Colors.green : Colors.red,
        size: 20,
      ),
    );
  }

  void _mostrarAyuda() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Ayuda - Recordatorios'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '¿Cómo funcionan los recordatorios?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Los recordatorios se envían automáticamente cada día a las 9:00 AM.\n\n'
                '2. Se envían 3 tipos de recordatorios:\n'
                '   • Cuota próxima a vencer (X días antes)\n'
                '   • Cuota vencida (el día del vencimiento)\n'
                '   • Cumpleaños (el día del cumpleaños)\n\n'
                '3. Solo se envía 1 recordatorio por día por socio.\n\n'
                '4. Puedes elegir enviar por Email, Telegram, o ambos.',
              ),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Configuración Requerida',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Para Email: Configura SMTP en "Configuración de Email"\n'
                '• Para Telegram: Configura el bot en "Configuración de Telegram"',
              ),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Envío Manual',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Usa el botón "Enviar Ahora" para probar o enviar recordatorios manualmente.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
