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
    final Color estadoColor = _getColorByEstado();
    final IconData estadoIcon = _getIconByEstado();
    // Usar sólo la parte de fecha para evitar errores por la hora del día
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final venc = DateTime(
      socio.fechaVencimiento.year,
      socio.fechaVencimiento.month,
      socio.fechaVencimiento.day,
    );
    final int dias = venc.difference(hoy).inDays;
    final String diasTexto = dias < 0
        ? 'Vencida hace ${-dias} días'
        : dias == 0
            ? 'Vence hoy'
            : dias == 1
                ? 'Vence mañana'
                : '$dias días restantes';
    final Color chipColor = dias < 0
        ? Colors.red
        : (dias <= 7 ? Colors.orange : Colors.green);

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).cardColor,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Indicador de estado
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(estadoIcon, color: estadoColor),
                ),
                const SizedBox(width: 12),
                // Datos del socio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        socio.nombreCompleto,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      _infoWithIcon(Icons.badge, 'DNI: ${socio.dni}'),
                      _infoWithIcon(Icons.phone, socio.telefono),
                      _infoWithIcon(Icons.email, socio.email),
                      const SizedBox(height: 8),
                      _buildStatusPill(diasTexto, chipColor),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Acciones verticales
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onNotificar != null && socio.necesitaNotificacion)
                      _actionIconButton(
                        context,
                        icon: Icons.notifications,
                        tooltip: 'Recordar por Telegram',
                        color: Colors.orange,
                        onPressed: onNotificar,
                      ),
                    if (onPagarCuota != null)
                      _actionIconButton(
                        context,
                        icon: Icons.attach_money,
                        tooltip: 'Cobrar cuota',
                        color: Colors.green,
                        onPressed: onPagarCuota,
                      ),
                    if (onEdit != null)
                      _actionIconButton(
                        context,
                        icon: Icons.edit,
                        tooltip: 'Editar',
                        color: Colors.blue,
                        onPressed: onEdit,
                      ),
                    if (onDelete != null)
                      _actionIconButton(
                        context,
                        icon: Icons.delete,
                        tooltip: 'Eliminar',
                        color: Colors.red,
                        onPressed: onDelete,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTelegramStatus(socio),
          ],
        ),
      ),
    );
  }

  Widget _infoWithIcon(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _actionIconButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: Icon(icon, color: color),
            ),
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