import 'package:gym/core/database/database_helper.dart';
import 'package:gym/features/pos/models/movimiento_stock.dart';
import 'package:sqflite/sqflite.dart';

class MovimientosStockRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ==================== REGISTRO DE MOVIMIENTOS ====================

  /// Registra un movimiento de stock
  Future<int> registrarMovimiento(MovimientoStock movimiento) async {
    final db = await _dbHelper.database;
    return await db.insert('stock_movimientos', movimiento.toMap());
  }

  /// Registra un movimiento automáticamente calculando el stock nuevo
  Future<int> registrarMovimientoAuto({
    required int productoId,
    int? loteId,
    required TipoMovimiento tipo,
    required int cantidad,
    String? motivo,
    int? referenciaId,
    String? referenciaTabla,
    int? usuarioId,
  }) async {
    final db = await _dbHelper.database;

    // Obtener stock actual del producto
    final result = await db.query(
      'productos',
      columns: ['stock'],
      where: 'id = ?',
      whereArgs: [productoId],
    );

    if (result.isEmpty) {
      throw Exception('Producto no encontrado');
    }

    final stockAnterior = result.first['stock'] as int;
    final stockNuevo = _calcularStockNuevo(stockAnterior, tipo, cantidad);

    final movimiento = MovimientoStock(
      productoId: productoId,
      loteId: loteId,
      tipo: tipo,
      cantidad: cantidad,
      stockAnterior: stockAnterior,
      stockNuevo: stockNuevo,
      motivo: motivo,
      referenciaId: referenciaId,
      referenciaTabla: referenciaTabla,
      usuarioId: usuarioId,
      fechaMovimiento: DateTime.now(),
    );

    return await registrarMovimiento(movimiento);
  }

  // ==================== CONSULTAS ====================

  Future<List<MovimientoStock>> obtenerTodos({int? limit}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_movimientos',
      orderBy: 'fechaMovimiento DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => MovimientoStock.fromMap(maps[i]));
  }

  Future<List<MovimientoStock>> obtenerPorProducto(int productoId, {int? limit}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_movimientos',
      where: 'productoId = ?',
      whereArgs: [productoId],
      orderBy: 'fechaMovimiento DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => MovimientoStock.fromMap(maps[i]));
  }

  Future<List<MovimientoStock>> obtenerPorLote(int loteId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_movimientos',
      where: 'loteId = ?',
      whereArgs: [loteId],
      orderBy: 'fechaMovimiento DESC',
    );
    return List.generate(maps.length, (i) => MovimientoStock.fromMap(maps[i]));
  }

  Future<List<MovimientoStock>> obtenerPorTipo(TipoMovimiento tipo, {int? limit}) async {
    final db = await _dbHelper.database;
    final tipoStr = _tipoToString(tipo);
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_movimientos',
      where: 'tipo = ?',
      whereArgs: [tipoStr],
      orderBy: 'fechaMovimiento DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => MovimientoStock.fromMap(maps[i]));
  }

  Future<List<MovimientoStock>> obtenerPorFecha({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_movimientos',
      where: 'fechaMovimiento BETWEEN ? AND ?',
      whereArgs: [desde.toIso8601String(), hasta.toIso8601String()],
      orderBy: 'fechaMovimiento DESC',
    );
    return List.generate(maps.length, (i) => MovimientoStock.fromMap(maps[i]));
  }

  // ==================== ESTADÍSTICAS ====================

  Future<Map<String, int>> obtenerEstadisticasPorTipo({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final db = await _dbHelper.database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (desde != null && hasta != null) {
      whereClause = 'WHERE fechaMovimiento BETWEEN ? AND ?';
      whereArgs = [desde.toIso8601String(), hasta.toIso8601String()];
    }
    
    final result = await db.rawQuery('''
      SELECT tipo, COUNT(*) as count
      FROM stock_movimientos
      $whereClause
      GROUP BY tipo
    ''', whereArgs);

    final Map<String, int> stats = {};
    for (var row in result) {
      stats[row['tipo'] as String] = row['count'] as int;
    }
    return stats;
  }

  Future<int> contarMovimientos({
    int? productoId,
    TipoMovimiento? tipo,
  }) async {
    final db = await _dbHelper.database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (productoId != null && tipo != null) {
      whereClause = 'WHERE productoId = ? AND tipo = ?';
      whereArgs = [productoId, _tipoToString(tipo)];
    } else if (productoId != null) {
      whereClause = 'WHERE productoId = ?';
      whereArgs = [productoId];
    } else if (tipo != null) {
      whereClause = 'WHERE tipo = ?';
      whereArgs = [_tipoToString(tipo)];
    }
    
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM stock_movimientos
      $whereClause
    ''', whereArgs);

    return result.first['count'] as int;
  }

  // ==================== HELPERS PRIVADOS ====================

  int _calcularStockNuevo(int stockAnterior, TipoMovimiento tipo, int cantidad) {
    switch (tipo) {
      case TipoMovimiento.entrada:
      case TipoMovimiento.compra:
      case TipoMovimiento.devolucion:
        return stockAnterior + cantidad;
      
      case TipoMovimiento.salida:
      case TipoMovimiento.venta:
      case TipoMovimiento.merma:
        return stockAnterior - cantidad;
      
      case TipoMovimiento.ajuste:
      case TipoMovimiento.transferencia:
        // Para ajustes, la cantidad puede ser positiva o negativa
        return cantidad;
    }
  }

  String _tipoToString(TipoMovimiento tipo) {
    switch (tipo) {
      case TipoMovimiento.entrada:
        return 'entrada';
      case TipoMovimiento.salida:
        return 'salida';
      case TipoMovimiento.ajuste:
        return 'ajuste';
      case TipoMovimiento.venta:
        return 'venta';
      case TipoMovimiento.compra:
        return 'compra';
      case TipoMovimiento.devolucion:
        return 'devolucion';
      case TipoMovimiento.merma:
        return 'merma';
      case TipoMovimiento.transferencia:
        return 'transferencia';
    }
  }
}
