import 'package:gym/core/database/database_helper.dart';
import 'package:gym/features/pos/models/lote_producto.dart';
import 'package:gym/features/pos/models/alerta_inventario.dart';
import 'package:sqflite/sqflite.dart';

class LotesRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ==================== LOTES ====================

  Future<List<LoteProducto>> obtenerTodos() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lotes_productos',
      orderBy: 'fechaVencimiento ASC',
    );
    return List.generate(maps.length, (i) => LoteProducto.fromMap(maps[i]));
  }

  Future<List<LoteProducto>> obtenerPorProducto(int productoId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lotes_productos',
      where: 'productoId = ?',
      whereArgs: [productoId],
      orderBy: 'fechaVencimiento ASC',
    );
    return List.generate(maps.length, (i) => LoteProducto.fromMap(maps[i]));
  }

  Future<LoteProducto?> obtenerPorId(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lotes_productos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return LoteProducto.fromMap(maps.first);
  }

  Future<List<LoteProducto>> obtenerVencidos() async {
    final db = await _dbHelper.database;
    final ahora = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> maps = await db.query(
      'lotes_productos',
      where: 'fechaVencimiento IS NOT NULL AND fechaVencimiento < ? AND stockLote > 0',
      whereArgs: [ahora],
      orderBy: 'fechaVencimiento ASC',
    );
    return List.generate(maps.length, (i) => LoteProducto.fromMap(maps[i]));
  }

  Future<List<LoteProducto>> obtenerProximosAVencer({int dias = 30}) async {
    final db = await _dbHelper.database;
    final ahora = DateTime.now();
    final limite = ahora.add(Duration(days: dias));
    
    final List<Map<String, dynamic>> maps = await db.query(
      'lotes_productos',
      where: 'fechaVencimiento IS NOT NULL AND fechaVencimiento BETWEEN ? AND ? AND stockLote > 0',
      whereArgs: [ahora.toIso8601String(), limite.toIso8601String()],
      orderBy: 'fechaVencimiento ASC',
    );
    return List.generate(maps.length, (i) => LoteProducto.fromMap(maps[i]));
  }

  Future<int> crear(LoteProducto lote) async {
    final db = await _dbHelper.database;
    
    // Generar número de lote automático si no tiene
    var loteConNumero = lote;
    if (lote.numeroLote.isEmpty) {
      final numeroLote = await _generarNumeroLote(db, lote.productoId);
      loteConNumero = lote.copyWith(numeroLote: numeroLote);
    }
    
    final id = await db.insert('lotes_productos', loteConNumero.toMap());
    
    // Actualizar stock del producto
    await _actualizarStockProducto(db, lote.productoId);
    
    // Generar alertas si es necesario
    await _verificarYCrearAlertas(loteConNumero.copyWith(id: id));
    
    return id;
  }

  Future<int> actualizar(LoteProducto lote) async {
    final db = await _dbHelper.database;
    
    final result = await db.update(
      'lotes_productos',
      lote.toMap(),
      where: 'id = ?',
      whereArgs: [lote.id],
    );
    
    // Actualizar stock del producto
    await _actualizarStockProducto(db, lote.productoId);
    
    // Verificar alertas
    await _verificarYCrearAlertas(lote);
    
    return result;
  }

  Future<int> eliminar(int id) async {
    final db = await _dbHelper.database;
    
    // Obtener el lote antes de eliminarlo para actualizar el stock
    final lote = await obtenerPorId(id);
    if (lote == null) return 0;
    
    final result = await db.delete(
      'lotes_productos',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // Actualizar stock del producto
    await _actualizarStockProducto(db, lote.productoId);
    
    return result;
  }

  Future<int> ajustarStockLote(int loteId, int nuevoStock) async {
    final db = await _dbHelper.database;
    
    final lote = await obtenerPorId(loteId);
    if (lote == null) return 0;
    
    final result = await db.update(
      'lotes_productos',
      {'stockLote': nuevoStock},
      where: 'id = ?',
      whereArgs: [loteId],
    );
    
    // Actualizar stock del producto
    await _actualizarStockProducto(db, lote.productoId);
    
    return result;
  }

  // ==================== ALERTAS ====================

  Future<List<AlertaInventario>> obtenerAlertas({bool soloNoLeidas = false}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'alertas_inventario',
      where: soloNoLeidas ? 'leida = ?' : null,
      whereArgs: soloNoLeidas ? [0] : null,
      orderBy: 'fechaCreacion DESC',
    );
    return List.generate(maps.length, (i) => AlertaInventario.fromMap(maps[i]));
  }

  Future<int> contarAlertasNoLeidas() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM alertas_inventario WHERE leida = 0'
    );
    return result.first['count'] as int;
  }

  Future<int> marcarAlertaComoLeida(int alertaId) async {
    final db = await _dbHelper.database;
    return await db.update(
      'alertas_inventario',
      {'leida': 1},
      where: 'id = ?',
      whereArgs: [alertaId],
    );
  }

  Future<int> marcarTodasComoLeidas() async {
    final db = await _dbHelper.database;
    return await db.update(
      'alertas_inventario',
      {'leida': 1},
      where: 'leida = ?',
      whereArgs: [0],
    );
  }

  Future<void> verificarYGenerarAlertas() async {
    // Verificar todos los lotes y generar alertas
    final lotes = await obtenerTodos();
    for (var lote in lotes) {
      await _verificarYCrearAlertas(lote);
    }
  }

  // ==================== HELPERS PRIVADOS ====================

  Future<String> _generarNumeroLote(Database db, int productoId) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM lotes_productos WHERE productoId = ?',
      [productoId]
    );
    final count = result.first['count'] as int;
    final fecha = DateTime.now();
    return 'L${productoId.toString().padLeft(4, '0')}-${fecha.year}${fecha.month.toString().padLeft(2, '0')}-${(count + 1).toString().padLeft(3, '0')}';
  }

  Future<void> _actualizarStockProducto(Database db, int productoId) async {
    // Sumar el stock de todos los lotes del producto
    final result = await db.rawQuery(
      'SELECT SUM(stockLote) as total FROM lotes_productos WHERE productoId = ?',
      [productoId]
    );
    final stockTotal = (result.first['total'] as int?) ?? 0;
    
    // Actualizar el stock del producto
    await db.update(
      'productos',
      {'stock': stockTotal},
      where: 'id = ?',
      whereArgs: [productoId],
    );
  }

  Future<void> _verificarYCrearAlertas(LoteProducto lote) async {
    if (lote.fechaVencimiento == null || lote.stockLote == 0) return;
    
    final db = await _dbHelper.database;
    
    // Eliminar alertas antiguas de este lote
    await db.delete(
      'alertas_inventario',
      where: 'loteId = ?',
      whereArgs: [lote.id],
    );
    
    final ahora = DateTime.now();
    final diasRestantes = lote.fechaVencimiento!.difference(ahora).inDays;
    
    // Producto vencido
    if (diasRestantes < 0) {
      await db.insert('alertas_inventario', {
        'tipo': 'producto_vencido',
        'productoId': lote.productoId,
        'loteId': lote.id,
        'mensaje': 'Lote ${lote.numeroLote} vencido hace ${-diasRestantes} días',
        'prioridad': 'critica',
        'leida': 0,
        'fechaCreacion': DateTime.now().toIso8601String(),
        'fechaVencimiento': lote.fechaVencimiento!.toIso8601String(),
      });
    }
    // Vencimiento crítico (7 días o menos)
    else if (diasRestantes <= 7) {
      await db.insert('alertas_inventario', {
        'tipo': 'vencimiento_critico',
        'productoId': lote.productoId,
        'loteId': lote.id,
        'mensaje': 'Lote ${lote.numeroLote} vence en $diasRestantes días',
        'prioridad': 'alta',
        'leida': 0,
        'fechaCreacion': DateTime.now().toIso8601String(),
        'fechaVencimiento': lote.fechaVencimiento!.toIso8601String(),
      });
    }
    // Vencimiento próximo (30 días o menos)
    else if (diasRestantes <= 30) {
      await db.insert('alertas_inventario', {
        'tipo': 'vencimiento_proximo',
        'productoId': lote.productoId,
        'loteId': lote.id,
        'mensaje': 'Lote ${lote.numeroLote} vence en $diasRestantes días',
        'prioridad': 'media',
        'leida': 0,
        'fechaCreacion': DateTime.now().toIso8601String(),
        'fechaVencimiento': lote.fechaVencimiento!.toIso8601String(),
      });
    }
  }
}
