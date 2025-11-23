import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';

class GymConfigService {
  static final GymConfigService _instance = GymConfigService._internal();
  factory GymConfigService() => _instance;
  GymConfigService._internal();

  static const String _keyNombreGym = 'gym_nombre';
  static const String _keyAliasTransferencia = 'gym_alias_transferencia';
  static const String _keyMercadoPagoEnabled = 'gym_mercadopago_enabled';
  static const String _keyMercadoPagoAccessToken = 'gym_mercadopago_token';

  static const String _keyThemeMode = 'gym_theme_mode'; // 'dark' o 'light'

  // Valores por defecto
  static const String _defaultNombreGym = 'GYM MANAGEMENT';
  static const String _defaultAlias = '';

  // Notifier para cambios en el nombre y tema
  final ValueNotifier<String> nombreGymNotifier = ValueNotifier<String>(_defaultNombreGym);
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

  // Cargar configuración inicial
  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString(_keyNombreGym) ?? _defaultNombreGym;
    nombreGymNotifier.value = nombre;
    
    final themeString = prefs.getString(_keyThemeMode) ?? 'dark';
    themeModeNotifier.value = themeString == 'light' ? ThemeMode.light : ThemeMode.dark;
  }
  
  // Alternar y guardar tema
  Future<void> toggleTheme() async {
    final newMode = themeModeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    themeModeNotifier.value = newMode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, newMode == ThemeMode.dark ? 'dark' : 'light');
  }

  // Guardar configuración general
  Future<void> saveConfig({
    String? nombreGym,
    String? aliasTransferencia,
    bool? mercadoPagoEnabled,
    String? mercadoPagoAccessToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (nombreGym != null) {
      // Si el nombre está vacío, usar el valor por defecto
      final nombreFinal = nombreGym.trim().isEmpty ? _defaultNombreGym : nombreGym.trim();
      
      await prefs.setString(_keyNombreGym, nombreFinal);
      nombreGymNotifier.value = nombreFinal; // Notificar cambio
      
      // Actualizar título de ventana en desktop
      if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
        try {
          await windowManager.setTitle(nombreFinal);
        } catch (e) {
          debugPrint('Error actualizando título de ventana: $e');
        }
      }
    }
    if (aliasTransferencia != null) {
      await prefs.setString(_keyAliasTransferencia, aliasTransferencia);
    }
    if (mercadoPagoEnabled != null) {
      await prefs.setBool(_keyMercadoPagoEnabled, mercadoPagoEnabled);
    }
    if (mercadoPagoAccessToken != null) {
      await prefs.setString(_keyMercadoPagoAccessToken, mercadoPagoAccessToken);
    }
  }

  // Obtener configuración completa
  Future<Map<String, dynamic>> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'nombreGym': prefs.getString(_keyNombreGym) ?? _defaultNombreGym,
      'aliasTransferencia': prefs.getString(_keyAliasTransferencia) ?? _defaultAlias,
      'mercadoPagoEnabled': prefs.getBool(_keyMercadoPagoEnabled) ?? false,
      'mercadoPagoAccessToken': prefs.getString(_keyMercadoPagoAccessToken) ?? '',
    };
  }

  // Obtener solo el nombre del gym
  Future<String> getNombreGym() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyNombreGym) ?? _defaultNombreGym;
  }

  // Obtener solo el alias
  Future<String> getAliasTransferencia() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAliasTransferencia) ?? _defaultAlias;
  }

  // Verificar si Mercado Pago está habilitado
  Future<bool> isMercadoPagoEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMercadoPagoEnabled) ?? false;
  }
}
