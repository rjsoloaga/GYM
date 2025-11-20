import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym/core/database/database_helper.dart';
import 'package:gym/features/socios/models/socio.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class RegistroAsistenciaScreen extends StatefulWidget {
  const RegistroAsistenciaScreen({super.key});

  @override
  State<RegistroAsistenciaScreen> createState() => _RegistroAsistenciaScreenState();
}

class _RegistroAsistenciaScreenState extends State<RegistroAsistenciaScreen> {
  final _dniController = TextEditingController();
  final _focusNode = FocusNode();
  
  Socio? _ultimoSocio;
  String? _ultimoEstado;
  DateTime? _ultimaHora;
  bool _procesando = false;
  bool _sonidosHabilitados = true;
  Timer? _clearTimer;

  @override
  void initState() {
    super.initState();
    _cargarPreferenciaSonidos();
    // Auto-focus en el campo de DNI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _dniController.dispose();
    _focusNode.dispose();
    _clearTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarPreferenciaSonidos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sonidosHabilitados = prefs.getBool('asistencia_sonidos_habilitados') ?? true;
    });
  }

  Future<void> _toggleSonidos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sonidosHabilitados = !_sonidosHabilitados;
    });
    await prefs.setBool('asistencia_sonidos_habilitados', _sonidosHabilitados);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_sonidosHabilitados ? 'Sonidos activados' : 'Sonidos desactivados'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _limpiarFeedback() {
    setState(() {
      _ultimoSocio = null;
      _ultimoEstado = null;
      _ultimaHora = null;
    });
  }

  void _iniciarTimerAutoClear() {
    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _limpiarFeedback();
      }
    });
  }

  Future<void> _registrarAsistencia() async {
    if (_procesando) return;
    
    final dni = _dniController.text.trim();
    if (dni.isEmpty) return;

    setState(() => _procesando = true);

    try {
      // Buscar socio por DNI
      final socio = await DatabaseHelper.instance.getSocioPorDni(dni);
      
      if (socio == null) {
        // Socio no encontrado
        _mostrarError('DNI no encontrado');
        if (_sonidosHabilitados) {
          _reproducirSonidoError();
        }
      } else {
        // Socio encontrado - registrar asistencia
        final estado = socio.estadoCuota;
        await DatabaseHelper.instance.registrarAsistencia(socio.id!, estado);
        
        setState(() {
          _ultimoSocio = socio;
          _ultimoEstado = estado;
          _ultimaHora = DateTime.now();
        });

        // Reproducir sonido según estado
        if (_sonidosHabilitados) {
          _reproducirSonidoSegunEstado(estado);
        }

        // Iniciar timer para limpiar feedback
        _iniciarTimerAutoClear();
      }
    } catch (e) {
      _mostrarError('Error: $e');
      if (_sonidosHabilitados) {
        _reproducirSonidoError();
      }
    } finally {
      setState(() => _procesando = false);
      _dniController.clear();
      _focusNode.requestFocus();
    }
  }

  void _reproducirSonidoSegunEstado(String estado) async {
    try {
      // Crear un beep simple usando audioplayers
      final player = AudioPlayer();
      
      if (estado == 'Vencido') {
        // Sonido de error (3 beeps rápidos)
        for (int i = 0; i < 3; i++) {
          await Future.delayed(Duration(milliseconds: i * 150));
          await player.play(AssetSource('sounds/beep_error.mp3')).catchError((_) {
            // Si no hay archivo, usar vibración o nada
            debugPrint('No se pudo reproducir sonido de error');
          });
        }
      } else if (estado == 'Por Vencer') {
        // Sonido de advertencia (2 beeps)
        for (int i = 0; i < 2; i++) {
          await Future.delayed(Duration(milliseconds: i * 200));
          await player.play(AssetSource('sounds/beep_warning.mp3')).catchError((_) {
            debugPrint('No se pudo reproducir sonido de advertencia');
          });
        }
      } else {
        // Sonido de éxito (1 beep)
        await player.play(AssetSource('sounds/beep_success.mp3')).catchError((_) {
          debugPrint('No se pudo reproducir sonido de éxito');
        });
      }
      
      await player.dispose();
    } catch (e) {
      debugPrint('Error reproduciendo sonido: $e');
    }
  }

  void _reproducirSonidoError() async {
    try {
      final player = AudioPlayer();
      // Sonido de error fuerte (4 beeps muy rápidos)
      for (int i = 0; i < 4; i++) {
        await Future.delayed(Duration(milliseconds: i * 100));
        await player.play(AssetSource('sounds/beep_error.mp3')).catchError((_) {
          debugPrint('No se pudo reproducir sonido de error');
        });
      }
      await player.dispose();
    } catch (e) {
      debugPrint('Error reproduciendo sonido de error: $e');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'Vencido':
        return Colors.red;
      case 'Por Vencer':
        return Colors.orange;
      case 'Al Día':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconoEstado(String estado) {
    switch (estado) {
      case 'Vencido':
        return Icons.error;
      case 'Por Vencer':
        return Icons.warning;
      case 'Al Día':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Asistencia'),
        backgroundColor: Colors.blue,
        actions: [
          // Toggle de sonidos
          IconButton(
            icon: Icon(_sonidosHabilitados ? Icons.volume_up : Icons.volume_off),
            onPressed: _toggleSonidos,
            tooltip: _sonidosHabilitados ? 'Desactivar sonidos' : 'Activar sonidos',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Campo de entrada DNI
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _dniController,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: 'Ingrese DNI',
                    hintText: '12345678',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge, size: 32),
                  ),
                  onSubmitted: (_) => _registrarAsistencia(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Botón de registro
            ElevatedButton.icon(
              onPressed: _procesando ? null : _registrarAsistencia,
              icon: _procesando 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.login, size: 32),
              label: Text(
                _procesando ? 'Procesando...' : 'Registrar Ingreso',
                style: const TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            
            // Feedback visual del último registro
            if (_ultimoSocio != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ÚLTIMO REGISTRO',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  TextButton.icon(
                    onPressed: _limpiarFeedback,
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Limpiar'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _getColorEstado(_ultimoEstado!).withOpacity(0.1),
                  border: Border.all(color: _getColorEstado(_ultimoEstado!), width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getIconoEstado(_ultimoEstado!),
                      size: 80,
                      color: _getColorEstado(_ultimoEstado!),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _ultimoSocio!.nombreCompleto,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'DNI: ${_ultimoSocio!.dni}',
                      style: const TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: _getColorEstado(_ultimoEstado!),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        _ultimoEstado!.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Vence: ${DateFormat('dd/MM/yyyy').format(_ultimoSocio!.fechaVencimiento)}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hora: ${DateFormat('HH:mm:ss').format(_ultimaHora!)}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 100),
              Icon(Icons.qr_code_scanner, size: 120, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Esperando registro...',
                style: TextStyle(fontSize: 20, color: Colors.grey[400]),
              ),
              const SizedBox(height: 8),
              Text(
                'El feedback se limpiará automáticamente en 5 segundos',
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
