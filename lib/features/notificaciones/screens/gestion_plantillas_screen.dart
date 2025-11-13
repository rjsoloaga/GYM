import 'package:flutter/material.dart';
import 'package:gym/features/notificaciones/models/plantilla_notificacion.dart';
import 'package:gym/features/notificaciones/services/plantilla_service.dart';
import 'package:gym/features/socios/models/socio.dart';

class GestionPlantillasScreen extends StatefulWidget {
  const GestionPlantillasScreen({super.key});

  @override
  State<GestionPlantillasScreen> createState() => _GestionPlantillasScreenState();
}

class _GestionPlantillasScreenState extends State<GestionPlantillasScreen> {
  late List<PlantillaNotificacion> _plantillas;

  @override
  void initState() {
    super.initState();
    _plantillas = PlantillaService.plantillasPredeterminadas;
  }

  void _editarPlantilla(PlantillaNotificacion plantilla) {
    final controller = TextEditingController(text: plantilla.mensaje);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar: ${plantilla.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Variables disponibles:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final entry in PlantillaNotificacion.variablesDisponibles.entries)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Mensaje',
                hintText: 'Usa {variable} para insertar datos del socio',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final nuevaPlantilla = plantilla.copyWith(mensaje: controller.text);
              _actualizarPlantilla(nuevaPlantilla);
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _actualizarPlantilla(PlantillaNotificacion plantilla) {
    setState(() {
      final index = _plantillas.indexWhere((p) => p.id == plantilla.id);
      if (index != -1) {
        _plantillas[index] = plantilla;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Plantilla "${plantilla.nombre}" actualizada')),
    );
  }

  void _mostrarVistaPrevia(PlantillaNotificacion plantilla) {
    // Socio de ejemplo para la vista previa
    final socioEjemplo = Socio(
      nombreCompleto: 'Juan Pérez',
      dni: '12345678',
      telefono: '3624123456',
      email: 'juan@example.com',
      fechaInicio: DateTime.now(),
      fechaVencimiento: DateTime.now().add(const Duration(days: 5)),
      precioMensual: 5000.0,
      tipoPlan: 'Premium',
    );

    final mensaje = plantilla.aplicarVariables(socioEjemplo);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vista previa: ${plantilla.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Para: Juan Pérez (Vence en 5 días)'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(mensaje),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plantillas de Notificaciones'),
      ),
      body: ListView.builder(
        itemCount: _plantillas.length,
        itemBuilder: (context, index) {
          final plantilla = _plantillas[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(plantilla.nombre),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enviar ${plantilla.diasAntes >= 0 ? '${plantilla.diasAntes} días antes' : 'cuando esté vencida'}',
                    style: TextStyle(
                      color: plantilla.diasAntes == 0 ? Colors.orange : 
                             plantilla.diasAntes == -1 ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plantilla.mensaje,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () => _mostrarVistaPrevia(plantilla),
                    tooltip: 'Vista previa',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editarPlantilla(plantilla),
                    tooltip: 'Editar plantilla',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}