import 'package:flutter_test/flutter_test.dart';
import 'package:gym/features/pos/models/producto.dart';
import 'package:gym/features/pos/services/productos_repository.dart';

void main() {
  group('ProductosRepository permission validation', () {
    final repository = ProductosRepository();

    test('Non-admin cannot set price fields on create', () async {
      final producto = Producto(
        nombre: 'Test Product',
        precioCompra: 100.0,
        precioVenta: 150.0,
        stock: 10,
        stockMinimo: 5,
        activo: true,
        categoriaId: 1,
        fechaCreacion: DateTime.now(),
      );


      // crear con isAdmin = false should force prices to 0
      final id = await repository.crear(producto, isAdmin: false);
      final creado = await repository.obtenerPorId(id);

      expect(creado?.precioCompra, equals(0));
      expect(creado?.precioVenta, equals(0));
    });

    test('Admin can set price fields on create', () async {
      final producto = Producto(
        nombre: 'Admin Product',
        precioCompra: 200.0,
        precioVenta: 250.0,
        stock: 5,
        stockMinimo: 2,
        activo: true,
        categoriaId: 1,
      );

      final id = await repository.crear(producto, isAdmin: true);
      final creado = await repository.obtenerPorId(id);

      expect(creado?.precioCompra, equals(200.0));
      expect(creado?.precioVenta, equals(250.0));
    });
  });
}
