import 'package:gym/features/socios/models/socio.dart';

class PagoService {
  // Calcular nueva fecha de vencimiento según el plan
  static DateTime calcularNuevaFechaVencimiento(Socio socio) {
    switch (socio.tipoPlan) {
      case 'Mensual':
        return socio.fechaVencimiento.add(const Duration(days: 30));
      case 'Trimestral':
        return socio.fechaVencimiento.add(const Duration(days: 90));
      case 'Anual':
        return socio.fechaVencimiento.add(const Duration(days: 365));
      default:
        return socio.fechaVencimiento.add(const Duration(days: 30));
    }
  }

  // Simular procesamiento de pago
  static Future<bool> procesarPago(Socio socio) async {
    await Future.delayed(const Duration(seconds: 2));
    return true; // Simular pago exitoso
  }
}