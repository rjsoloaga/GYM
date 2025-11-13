import 'package:flutter/material.dart';
import 'package:gym/features/planes/models/plan.dart';
import 'package:gym/features/planes/screens/plan_form_screen.dart';
import 'package:gym/features/planes/services/plan_service.dart';
import 'package:gym/features/planes/widgets/plan_card.dart';

class PlanesListScreen extends StatefulWidget {
  static const routeName = '/planes';

  const PlanesListScreen({Key? key}) : super(key: key);

  @override
  _PlanesListScreenState createState() => _PlanesListScreenState();
}

class _PlanesListScreenState extends State<PlanesListScreen> {
  final PlanService _planService = PlanService();
  late Future<List<Plan>> _planesFuture;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _loadPlanes();
    
    // Agregar un listener para cuando la pantalla vuelva a estar visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Verificar si la pantalla está en la pila de navegación
      if (ModalRoute.of(context)?.isCurrent == true) {
        _loadPlanes();
      }
    });
  }

  // Usaremos una clave para el RefreshIndicator
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cargar los planes cuando los dependencias cambian
    _loadPlanes();
  }

  // Método para cargar los planes
  Future<void> _loadPlanes() async {
    if (!mounted) return;
    
    setState(() {
      _planesFuture = _planService.obtenerPlanesActivos();
    });
  }
  
  // Método para manejar el refresh manual
  Future<void> _handleRefresh() async {
    await _loadPlanes();
  }

  Future<void> _togglePlanStatus(Plan plan) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(plan.activo ? 'Desactivar Plan' : 'Activar Plan'),
          content: Text(
            plan.activo
                ? '¿Estás seguro de que deseas desactivar este plan?'
                : '¿Deseas activar este plan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: plan.activo ? Colors.orange : Colors.green,
              ),
              child: Text(plan.activo ? 'Desactivar' : 'Activar'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        if (plan.activo) {
          await _planService.desactivarPlan(plan.id!);
        } else {
          final planActualizado = plan.copyWith(activo: true);
          await _planService.actualizarPlan(planActualizado);
        }
        _loadPlanes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                plan.activo
                    ? 'Plan desactivado correctamente'
                    : 'Plan activado correctamente',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePlan(Plan plan) async {
    try {
      // Verificar si el plan puede ser desactivado (no tiene socios asociados)
      final canDelete = await _planService.puedeEliminarse(plan.id!);
      
      if (!canDelete) {
        // Si no se puede eliminar porque tiene socios asociados
        if (mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('No se puede eliminar'),
              content: const Text(
                'Este plan no puede ser eliminado porque tiene socios asociados. En su lugar, puedes desactivarlo.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Confirmar la eliminación
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminar Plan'),
          content: const Text('¿Estás seguro de que deseas eliminar este plan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        // Mostrar un indicador de carga
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );

        try {
          // Realizar la eliminación lógica (desactivar)
          await _planService.desactivarPlan(plan.id!);
          
          // Cerrar el diálogo de carga
          if (mounted) {
            Navigator.of(context).pop();
            
            // Actualizar la lista de planes
            await _loadPlanes();
            
            // Mostrar mensaje de éxito
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Plan desactivado correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          // Cerrar el diálogo de carga en caso de error
          if (mounted) {
            Navigator.of(context).pop();
            
            // Mostrar mensaje de error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al desactivar el plan: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Planes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlanes,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).pushNamed('/planes/form', arguments: null);
              if (result == true) {
                // Solo recargar si el resultado es true (éxito)
                _loadPlanes();
              }
            },
            tooltip: 'Nuevo Plan',
          ),
        ],
      ),
      body: FutureBuilder<List<Plan>>(
        future: _planesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'Error al cargar los planes',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadPlanes,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final planes = snapshot.data ?? [];

          if (planes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay planes disponibles',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Presiona el botón + para crear un nuevo plan',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context).pushNamed('/planes/form', arguments: null);
                      if (result == true) {
                        // Solo recargar si el resultado es true (éxito)
                        _loadPlanes();
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Crear Plan'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _handleRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              itemCount: planes.length,
              itemBuilder: (ctx, index) {
                final plan = planes[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: PlanCard(
                    key: ValueKey('plan-${plan.id}'),
                    plan: plan,
                    onTap: () async {
                      final result = await Navigator.of(context).pushNamed(
                        '/planes/form',
                        arguments: plan,
                      );
                      
                      if (result == true && mounted) {
                        _loadPlanes();
                      }
                    },
                    onEdit: () async {
                      final result = await Navigator.of(context).pushNamed(
                        '/planes/form',
                        arguments: plan,
                      );
                      
                      if (result == true && mounted) {
                        _loadPlanes();
                      }
                    },
                    onDelete: () => _deletePlan(plan),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).pushNamed('/planes/form');
          if (result == true && mounted) {
            _loadPlanes();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Plan'),
      ),
    );
  }
}
