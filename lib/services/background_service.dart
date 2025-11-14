import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gym/features/notificaciones/services/telegram_service.dart';

class BackgroundService {
  static Timer? _timer;
  static const Duration _pollingInterval = Duration(minutes: 5);

  static Future<void> initialize() async {
    // No es necesario inicializar nada para esta implementación simple
    print('Servicio de fondo inicializado');
  }

  static Future<bool> start() async {
    try {
      // Detener cualquier temporizador existente
      _timer?.cancel();

      // Iniciar el temporizador para verificar actualizaciones
      _timer = Timer.periodic(_pollingInterval, (timer) async {
        if (!kIsWeb) {
          try {
            await TelegramService.getUpdates();
            print('Verificando mensajes de Telegram...');
          } catch (e) {
            print('Error al verificar mensajes: $e');
          }
        }
      });

      // Ejecutar la primera verificación de inmediato
      if (!kIsWeb) {
        await TelegramService.getUpdates();
      }

      print('Servicio de telegram iniciado');
      return true;
    } catch (e) {
      print('Error al iniciar el servicio de telegram: $e');
      return false;
    }
  }

  static Future<bool> stop() async {
    try {
      _timer?.cancel();
      _timer = null;
      print('Servicio de telegram detenido');
      return true;
    } catch (e) {
      print('Error al detener el servicio de telegram: $e');
      return false;
    }
  }
}