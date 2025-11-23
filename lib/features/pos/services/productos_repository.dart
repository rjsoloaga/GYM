import 'package:gym/core/database/database_helper.dart';
import 'package:gym/features/pos/models/producto.dart';
import 'package:gym/features/pos/models/categoria_producto.dart';
import 'package:gym/features/pos/models/proveedor.dart';
import 'package:sqflite/sqflite.dart';

class ProductosRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ==================== PRODUCTOS ====================

  Future<List<Producto>> obtenerTodos({bool soloActivos = true}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      where: soloActivos ? 'activo = ?' : null,
      whereArgs: soloActivos ? [1] : null,
      orderBy: 'nombre ASC',
    );
    return List.generate(maps.length, (i) => Producto.fromMap(maps[i]));
  }

  Future<List<Producto>> buscarProductos(String query) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      where: 'activo = 1 AND (nombre LIKE ? OR codigo LIKE ? OR codigoBarras LIKE ?)',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'nombre ASC',
    );
    return List.generate(maps.length, (i) => Producto.fromMap(maps[i]));
  }

  Future<List<Producto>> obtenerPorCategoria(int categoriaId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      where: 'categoriaId = ? AND activo = 1',
      whereArgs: [categoriaId],
      orderBy: 'nombre ASC',
    );
    return List.generate(maps.length, (i) => Producto.fromMap(maps[i]));
  }

  Future<Producto?> obtenerPorId(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Producto.fromMap(maps.first);
  }

  Future<Producto?> obtenerPorCodigo(String codigo) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      where: 'codigo = ? OR codigoBarras = ?',
      whereArgs: [codigo, codigo],
    );
    if (maps.isEmpty) return null;
    return Producto.fromMap(maps.first);
  }

  Future<int> crear(Producto producto, {DateTime? fechaVencimientoInicial, bool isAdmin = false}) async {
    final db = await _dbHelper.database;
    
    return await db.transaction((txn) async {
      // 1. Generar código automático si no tiene
      var productoConCodigo = producto;
      if (producto.codigo == null || producto.codigo!.isEmpty) {
        final codigo = await _generarCodigoProductoTxn(txn);
        productoConCodigo = productoConCodigo.copyWith(codigo: codigo);
      }
      
      // 2. Si el usuario no es admin, forzar precios a 0 (no permitir establecer)
      if (!isAdmin) {
        productoConCodigo = productoConCodigo.copyWith(
          precioCompra: 0,
          precioVenta: 0,
        );
      }

      // 3. Calcular margen si no está definido
      if (productoConCodigo.margenGanancia == null) {
        final margen = productoConCodigo.calcularMargen();
        productoConCodigo = productoConCodigo.copyWith(margenGanancia: margen);
      }
      
      // 4. Insertar producto
      final productoId = await txn.insert('productos', productoConCodigo.toMap());
      
      // 5. Si tiene fecha de vencimiento y stock inicial, crear lote automático
      if (fechaVencimientoInicial != null && productoConCodigo.stock > 0) {
        final lote = {
          'productoId': productoId,
          'numeroLote': 'LOTE-INI-${DateTime.now().millisecondsSinceEpoch}',
          'fechaVencimiento': fechaVencimientoInicial.toIso8601String(),
          'fechaIngreso': DateTime.now().toIso8601String(),
          'stockLote': productoConCodigo.stock,
          'precioCompraLote': productoConCodigo.precioCompra,
          'notas': 'Lote inicial automático',
        };
        await txn.insert('lotes_productos', lote);
      }
      
      return productoId;
    });
  }

  Future<String> _generarCodigoProductoTxn(Transaction txn) async {
    final result = await txn.rawQuery('SELECT COUNT(*) as count FROM productos');
    final count = result.first['count'] as int;
    return 'PROD-${(count + 1).toString().padLeft(6, '0')}';
  }

  Future<int> actualizar(Producto producto, {bool isAdmin = false}) async {
    final db = await _dbHelper.database;
    
    // Si no es admin, preservar precios actuales del registro
    if (!isAdmin) {
      final existente = await obtenerPorId(producto.id!);
      if (existente != null) {
        producto = producto.copyWith(
          precioCompra: existente.precioCompra,
          precioVenta: existente.precioVenta,
        );
      }
    }

    // Recalcular margen con los precios (posiblemente preservados)
    final margen = producto.calcularMargen();
    final productoActualizado = producto.copyWith(
      margenGanancia: margen,
      fechaActualizacion: DateTime.now(),
    );
    
    return await db.update(
      'productos',
      productoActualizado.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  Future<int> eliminar(int id) async {
    final db = await _dbHelper.database;
    // Soft delete
    return await db.update(
      'productos',
      {'activo': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> actualizarStock(int productoId, int nuevoStock) async {
    final db = await _dbHelper.database;
    return await db.update(
      'productos',
      {'stock': nuevoStock},
      where: 'id = ?',
      whereArgs: [productoId],
    );
  }

  Future<List<Producto>> obtenerProductosBajoStock() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM productos 
      WHERE activo = 1 AND stock <= stockMinimo
      ORDER BY stock ASC
    ''');
    return List.generate(maps.length, (i) => Producto.fromMap(maps[i]));
  }

  // ==================== CATEGORÍAS ====================

  Future<List<CategoriaProducto>> obtenerCategorias({bool soloActivas = true}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categorias_productos',
      where: soloActivas ? 'activo = ?' : null,
      whereArgs: soloActivas ? [1] : null,
      orderBy: 'orden ASC, nombre ASC',
    );
    return List.generate(maps.length, (i) => CategoriaProducto.fromMap(maps[i]));
  }

  Future<int> crearCategoria(CategoriaProducto categoria) async {
    final db = await _dbHelper.database;
    return await db.insert('categorias_productos', categoria.toMap());
  }

  Future<int> actualizarCategoria(CategoriaProducto categoria) async {
    final db = await _dbHelper.database;
    return await db.update(
      'categorias_productos',
      categoria.toMap(),
      where: 'id = ?',
      whereArgs: [categoria.id],
    );
  }

  // ==================== PROVEEDORES ====================

  Future<List<Proveedor>> obtenerProveedores({bool soloActivos = true}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'proveedores',
      where: soloActivos ? 'activo = ?' : null,
      whereArgs: soloActivos ? [1] : null,
      orderBy: 'nombre ASC',
    );
    return List.generate(maps.length, (i) => Proveedor.fromMap(maps[i]));
  }

  Future<int> crearProveedor(Proveedor proveedor) async {
    final db = await _dbHelper.database;
    return await db.insert('proveedores', proveedor.toMap());
  }

  Future<int> actualizarProveedor(Proveedor proveedor) async {
    final db = await _dbHelper.database;
    return await db.update(
      'proveedores',
      proveedor.toMap(),
      where: 'id = ?',
      whereArgs: [proveedor.id],
    );
  }

  // ==================== HELPERS ====================

  Future<String> _generarCodigoProducto(Database db) async {
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM productos');
    final count = result.first['count'] as int;
    return 'PROD-${(count + 1).toString().padLeft(6, '0')}';
  }
}
