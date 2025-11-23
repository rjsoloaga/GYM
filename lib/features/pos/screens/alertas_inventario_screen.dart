import 'package:flutter/material.dart';
import 'package:gym/features/pos/models/alerta_inventario.dart';
import 'package:gym/features/pos/models/producto.dart';
import 'package:gym/features/pos/services/lotes_repository.dart';
import 'package:gym/features/pos/services/productos_repository.dart';
import 'package:intl/intl.dart';

class AlertasInventarioScreen extends StatefulWidget {
  const AlertasInventarioScreen({super.key});

  @override
  State<AlertasInventarioScreen> createState() => _AlertasInventarioScreenState();
}

class _AlertasInventarioScreenState extends State<AlertasInventarioScreen> {
  final LotesRepository _lotesRepository = LotesRepository();
  final ProductosRepository _productosRepository = ProductosRepository();
  
  List<AlertaInventario> _alertas = [];
  Map<int, Producto> _productosCache = {};
  bool _isLoading = true;
  bool _soloNoLeidas = true;

  @override
  void initState() {
    super.initState();
    _cargarAlertas();
  }

  Future<void> _cargarAlertas() async {
    setState(() => _isLoading = true);
    try {
      final alertas = await _lotesRepository.obtenerAlertas(soloNoLeidas: _soloNoLeidas);
      
      // Cargar productos en caché
      final productosIds = alertas.where((a) => a.productoId != null).map((a) => a.productoId!).toSet();
      for (var id in productosIds) {
        final producto = await _productosRepository.obtenerPorId(id);
        if (producto != null) {
          _productosCache[id] = producto;
        }
      }
      
      setState(() {
        _alertas = alertas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando alertas: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _marcarComoLeida(AlertaInventario alerta) async {
    try {
      await _lotesRepository.marcarAlertaComoLeida(alerta.id!);
      _cargarAlertas();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _marcarTodasComoLeidas() async {
    try {
      await _lotesRepository.marcarTodasComoLeidas();
      _cargarAlertas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todas las alertas marcadas como leídas'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getColorPrioridad(PrioridadAlerta prioridad) {
    switch (prioridad) {
      case PrioridadAlerta.critica:
        return Colors.red;
      case PrioridadAlerta.alta:
        return Colors.orange;
      case PrioridadAlerta.media:
        return Colors.yellow.shade700;
      case PrioridadAlerta.baja:
        return Colors.blue;
    }
  }

  IconData _getIconoTipo(TipoAlerta tipo) {
    switch (tipo) {
      case TipoAlerta.productoVencido:
        return Icons.dangerous;
      case TipoAlerta.vencimientoCritico:
        return Icons.warning_amber;
      case TipoAlerta.vencimientoProximo:
        return Icons.access_time;
      case TipoAlerta.stockBajo:
        return Icons.inventory;
      case TipoAlerta.stockCritico:
        return Icons.error_outline;
    }
  }

  String _getTituloTipo(TipoAlerta tipo) {
    switch (tipo) {
      case TipoAlerta.productoVencido:
        return 'Producto Vencido';
      case TipoAlerta.vencimientoCritico:
        return 'Vencimiento Crítico';
      case TipoAlerta.vencimientoProximo:
        return 'Vencimiento Próximo';
      case TipoAlerta.stockBajo:
        return 'Stock Bajo';
      case TipoAlerta.stockCritico:
        return 'Stock Crítico';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final alertasNoLeidas = _alertas.where((a) => !a.leida).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas de Inventario'),
        actions: [
          if (alertasNoLeidas > 0)
            TextButton.icon(
              onPressed: _marcarTodasComoLeidas,
              icon: const Icon(Icons.done_all, color: Colors.white),
              label: const Text('Marcar todas', style: TextStyle(color: Colors.white)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarAlertas,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtro
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('No Leídas'),
                        icon: Icon(Icons.notifications_active),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Todas'),
                        icon: Icon(Icons.notifications),
                      ),
                    ],
                    selected: {_soloNoLeidas},
                    onSelectionChanged: (Set<bool> selection) {
                      setState(() {
                        _soloNoLeidas = selection.first;
                      });
                      _cargarAlertas();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Estadísticas
          if (!_isLoading && _alertas.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Flexible(
                    child: _buildStatChip(
                      'Total',
                      _alertas.length.toString(),
                      Icons.notifications,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: _buildStatChip(
                      'No Leídas',
                      alertasNoLeidas.toString(),
                      Icons.notifications_active,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: _buildStatChip(
                      'Críticas',
                      _alertas.where((a) => a.prioridad == PrioridadAlerta.critica).length.toString(),
                      Icons.dangerous,
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 1),

          // Lista de alertas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _alertas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _soloNoLeidas ? Icons.notifications_off : Icons.notifications_none,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _soloNoLeidas
                                  ? '¡No hay alertas pendientes!'
                                  : 'No hay alertas registradas',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _alertas.length,
                        itemBuilder: (context, index) {
                          final alerta = _alertas[index];
                          final producto = alerta.productoId != null
                              ? _productosCache[alerta.productoId!]
                              : null;
                          final color = _getColorPrioridad(alerta.prioridad);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: alerta.leida ? null : color.withOpacity(0.05),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.2),
                                child: Icon(_getIconoTipo(alerta.tipo), color: color),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getTituloTipo(alerta.tipo),
                                      style: TextStyle(
                                        fontWeight: alerta.leida ? FontWeight.normal : FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (!alerta.leida)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (producto != null)
                                    Text(
                                      producto.nombre,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  Text(alerta.mensaje),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateFormat.format(alerta.fechaCreacion),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: !alerta.leida
                                  ? IconButton(
                                      icon: const Icon(Icons.done),
                                      onPressed: () => _marcarComoLeida(alerta),
                                      tooltip: 'Marcar como leída',
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
