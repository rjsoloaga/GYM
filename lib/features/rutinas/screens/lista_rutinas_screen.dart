import 'package:flutter/material.dart';
import 'package:gym/features/rutinas/models/rutina.dart';
import 'package:gym/features/rutinas/services/rutinas_service.dart';
import 'package:gym/features/rutinas/screens/formulario_rutina_screen.dart';

class ListaRutinasScreen extends StatefulWidget {
  const ListaRutinasScreen({super.key});

  @override
  State<ListaRutinasScreen> createState() => _ListaRutinasScreenState();
}

class _ListaRutinasScreenState extends State<ListaRutinasScreen> {
  final RutinasService _rutinasService = RutinasService();
  List<Rutina> _rutinas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarRutinas();
  }

  Future<void> _cargarRutinas() async {
    setState(() => _cargando = true);
    try {
      final rutinas = await _rutinasService.getRutinas();
      setState(() {
        _rutinas = rutinas;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando rutinas: $e')),
        );
      }
    }
  }

  Future<void> _eliminarRutina(Rutina rutina) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Rutina'),
        content: Text('¿Estás seguro de eliminar "${rutina.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && rutina.id != null) {
      await _rutinasService.eliminarRutina(rutina.id!);
      _cargarRutinas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rutina eliminada')),
        );
      }
    }
  }

  void _navegarAFormulario({Rutina? rutina}) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioRutinaScreen(rutina: rutina),
      ),
    );

    if (resultado == true) {
      _cargarRutinas();
    }
  }

  Color _getColorNivel(String? nivel) {
    switch (nivel?.toLowerCase()) {
      case 'principiante':
        return Colors.green;
      case 'intermedio':
        return Colors.orange;
      case 'avanzado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutinas de Entrenamiento'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _rutinas.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay rutinas creadas',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _rutinas.length,
                  padding: const EdgeInsets.only(bottom: 80, top: 8),
                  itemBuilder: (context, index) {
                    final rutina = _rutinas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColorNivel(rutina.nivel).withOpacity(0.2),
                          child: Icon(
                            Icons.assignment,
                            color: _getColorNivel(rutina.nivel),
                          ),
                        ),
                        title: Text(
                          rutina.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (rutina.nivel != null)
                              Chip(
                                label: Text(
                                  rutina.nivel!,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                backgroundColor: _getColorNivel(rutina.nivel).withOpacity(0.2),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            Text('${rutina.ejercicios.length} ejercicios'),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'editar',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'eliminar',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'editar') {
                              _navegarAFormulario(rutina: rutina);
                            } else if (value == 'eliminar') {
                              _eliminarRutina(rutina);
                            }
                          },
                        ),
                        children: [
                          if (rutina.descripcion != null && rutina.descripcion!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                rutina.descripcion!,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          const Divider(),
                          ...rutina.ejercicios.map((item) {
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.deepPurple.withOpacity(0.2),
                                child: Text(
                                  '${item.orden}',
                                  style: const TextStyle(fontSize: 12, color: Colors.deepPurple),
                                ),
                              ),
                              title: Text(item.ejercicio?.nombre ?? 'Ejercicio desconocido'),
                              subtitle: Text(
                                '${item.series ?? '-'} series × ${item.repeticiones ?? '-'} reps'
                                '${item.descansoSegundos != null ? ' • ${item.descansoSegundos}s descanso' : ''}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarAFormulario(),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }
}
