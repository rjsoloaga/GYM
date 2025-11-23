import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Servicio para gestionar la licencia y período de prueba de la aplicación
class LicenseService {
  static final LicenseService _instance = LicenseService._internal();
  factory LicenseService() => _instance;
  LicenseService._internal();

  static const String _keyFirstInstallDate = 'app_first_install_date';
  static const String _keyLicenseKey = 'app_license_key';
  static const String _keyLicenseType = 'app_license_type'; // 'trial', 'basic', 'premium'
  
  static const int trialDays = 60;
  
  /// Inicializar el servicio (llamar al inicio de la app)
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Si es la primera vez, guardar la fecha de instalación
    if (!prefs.containsKey(_keyFirstInstallDate)) {
      await prefs.setString(_keyFirstInstallDate, DateTime.now().toIso8601String());
      await prefs.setString(_keyLicenseType, 'trial');
      debugPrint('🔑 Primera instalación registrada. Período de prueba iniciado.');
    }
  }
  
  /// Verificar si la licencia es válida
  Future<LicenseStatus> checkLicense() async {
    final prefs = await SharedPreferences.getInstance();
    
    final licenseType = prefs.getString(_keyLicenseType) ?? 'trial';
    
    // Si tiene licencia premium o básica válida
    if (licenseType == 'premium' || licenseType == 'basic') {
      final licenseKey = prefs.getString(_keyLicenseKey);
      if (licenseKey != null && licenseKey.isNotEmpty) {
        return LicenseStatus(
          isValid: true,
          type: licenseType,
          daysRemaining: -1, // Ilimitado
          message: 'Licencia $licenseType activa',
        );
      }
    }
    
    // Verificar período de prueba
    final firstInstallStr = prefs.getString(_keyFirstInstallDate);
    if (firstInstallStr == null) {
      // No debería pasar, pero por seguridad
      await initialize();
      return checkLicense();
    }
    
    final firstInstall = DateTime.parse(firstInstallStr);
    final now = DateTime.now();
    final daysPassed = now.difference(firstInstall).inDays;
    final daysRemaining = trialDays - daysPassed;
    
    if (daysRemaining > 0) {
      return LicenseStatus(
        isValid: true,
        type: 'trial',
        daysRemaining: daysRemaining,
        message: 'Período de prueba: $daysRemaining días restantes',
      );
    } else {
      return LicenseStatus(
        isValid: false,
        type: 'expired',
        daysRemaining: 0,
        message: 'El período de prueba ha expirado. Por favor, adquiere una licencia.',
      );
    }
  }
  
  /// Activar licencia con una clave
  Future<bool> activateLicense(String licenseKey, String type) async {
    // Aquí podrías validar la clave contra un servidor
    // Por ahora, validación simple de formato
    if (licenseKey.length < 16) {
      return false;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLicenseKey, licenseKey);
    await prefs.setString(_keyLicenseType, type);
    
    debugPrint('✅ Licencia $type activada correctamente');
    return true;
  }
  
  /// Resetear licencia (solo para desarrollo/testing)
  Future<void> resetLicense() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFirstInstallDate);
    await prefs.remove(_keyLicenseKey);
    await prefs.remove(_keyLicenseType);
    debugPrint('🔄 Licencia reseteada');
  }
}

class LicenseStatus {
  final bool isValid;
  final String type; // 'trial', 'basic', 'premium', 'expired'
  final int daysRemaining; // -1 si es ilimitado
  final String message;
  
  LicenseStatus({
    required this.isValid,
    required this.type,
    required this.daysRemaining,
    required this.message,
  });
  
  bool get isTrial => type == 'trial';
  bool get isBasic => type == 'basic';
  bool get isPremium => type == 'premium';
  bool get isExpired => type == 'expired';
}
