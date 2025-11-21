import 'package:flutter/material.dart';
import 'package:gym/features/rutinas/models/ejercicio.dart';
import 'package:gym/features/rutinas/services/rutinas_service.dart';
import 'package:gym/features/rutinas/screens/formulario_ejercicio_screen.dart';

class ListaEjerciciosScreen extends StatefulWidget {
  const ListaEjerciciosScreen({super.key});

  @override
  State<ListaEjerciciosScreen> createState() => _ListaEjerciciosScreenState();
}

class _ListaEjerciciosScreenState extends State<ListaEjerciciosScreen> {
  final RutinasService _rutinasService = RutinasService();
  List<Ejercicio> _ejercicios = [];
  List<Ejercicio> _ejerciciosFiltrados = [];
  bool _cargando = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarEjercicios();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarEjercicios() async {
    setState(() => _cargando = true);
    try {
      final ejercicios = await _rutinasService.getEjercicios();
      setState(() {
        _ejercicios = ejercicios;
        _filtrarEjercicios(_searchController.text);
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando ejercicios: $e')),
        );
      }
    }
  }

  void _filtrarEjercicios(String query) {
    if (query.isEmpty) {
      setState(() => _ejerciciosFiltrados = _ejercicios);
    } else {
      setState(() {
        _ejerciciosFiltrados = _ejercicios.where((e) {
          return e.nombre.toLowerCase().contains(query.toLowerCase()) ||
              (e.grupoMuscular?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      });
    }
  }

  Future<void> _eliminarEjercicio(Ejercicio ejercicio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Ejercicio'),
        content: Text('¿Estás seguro de eliminar "${ejercicio.nombre}"?'),
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

    if (confirmar == true && ejercicio.id != null) {
      await _rutinasService.eliminarEjercicio(ejercicio.id!);
      _cargarEjercicios();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ejercicio eliminado')),
        );
      }
    }
  }

  void _navegarAFormulario({Ejercicio? ejercicio}) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioEjercicioScreen(ejercicio: ejercicio),
      ),
    );

    if (resultado == true) {
      _cargarEjercicios();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejercicios'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar ejercicio...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: _filtrarEjercicios,
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _ejerciciosFiltrados.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No hay ejercicios registrados',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _ejerciciosFiltrados.length,
                        padding: const EdgeInsets.only(bottom: 80),
                        itemBuilder: (context, index) {
                          final ejercicio = _ejerciciosFiltrados[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple.withOpacity(0.2),
                                child: const Icon(Icons.fitness_center, color: Colors.deepPurple),
                              ),
                              title: Text(
                                ejercicio.nombre,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(ejercicio.grupoMuscular ?? 'Sin grupo muscular'),
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
                                    _navegarAFormulario(ejercicio: ejercicio);
                                  } else if (value == 'eliminar') {
                                    _eliminarEjercicio(ejercicio);
                                  }
                                },
                              ),
                              onTap: () => _navegarAFormulario(ejercicio: ejercicio),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarAFormulario(),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }
}
