import 'package:flutter/material.dart';
import '../models/socio.dart';

class SocioCard extends StatelessWidget {
  final Socio socio;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCobrar; // Para futura integración con pagos
  final VoidCallback? onNotificar; // Para futura integración con notificaciones
  final VoidCallback? onPagarCuota; // Nuevo botón para pagar cuota

  const SocioCard({
    super.key,
    required this.socio,
  this.onEdit,
  this.onDelete,
    this.onCobrar,
    this.onNotificar,
    this.onPagarCuota,
  });

  // Método para obtener el color según el estado de la cuota
  Color _getColorByEstado() {
    switch (socio.estadoCuota) {
      case 'Vencido':
        return Colors.red;
      case 'Por Vencer':
        return Colors.orange;
      case 'Al Día':  // ← DEBE COINCIDIR CON EL MODELO
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Método para obtener el icono según el estado
  IconData _getIconByEstado() {
    switch (socio.estadoCuota) {
      case 'Vencido':
        return Icons.error;
      case 'Por Vencer':
        return Icons.warning;
      case 'Al Día':  // ← DEBE COINCIDIR CON EL MODELO
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  // Formatear fecha para mostrar
  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: _getColorByEstado(),
              width: 6,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con nombre y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      socio.nombreCompleto,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        _getIconByEstado(),
                        color: _getColorByEstado(),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        socio.estadoCuota,
                        style: TextStyle(
                          color: _getColorByEstado(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Información del socio
              _buildInfoRow('DNI:', socio.dni),
              _buildInfoRow('Teléfono:', socio.telefono),
              _buildInfoRow('Email:', socio.email),
              
              const SizedBox(height: 4),
              _buildTelegramStatus(socio),
              
              const SizedBox(height: 8),
              
              // Fechas
              Row(
                children: [
                  Expanded(
                    child: _buildDateInfo(
                      'Inicio:',
                      _formatearFecha(socio.fechaInicio),
                    ),
                  ),
                  Expanded(
                    child: _buildDateInfo(
                      'Vence:',
                      _formatearFecha(socio.fechaVencimiento),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Plan y precio
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(
                      socio.tipoPlan,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.blue,
                  ),
                  Text(
                    '\$${socio.precioMensual.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),

              // 🆕 BOTÓN DE NOTIFICACIÓN (si está habilitado y el socio lo necesita)
              if (onNotificar != null && socio.necesitaNotificacion) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onNotificar, // ← ESTE BOTÓN DEBE FUNCIONAR
                    icon: const Icon(Icons.notifications, size: 18),
                    label: const Text('Recordatorio de Cuota'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // 🆕 BOTÓN PAGAR CUOTA (solo para socios vencidos o por vencer)
              if (onPagarCuota != null && socio.estadoCuota != 'Verde') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onPagarCuota,
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Cobrar Cuota'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // BOTONES DE ACCIÓN PRINCIPALES
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Editar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: onEdit != null ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Eliminar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: onDelete != null ? Colors.red : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Botón de cobrar (para futuro)
              if (onCobrar != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onCobrar,
                    icon: const Icon(Icons.payment),
                    label: const Text('Cobrar Cuota'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? 'No especificado' : value,
              style: TextStyle(
                color: value.isEmpty ? Colors.grey : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTelegramStatus(Socio socio) {
    // VERDADERO estado - basado en si puede recibir mensajes
    final bool puedeRecibirMensajes = socio.telegramChatId != null && 
                                    socio.telegramChatId!.isNotEmpty && 
                                    socio.telegramChatId != 'temp_${socio.id}';
    
    return Row(
      children: [
        Icon(
          puedeRecibirMensajes ? Icons.telegram : Icons.telegram_outlined,
          color: puedeRecibirMensajes ? Colors.blue : Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          puedeRecibirMensajes ? 'Conectado a Telegram' : 'No registrado en Telegram',
          style: TextStyle(
            color: puedeRecibirMensajes ? Colors.blue : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}