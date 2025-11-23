import 'package:gym/core/database/database_helper.dart';
import 'package:gym/features/pos/models/venta.dart';
import 'package:gym/features/pos/models/detalle_venta.dart';
import 'package:gym/features/pos/models/movimiento_stock.dart';
import 'package:gym/features/pos/services/movimientos_stock_repository.dart';
import 'package:sqflite/sqflite.dart';

class VentasRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final MovimientosStockRepository _movimientosRepository = MovimientosStockRepository();

  // ==================== VENTAS ====================

  Future<List<Venta>> obtenerTodas({int? limit}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ventas',
      orderBy: 'fechaVenta DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => Venta.fromMap(maps[i]));
  }

  Future<Venta?> obtenerPorId(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ventas',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Venta.fromMap(maps.first);
  }

  Future<List<Venta>> obtenerPorFecha({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ventas',
      where: 'fechaVenta BETWEEN ? AND ?',
      whereArgs: [desde.toIso8601String(), hasta.toIso8601String()],
      orderBy: 'fechaVenta DESC',
    );
    return List.generate(maps.length, (i) => Venta.fromMap(maps[i]));
  }

  Future<List<Venta>> obtenerPorSocio(int socioId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ventas',
      where: 'socioId = ?',
      whereArgs: [socioId],
      orderBy: 'fechaVenta DESC',
    );
    return List.generate(maps.length, (i) => Venta.fromMap(maps[i]));
  }

  /// Crea una venta completa con sus detalles y actualiza el stock
  Future<int> crearVenta({
    required Venta venta,
    required List<DetalleVenta> detalles,
  }) async {
    final db = await _dbHelper.database;
    
    return await db.transaction((txn) async {
      // 1. Generar número de venta si no tiene
      var ventaConNumero = venta;
      if (venta.numeroVenta.isEmpty) {
        final numeroVenta = await _generarNumeroVenta(txn);
        ventaConNumero = venta.copyWith(numeroVenta: numeroVenta);
      }
      
      // 2. Insertar la venta
      final ventaId = await txn.insert('ventas', ventaConNumero.toMap());
      
      // 3. Insertar los detalles y actualizar stock
      for (var detalle in detalles) {
        final detalleConVentaId = detalle.copyWith(ventaId: ventaId);
        await txn.insert('detalles_venta', detalleConVentaId.toMap());
        
        // 4. Actualizar stock del producto (restar)
        await txn.rawUpdate('''
          UPDATE productos 
          SET stock = stock - ? 
          WHERE id = ?
        ''', [detalle.cantidad, detalle.productoId]);
        
        // 5. Registrar movimiento de stock
        final movimiento = MovimientoStock(
          productoId: detalle.productoId,
          loteId: detalle.loteId,
          tipo: TipoMovimiento.venta,
          cantidad: detalle.cantidad,
          stockAnterior: 0, // Se calculará después
          stockNuevo: 0, // Se calculará después
          motivo: 'Venta ${ventaConNumero.numeroVenta}',
          referenciaId: ventaId,
          referenciaTabla: 'ventas',
          fechaMovimiento: venta.fechaVenta,
        );
        
        // Obtener stock actual para el movimiento
        final stockResult = await txn.query(
          'productos',
          columns: ['stock'],
          where: 'id = ?',
          whereArgs: [detalle.productoId],
        );
        if (stockResult.isNotEmpty) {
          final stockNuevo = stockResult.first['stock'] as int;
          final stockAnterior = stockNuevo + detalle.cantidad;
          final movimientoCompleto = movimiento.copyWith(
            stockAnterior: stockAnterior,
            stockNuevo: stockNuevo,
          );
          await txn.insert('stock_movimientos', movimientoCompleto.toMap());
        }
      }
      
      return ventaId;
    });
  }

  Future<int> cancelarVenta(int ventaId) async {
    final db = await _dbHelper.database;
    
    return await db.transaction((txn) async {
      // 1. Obtener detalles de la venta
      final detalles = await obtenerDetalles(ventaId);
      
      // 2. Devolver stock
      for (var detalle in detalles) {
        await txn.rawUpdate('''
          UPDATE productos 
          SET stock = stock + ? 
          WHERE id = ?
        ''', [detalle.cantidad, detalle.productoId]);
        
        // 3. Registrar movimiento de devolución
        final movimiento = MovimientoStock(
          productoId: detalle.productoId,
          loteId: detalle.loteId,
          tipo: TipoMovimiento.devolucion,
          cantidad: detalle.cantidad,
          stockAnterior: 0,
          stockNuevo: 0,
          motivo: 'Cancelación de venta',
          referenciaId: ventaId,
          referenciaTabla: 'ventas',
          fechaMovimiento: DateTime.now(),
        );
        
        final stockResult = await txn.query(
          'productos',
          columns: ['stock'],
          where: 'id = ?',
          whereArgs: [detalle.productoId],
        );
        if (stockResult.isNotEmpty) {
          final stockNuevo = stockResult.first['stock'] as int;
          final stockAnterior = stockNuevo - detalle.cantidad;
          final movimientoCompleto = movimiento.copyWith(
            stockAnterior: stockAnterior,
            stockNuevo: stockNuevo,
          );
          await txn.insert('stock_movimientos', movimientoCompleto.toMap());
        }
      }
      
      // 4. Actualizar estado de la venta
      return await txn.update(
        'ventas',
        {'estado': 'cancelada'},
        where: 'id = ?',
        whereArgs: [ventaId],
      );
    });
  }

  // ==================== DETALLES DE VENTA ====================

  Future<List<DetalleVenta>> obtenerDetalles(int ventaId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'detalles_venta',
      where: 'ventaId = ?',
      whereArgs: [ventaId],
    );
    return List.generate(maps.length, (i) => DetalleVenta.fromMap(maps[i]));
  }

  // ==================== ESTADÍSTICAS ====================

  Future<double> obtenerTotalVentasHoy() async {
    final db = await _dbHelper.database;
    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDia = inicioDia.add(const Duration(days: 1));
    
    final result = await db.rawQuery('''
      SELECT SUM(total) as total
      FROM ventas
      WHERE estado = 'completada'
        AND fechaVenta BETWEEN ? AND ?
    ''', [inicioDia.toIso8601String(), finDia.toIso8601String()]);
    
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> obtenerCantidadVentasHoy() async {
    final db = await _dbHelper.database;
    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDia = inicioDia.add(const Duration(days: 1));
    
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM ventas
      WHERE estado = 'completada'
        AND fechaVenta BETWEEN ? AND ?
    ''', [inicioDia.toIso8601String(), finDia.toIso8601String()]);
    
    return result.first['count'] as int;
  }

  Future<Map<String, double>> obtenerVentasPorMetodoPago({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final db = await _dbHelper.database;
    
    String whereClause = "estado = 'completada'";
    List<dynamic> whereArgs = [];
    
    if (desde != null && hasta != null) {
      whereClause += ' AND fechaVenta BETWEEN ? AND ?';
      whereArgs = [desde.toIso8601String(), hasta.toIso8601String()];
    }
    
    final result = await db.rawQuery('''
      SELECT metodoPago, SUM(total) as total
      FROM ventas
      WHERE $whereClause
      GROUP BY metodoPago
    ''', whereArgs);
    
    final Map<String, double> stats = {};
    for (var row in result) {
      stats[row['metodoPago'] as String] = (row['total'] as num).toDouble();
    }
    return stats;
  }

  Future<List<Map<String, dynamic>>> obtenerVentasUltimos7Dias() async {
    final db = await _dbHelper.database;
    final hoy = DateTime.now();
    final hace7dias = hoy.subtract(const Duration(days: 6)); // Hoy + 6 días atrás
    
    final result = await db.rawQuery('''
      SELECT 
        substr(fechaVenta, 1, 10) as fecha,
        SUM(total) as total
      FROM ventas
      WHERE estado = 'completada'
        AND fechaVenta >= ?
      GROUP BY substr(fechaVenta, 1, 10)
      ORDER BY fecha ASC
    ''', [hace7dias.toIso8601String().substring(0, 10)]);
    
    return result;
  }

  Future<List<Map<String, dynamic>>> obtenerProductosMasVendidos({int limit = 5}) async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT 
        p.nombre,
        SUM(d.cantidad) as cantidad,
        SUM(d.subtotal) as total
      FROM detalles_venta d
      JOIN ventas v ON v.id = d.ventaId
      JOIN productos p ON p.id = d.productoId
      WHERE v.estado = 'completada'
      GROUP BY d.productoId
      ORDER BY cantidad DESC
      LIMIT ?
    ''', [limit]);
    
    return result;
  }

  // ==================== HELPERS PRIVADOS ====================

  Future<String> _generarNumeroVenta(DatabaseExecutor db) async {
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM ventas');
    final count = result.first['count'] as int;
    final fecha = DateTime.now();
    return 'V${fecha.year}${fecha.month.toString().padLeft(2, '0')}-${(count + 1).toString().padLeft(6, '0')}';
  }
}
