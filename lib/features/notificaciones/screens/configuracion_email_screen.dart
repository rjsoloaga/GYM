import 'package:flutter/material.dart';
import 'package:gym/services/email_service.dart';

class ConfiguracionEmailScreen extends StatefulWidget {
  const ConfiguracionEmailScreen({super.key});

  @override
  State<ConfiguracionEmailScreen> createState() => _ConfiguracionEmailScreenState();
}

class _ConfiguracionEmailScreenState extends State<ConfiguracionEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailService = EmailService();
  
  // Controladores
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fromNameController = TextEditingController();
  final _fromEmailController = TextEditingController();
  
  bool _useSsl = true;
  bool _emailEnabled = false;
  bool _loading = true;
  bool _obscurePassword = true;
  bool _testingConnection = false;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    setState(() => _loading = true);
    
    final config = await _emailService.getSmtpConfig();
    final enabled = await _emailService.isEmailEnabled();
    
    if (config != null) {
      _hostController.text = config['host'] ?? '';
      _portController.text = config['port']?.toString() ?? '587';
      _usernameController.text = config['username'] ?? '';
      _passwordController.text = config['password'] ?? '';
      _fromNameController.text = config['fromName'] ?? '';
      _fromEmailController.text = config['fromEmail'] ?? '';
      _useSsl = config['useSsl'] ?? true;
    } else {
      // Valores por defecto para Gmail
      _hostController.text = 'smtp.gmail.com';
      _portController.text = '587';
      _useSsl = true;
    }
    
    setState(() {
      _emailEnabled = enabled;
      _loading = false;
    });
  }

  Future<void> _guardarConfiguracion() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _emailService.saveSmtpConfig(
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        fromName: _fromNameController.text.trim(),
        fromEmail: _fromEmailController.text.trim(),
        useSsl: _useSsl,
      );

      await _emailService.setEmailEnabled(_emailEnabled);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Configuración guardada correctamente'),
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

  Future<void> _probarConexion() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Por favor completa todos los campos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _testingConnection = true);

    // Primero guardar la configuración
    await _emailService.saveSmtpConfig(
      host: _hostController.text.trim(),
      port: int.parse(_portController.text.trim()),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      fromName: _fromNameController.text.trim(),
      fromEmail: _fromEmailController.text.trim(),
      useSsl: _useSsl,
    );

    // Probar conexión
    final success = await _emailService.testConnection();

    setState(() => _testingConnection = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
              ? '✅ Conexión exitosa! Se envió un email de prueba a ${_fromEmailController.text}'
              : '❌ Error de conexión. Verifica tus credenciales.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _fromNameController.dispose();
    _fromEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Configuración de Email'),
          backgroundColor: Colors.blue,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Email'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _mostrarAyuda(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Switch para habilitar/deshabilitar
              Card(
                child: SwitchListTile(
                  title: const Text('Habilitar envío de emails'),
                  subtitle: Text(_emailEnabled 
                    ? 'Los recordatorios se enviarán automáticamente'
                    : 'Los emails están deshabilitados'),
                  value: _emailEnabled,
                  onChanged: (value) => setState(() => _emailEnabled = value),
                  secondary: Icon(
                    _emailEnabled ? Icons.email : Icons.email_outlined,
                    color: _emailEnabled ? Colors.green : Colors.grey,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Configuración SMTP
              Text(
                'Configuración del Servidor SMTP',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              // Host
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: 'Servidor SMTP',
                  hintText: 'smtp.gmail.com',
                  prefixIcon: Icon(Icons.dns),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              
              // Puerto y SSL
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: 'Puerto',
                        hintText: '587',
                        prefixIcon: Icon(Icons.settings_ethernet),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Campo requerido';
                        if (int.tryParse(value!) == null) return 'Número inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: CheckboxListTile(
                      title: const Text('Usar SSL/TLS'),
                      value: _useSsl,
                      onChanged: (value) => setState(() => _useSsl = value ?? true),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Usuario
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Usuario / Email',
                  hintText: 'tu-email@gmail.com',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              
              // Contraseña
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  hintText: 'Contraseña de aplicación',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 8),
              Text(
                '⚠️ Para Gmail, usa una "Contraseña de aplicación", no tu contraseña normal',
                style: TextStyle(color: Colors.orange[700], fontSize: 12),
              ),
              
              const SizedBox(height: 24),
              
              // Información del remitente
              Text(
                'Información del Remitente',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              // Nombre del remitente
              TextFormField(
                controller: _fromNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Gimnasio',
                  hintText: 'Mi Gimnasio',
                  prefixIcon: Icon(Icons.fitness_center),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              
              // Email del remitente
              TextFormField(
                controller: _fromEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email del Gimnasio',
                  hintText: 'gimnasio@ejemplo.com',
                  prefixIcon: Icon(Icons.alternate_email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Campo requerido';
                  if (!value!.contains('@')) return 'Email inválido';
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _testingConnection ? null : _probarConexion,
                      icon: _testingConnection 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering),
                      label: Text(_testingConnection ? 'Probando...' : 'Probar Conexión'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _guardarConfiguracion,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarAyuda() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help, color: Colors.blue),
            SizedBox(width: 8),
            Text('Ayuda - Configuración SMTP'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Gmail',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('• Servidor: smtp.gmail.com'),
              const Text('• Puerto: 587'),
              const Text('• SSL/TLS: Activado'),
              const Text('• Contraseña: Usa una "Contraseña de aplicación"'),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  // TODO: Abrir URL con instrucciones
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Cómo crear contraseña de aplicación'),
              ),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Outlook/Hotmail',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('• Servidor: smtp-mail.outlook.com'),
              const Text('• Puerto: 587'),
              const Text('• SSL/TLS: Activado'),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Otros proveedores',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('Consulta la documentación de tu proveedor de email para obtener la configuración SMTP correcta.'),
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
