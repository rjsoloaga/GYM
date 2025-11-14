import 'package:gym/core/database/database_helper.dart';
import 'package:gym/features/planes/models/plan.dart';
import 'package:gym/features/socios/models/socio.dart';

class PlanService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Obtiene todos los planes activos
  Future<List<Plan>> obtenerPlanesActivos() async {
    return await _dbHelper.getPlanes(soloActivos: true);
  }

  /// Obtiene un plan por su ID
  Future<Plan?> obtenerPlanPorId(int id) async {
    return await _dbHelper.getPlan(id);
  }

  /// Crea un nuevo plan
  Future<int> crearPlan(Plan plan) async {
    return await _dbHelper.insertarPlan(plan);
  }

  /// Actualiza un plan existente
  Future<int> actualizarPlan(Plan plan) async {
    return await _dbHelper.actualizarPlan(plan);
  }

  /// Desactiva un plan (borrado lógico)
  Future<int> desactivarPlan(int planId) async {
    return await _dbHelper.desactivarPlan(planId);
  }

  /// Obtiene los socios asociados a un plan específico
  Future<List<Socio>> obtenerSociosPorPlan(int planId) async {
    return await _dbHelper.getSociosPorPlan(planId);
  }

  /// Calcula la fecha de vencimiento basada en la duración del plan
  /// Si el plan es de tiempo indeterminado, devuelve una fecha muy lejana (100 años)
  DateTime calcularFechaVencimiento(Plan plan, {DateTime? fechaInicio}) {
    final inicio = fechaInicio ?? DateTime.now();
    if (plan.tiempoIndeterminado || plan.duracionDias == null) {
      return inicio.add(const Duration(days: 365 * 100)); // 100 años en el futuro
    }
    return inicio.add(Duration(days: plan.duracionDias!));
  }

  /// Verifica si un plan puede ser eliminado (sin socios asociados)
  Future<bool> puedeEliminarse(int planId) async {
    final socios = await obtenerSociosPorPlan(planId);
    return socios.isEmpty;
  }

  /// Obtiene los planes activos con información de si han cambiado desde una fecha dada
  Future<List<Map<String, dynamic>>> getPlanesConEstadoActualizacion(DateTime? fechaConsulta) async {
    final planes = await _dbHelper.getPlanes(soloActivos: true);
    
    return planes.map((plan) {
      final haCambiado = fechaConsulta != null && 
          plan.fechaActualizacion.isAfter(fechaConsulta);
          
      return {
        'plan': plan,
        'haCambiado': haCambiado,
        'fechaUltimaActualizacion': plan.fechaActualizacion,
      };
    }).toList();
  }
  
  /// Verifica si algún plan ha cambiado desde la última consulta
  Future<bool> hanCambiadoLosPlanes(DateTime ultimaConsulta) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM planes WHERE fechaActualizacion > ? AND activo = 1',
      [ultimaConsulta.toIso8601String()]
    );
    
    final count = result.first['count'] as int;
    return count > 0;
  }

  /// Obtiene estadísticas de uso de los planes
  Future<Map<String, dynamic>> obtenerEstadisticas() async {
    final planes = await _dbHelper.getPlanes(soloActivos: true);
    final estadisticas = <String, dynamic>{
      'total_planes': planes.length,
      'planes': [],
    };

    for (var plan in planes) {
      final socios = await obtenerSociosPorPlan(plan.id!);
      estadisticas['planes'].add({
        'id': plan.id,
        'nombre': plan.nombre,
        'total_socios': socios.length,
        'ingresos_mensuales': plan.precio * socios.length,
        'activo': plan.activo,
      });
    }

    return estadisticas;
  }

  /// Obtiene los planes formateados para mostrar en formularios
  Future<List<Map<String, dynamic>>> obtenerPlanesParaFormulario() async {
    return await _dbHelper.getPlanesParaFormulario();
  }

  /// Actualiza el plan de un socio
  Future<void> actualizarPlanSocio(int socioId, int nuevoPlanId) async {
    final plan = await obtenerPlanPorId(nuevoPlanId);
    if (plan == null) throw Exception('Plan no encontrado');

    final socio = await _dbHelper.getSocio(socioId);
    if (socio == null) throw Exception('Socio no encontrado');

    final ahora = DateTime.now();
    final fechaVencimiento = calcularFechaVencimiento(plan, fechaInicio: ahora);

    final socioActualizado = socio.copyWith(
      planId: plan.id,
      tipoPlan: plan.nombre,
      precioMensual: plan.precio,
      fechaVencimiento: fechaVencimiento,
    );

    await _dbHelper.updateSocio(socioActualizado);

    // Registrar el pago del nuevo plan
    await _dbHelper.insertarPago(
      socioId,
      plan.precio,
      ahora,
      'Cambio de plan',
      usuarioId: 1, // ID del administrador o usuario que realiza el cambio
    );
  }

  /// Verifica si un socio tiene un plan activo
  Future<bool> tienePlanActivo(int socioId) async {
    final socio = await _dbHelper.getSocio(socioId);
    if (socio == null) return false;
    
    final ahora = DateTime.now();
    return socio.fechaVencimiento.isAfter(ahora) || 
           socio.fechaVencimiento.isAtSameMomentAs(DateTime(ahora.year, ahora.month, ahora.day));
  }

  /// Renueva el plan de un socio por el mismo período
  Future<void> renovarPlanSocio(int socioId) async {
    final socio = await _dbHelper.getSocio(socioId);
    if (socio == null) throw Exception('Socio no encontrado');
    
    if (socio.planId == null) {
      throw Exception('El socio no tiene un plan asignado');
    }

    final plan = await obtenerPlanPorId(socio.planId!);
    if (plan == null) throw Exception('Plan no encontrado');

    // Si el plan es de tiempo indeterminado, establecemos una fecha muy lejana
    if (plan.tiempoIndeterminado || plan.duracionDias == null) {
      final nuevaFecha = DateTime.now().add(const Duration(days: 365 * 100)); // 100 años
      final socioActualizado = socio.copyWith(fechaVencimiento: nuevaFecha);
      await _dbHelper.updateSocio(socioActualizado);
      return;
    }
    
    // Para planes con duración definida
    final nuevaFechaVencimiento = socio.fechaVencimiento.isBefore(DateTime.now())
        ? DateTime.now().add(Duration(days: plan.duracionDias!))
        : socio.fechaVencimiento.add(Duration(days: plan.duracionDias!));

    final socioActualizado = socio.copyWith(
      fechaVencimiento: nuevaFechaVencimiento,
    );

    await _dbHelper.updateSocio(socioActualizado);

    // Registrar el pago de renovación
    await _dbHelper.insertarPago(
      socioId,
      plan.precio,
      DateTime.now(),
      'Renovación de plan',
      usuarioId: 1, // ID del administrador o usuario que realiza la renovación
    );
  }
}