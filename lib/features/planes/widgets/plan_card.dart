import 'package:flutter/material.dart';
import 'package:gym/features/planes/models/plan.dart';

class PlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const PlanCard({
    Key? key,
    required this.plan,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      plan.nombre.isNotEmpty ? plan.nombre : 'Sin nombre',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color ?? Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (!plan.activo)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        'Inactivo',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8.0),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Icon(Icons.attach_money, 
                    size: 16.0, 
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    '\$${plan.precio.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Icon(
                    Icons.calendar_today, 
                    size: 16.0, 
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    plan.tiempoIndeterminado || plan.duracionDias == null 
                        ? 'Tiempo indefinido' 
                        : '${plan.duracionDias} días',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87,
                    ),
                  ),
                ],
              ),
              if (showActions) ..._buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    if (!showActions) return [];

    return [
      const Divider(height: 24.0, thickness: 1.0),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (onEdit != null)
            TextButton.icon(
              icon: const Icon(Icons.edit, size: 16.0),
              label: const Text('Editar'),
              onPressed: onEdit,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          if (onDelete != null)
            TextButton.icon(
              icon: const Icon(Icons.delete, size: 16.0, color: Colors.red),
              label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onPressed: onDelete,
            ),
        ],
      ),
    ];
  }
}