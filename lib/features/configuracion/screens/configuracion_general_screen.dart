import 'package:flutter/material.dart';
import 'package:gym/services/gym_config_service.dart';
import 'package:gym/features/notificaciones/services/telegram_service.dart';
import 'package:gym/services/email_service.dart';

class ConfiguracionGeneralScreen extends StatefulWidget {
  const ConfiguracionGeneralScreen({super.key});

  @override
  State<ConfiguracionGeneralScreen> createState() => _ConfiguracionGeneralScreenState();
}

class _ConfiguracionGeneralScreenState extends State<ConfiguracionGeneralScreen> {
  final _gymConfigService = GymConfigService();
  
  final _nombreGymController = TextEditingController();
  final _aliasController = TextEditingController();
  final _telegramBotTokenController = TextEditingController();
  final _emailHostController = TextEditingController();
  final _emailPortController = TextEditingController();
  final _emailUserController = TextEditingController();
  final _emailPasswordController = TextEditingController();
  final _emailFromController = TextEditingController();
  
  bool _mercadoPagoEnabled = false;
  bool _telegramEnabled = false;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  @override
  void dispose() {
    _nombreGymController.dispose();
    _aliasController.dispose();
    _telegramBotTokenController.dispose();
    _emailHostController.dispose();
    _emailPortController.dispose();
    _emailUserController.dispose();
    _emailPasswordController.dispose();
    _emailFromController.dispose();
    super.dispose();
  }

  Future<void> _cargarConfiguracion() async {
    final gymConfig = await _gymConfigService.getConfig();
    final telegramConfig = await TelegramService.getConfig();
    final emailConfig = await EmailService().getSmtpConfig();
    
    setState(() {
      _nombreGymController.text = gymConfig['nombreGym'] as String;
      _aliasController.text = gymConfig['aliasTransferencia'] as String;
      _mercadoPagoEnabled = gymConfig['mercadoPagoEnabled'] as bool;
      
      _telegramBotTokenController.text = telegramConfig['botToken'] as String;
      _telegramEnabled = telegramConfig['enabled'] as bool;
      
      if (emailConfig != null) {
        _emailHostController.text = emailConfig['host'] as String;
        _emailPortController.text = (emailConfig['port'] as int).toString();
        _emailUserController.text = emailConfig['username'] as String;
        _emailPasswordController.text = emailConfig['password'] as String;
        _emailFromController.text = emailConfig['fromEmail'] as String;
      }
      
      _cargando = false;
    });
  }

  Future<void> _guardarConfiguracion() async {
    await _gymConfigService.saveConfig(
      nombreGym: _nombreGymController.text.trim(),
      aliasTransferencia: _aliasController.text.trim(),
      mercadoPagoEnabled: _mercadoPagoEnabled,
    );
    
    await TelegramService.saveConfig(
      botToken: _telegramBotTokenController.text.trim(),
      enabled: _telegramEnabled,
    );
    
    // Solo guardar email si hay datos
    if (_emailHostController.text.trim().isNotEmpty) {
      await EmailService().saveSmtpConfig(
        host: _emailHostController.text.trim(),
        port: int.tryParse(_emailPortController.text.trim()) ?? 587,
        username: _emailUserController.text.trim(),
        password: _emailPasswordController.text.trim(),
        fromName: _nombreGymController.text.trim(), // Usar nombre del gym
        fromEmail: _emailFromController.text.trim(),
      );
      
      // Habilitar email si se guardó configuración
      await EmailService().setEmailEnabled(true);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Configuración guardada correctamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración General'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Guardar',
            onPressed: _guardarConfiguracion,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === INFORMACIÓN DEL GIMNASIO ===
                  Text(
                    'Información del Gimnasio',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade300,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: const Color(0xFF2a2a2a),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextField(
                            controller: _nombreGymController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del Gimnasio',
                              labelStyle: TextStyle(color: Colors.white70),
                              hintText: 'Ej: Gimnasio FitPower',
                              hintStyle: TextStyle(color: Colors.white38),
                              prefixIcon: Icon(Icons.fitness_center, color: Colors.deepPurple),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Este nombre aparecerá en el título de la aplicación',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // === TELEGRAM ===
                  Text(
                    'Telegram',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade300,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: const Color(0xFF2a2a2a),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Habilitar Telegram'),
                            subtitle: const Text('Enviar notificaciones por Telegram'),
                            value: _telegramEnabled,
                            onChanged: (value) => setState(() => _telegramEnabled = value),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _telegramBotTokenController,
                            decoration: const InputDecoration(
                              labelText: 'Bot Token',
                              hintText: '123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11',
                              prefixIcon: Icon(Icons.key),
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // === EMAIL ===
                  Text(
                    'Email (SMTP)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade300,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: const Color(0xFF2a2a2a),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextField(
                            controller: _emailHostController,
                            decoration: const InputDecoration(
                              labelText: 'Servidor SMTP',
                              hintText: 'smtp.gmail.com',
                              prefixIcon: Icon(Icons.dns),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailPortController,
                            decoration: const InputDecoration(
                              labelText: 'Puerto',
                              hintText: '587',
                              prefixIcon: Icon(Icons.numbers),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailUserController,
                            decoration: const InputDecoration(
                              labelText: 'Usuario',
                              hintText: 'tu@email.com',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailFromController,
                            decoration: const InputDecoration(
                              labelText: 'Email remitente',
                              hintText: 'gimnasio@email.com',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // === MÉTODOS DE PAGO ===
                  Text(
                    'Métodos de Pago',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade300,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: const Color(0xFF2a2a2a),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.account_balance, color: Colors.green, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'Transferencia Bancaria',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _aliasController,
                            decoration: const InputDecoration(
                              labelText: 'Alias / CVU / CBU',
                              labelStyle: TextStyle(color: Colors.white70),
                              hintText: 'Ej: gym.fitpower',
                              hintStyle: TextStyle(color: Colors.white38),
                              prefixIcon: Icon(Icons.payment, color: Colors.green),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.green, width: 2),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Este alias se incluirá en los recordatorios de pago para que los socios puedan transferir',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // === MERCADO PAGO (Próximamente) ===
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: const Color(0xFF2a2a2a),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.credit_card, color: Colors.blue, size: 28),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Mercado Pago',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.orange),
                                ),
                                child: const Text(
                                  'PRÓXIMAMENTE',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Opacity(
                            opacity: 0.5,
                            child: SwitchListTile(
                              title: const Text(
                                'Habilitar Mercado Pago',
                                style: TextStyle(color: Colors.white70),
                              ),
                              subtitle: const Text(
                                'Acepta pagos con tarjeta, QR y más',
                                style: TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                              value: false,
                              onChanged: null,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Integración con webhooks y pagos automáticos en desarrollo',
                                    style: TextStyle(color: Colors.blue, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // === BOTÓN GUARDAR ===
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _guardarConfiguracion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'Guardar Configuración',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
