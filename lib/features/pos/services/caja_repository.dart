import 'package:gym/core/database/database_helper.dart';
import '../models/caja_sesion.dart';

class CajaRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Obtiene la caja abierta del usuario actual (si existe)
  Future<CajaSesion?> obtenerCajaAbierta(int usuarioId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'cajas_sesiones',
      where: 'usuarioId = ? AND estado = ?',
      whereArgs: [usuarioId, 'abierta'],
      orderBy: 'fechaApertura DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return CajaSesion.fromMap(result.first);
    }
    return null;
  }

  /// Abre una nueva caja
  Future<int> abrirCaja(int usuarioId, double montoInicial, {String? notas}) async {
    final caja = CajaSesion(
      usuarioId: usuarioId,
      fechaApertura: DateTime.now(),
      montoInicial: montoInicial,
      estado: 'abierta',
      notas: notas,
    );
    final db = await _dbHelper.database;
    return await db.insert('cajas_sesiones', caja.toMap());
  }

  /// Cierra la caja actual
  Future<void> cerrarCaja({
    required int cajaId,
    required double montoFinalReal,
    required double montoEsperado,
    String? notas,
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      'cajas_sesiones',
      {
        'fechaCierre': DateTime.now().toIso8601String(),
        'montoFinalReal': montoFinalReal,
        'montoFinalEsperado': montoEsperado,
        'diferencia': montoFinalReal - montoEsperado,
        'estado': 'cerrada',
        'notas': notas,
      },
      where: 'id = ?',
      whereArgs: [cajaId],
    );
  }

  /// Obtiene el total de ventas en efectivo de una caja
  Future<double> obtenerVentasEfectivoCaja(int cajaId) async {
    final db = await _dbHelper.database;
    
    // Obtener fecha de apertura de la caja
    final cajaResult = await db.query(
      'cajas_sesiones',
      where: 'id = ?',
      whereArgs: [cajaId],
    );
    
    if (cajaResult.isEmpty) return 0.0;
    
    final caja = CajaSesion.fromMap(cajaResult.first);
    final fechaApertura = caja.fechaApertura.toIso8601String();
    final fechaCierre = caja.fechaCierre?.toIso8601String() ?? DateTime.now().toIso8601String();
    
    // Sumar ventas en efectivo entre esas fechas
    final result = await db.rawQuery('''
      SELECT SUM(total) as total
      FROM ventas
      WHERE metodoPago = 'efectivo'
        AND fechaVenta >= ?
        AND fechaVenta <= ?
    ''', [fechaApertura, fechaCierre]);
    
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Obtiene historial de cajas cerradas
  Future<List<CajaSesion>> obtenerHistorialCajas({int limit = 50}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'cajas_sesiones',
      where: 'estado = ?',
      whereArgs: ['cerrada'],
      orderBy: 'fechaCierre DESC',
      limit: limit,
    );
    return result.map((map) => CajaSesion.fromMap(map)).toList();
  }

  /// Registra un movimiento de caja (ingreso/egreso manual)
  Future<int> registrarMovimiento({
    required int cajaId,
    required int usuarioId,
    required String tipo, // 'ingreso' o 'egreso'
    required double monto,
    required String concepto,
  }) async {
    final db = await _dbHelper.database;
    return await db.insert('movimientos_caja', {
      'cajaId': cajaId,
      'usuarioId': usuarioId,
      'tipo': tipo,
      'monto': monto,
      'concepto': concepto,
      'fechaHora': DateTime.now().toIso8601String(),
    });
  }

  /// Obtiene movimientos de una caja
  Future<List<Map<String, dynamic>>> obtenerMovimientosCaja(int cajaId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'movimientos_caja',
      where: 'cajaId = ?',
      whereArgs: [cajaId],
      orderBy: 'fechaHora DESC',
    );
  }
}
