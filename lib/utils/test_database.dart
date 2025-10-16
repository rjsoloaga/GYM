// lib/test_database.dart
import 'package:gym/repositories/database_helper.dart';
import 'package:gym/models/socio.dart';

class TestDatabase {
  static Future<void> test() async {
    print('🧪 Probando base de datos...');
    
    // Test 1: Insertar socio
    final nuevoSocio = Socio(
      nombreCompleto: "Maria Garcia",
      dni: dniUnico,
      telefono: "987654321",
      fechaInicio: DateTime.now(),
      fechaVencimiento: DateTime.now().add(const Duration(days: 30)),
      precioMensual: 5000.0,
      tipoPlan: "Mensual",
    );

    try {
      int id = await DatabaseHelper.instance.insertarSocio(nuevoSocio);
      print('✅ Socio insertado con ID: $id');

      // Test 2: Obtener socios
      List<Socio> socios = await DatabaseHelper.instance.getSocios();
      print('📊 Socios en BD: ${socios.length}');
      
      for (var socio in socios) {
        print('👤 ${socio.nombreCompleto} - DNI: ${socio.dni}');
      }
      
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}