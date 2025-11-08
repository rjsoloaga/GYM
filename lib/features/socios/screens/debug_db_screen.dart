import 'package:flutter/material.dart';
import 'package:gym/core/database/database_helper.dart';

class DebugDBScreen extends StatefulWidget {
  const DebugDBScreen({super.key});

  @override
  State<DebugDBScreen> createState() => _DebugDBScreenState();
}

class _DebugDBScreenState extends State<DebugDBScreen> {
  List<Map<String, dynamic>> _rows = [];
  String _status = '';

  Future<void> _listarEnPantalla() async {
    try {
      final rows = await DatabaseHelper.instance.getAllRawSocios();
      setState(() {
        _rows = rows;
        _status = 'Encontradas ${rows.length} filas';
      });
    } catch (e) {
      setState(() => _status = 'Error al listar: $e');
    }
  }

  Future<void> _imprimirEnConsola() async {
    try {
      await DatabaseHelper.instance.debugPrintAllSocios();
      setState(() => _status = 'Imprimido en consola (debugPrint)');
    } catch (e) {
      setState(() => _status = 'Error al imprimir: $e');
    }
  }

  Future<void> _borrarDB() async {
    try {
      await DatabaseHelper.instance.dropDatabase();
      setState(() {
        _rows = [];
        _status = 'BD borrada';
      });
    } catch (e) {
      setState(() => _status = 'Error al borrar DB: $e');
    }
  }

  Future<void> _borrarYRecrear() async {
    try {
      await DatabaseHelper.instance.dropDatabase();
      await DatabaseHelper.instance.database; // forza onCreate
      final rows = await DatabaseHelper.instance.getAllRawSocios();
      setState(() {
        _rows = rows;
        _status = 'BD recreada, filas: ${rows.length}';
      });
    } catch (e) {
      setState(() => _status = 'Error al recrear DB: $e');
    }
  }

  Future<void> _recrearSinBorrar() async {
    try {
      await DatabaseHelper.instance.database;
      final rows = await DatabaseHelper.instance.getAllRawSocios();
      setState(() {
        _rows = rows;
        _status = 'BD abierta, filas: ${rows.length}';
      });
    } catch (e) {
      setState(() => _status = 'Error al abrir DB: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DEBUG DB (temporal)')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(onPressed: _imprimirEnConsola, child: const Text('Imprimir en consola')),
                ElevatedButton(onPressed: _listarEnPantalla, child: const Text('Listar en pantalla')),
                ElevatedButton(onPressed: _recrearSinBorrar, child: const Text('Abrir / Re-crear si falta')),
                ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), onPressed: _borrarDB, child: const Text('Borrar DB')),
                ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: _borrarYRecrear, child: const Text('Borrar y Recrear')),
              ],
            ),
            const SizedBox(height: 12),
            Text('Estado: $_status'),
            const SizedBox(height: 12),
            Expanded(
              child: _rows.isEmpty
                  ? const Center(child: Text('No hay filas listadas'))
                  : ListView.builder(
                      itemCount: _rows.length,
                      itemBuilder: (context, i) {
                        final r = _rows[i];
                        return Card(
                          child: ListTile(
                            title: Text(r['nombreCompleto']?.toString() ?? '—'),
                            subtitle: Text('dni: ${r['dni'] ?? ''}  tel: ${r['telefono'] ?? ''}  activo: ${r['activo'] ?? ''}'),
                            dense: true,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}