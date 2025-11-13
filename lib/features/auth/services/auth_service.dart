import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const _storage = FlutterSecureStorage();

  // Verificar si el dispositivo soporta autenticación biométrica
  static Future<bool> isBiometricAvailable() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  // Autenticar con huella digital
  static Future<bool> authenticateWithBiometrics() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Autentícate para acceder',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  // Guardar credenciales de forma segura
  static Future<void> saveCredentials(String userId, String token) async {
    await _storage.write(key: 'user_id', value: userId);
    await _storage.write(key: 'auth_token', value: token);
  }

  // Obtener credenciales guardadas
  static Future<Map<String, String?>> getStoredCredentials() async {
    final userId = await _storage.read(key: 'user_id');
    final token = await _storage.read(key: 'auth_token');
    return {'userId': userId, 'token': token};
  }

  // Eliminar credenciales
  static Future<void> deleteCredentials() async {
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'auth_token');
  }
}
