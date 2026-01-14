import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget que muestra la fecha y hora actual actualizándose en tiempo real
class DateTimeDisplay extends StatefulWidget {
  final bool showDate;
  final bool showTime;
  final TextStyle? textStyle;

  const DateTimeDisplay({
    super.key,
    this.showDate = true,
    this.showTime = true,
    this.textStyle,
  });

  @override
  State<DateTimeDisplay> createState() => _DateTimeDisplayState();
}

class _DateTimeDisplayState extends State<DateTimeDisplay> {
  DateTime _currentDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Actualizar cada segundo
    _updateDateTime();
  }

  void _updateDateTime() {
    if (mounted) {
      setState(() {
        _currentDateTime = DateTime.now();
      });
      // Programar próxima actualización
      Future.delayed(const Duration(seconds: 1), _updateDateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.9),
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    );

    final style = widget.textStyle ?? defaultStyle;

    // Si solo se muestra una línea (AppBar), mostrar en formato compacto
    if (widget.showDate && widget.showTime && (style.fontSize ?? 16) < 14) {
      return Text(
        '${DateFormat('d/MM/yyyy', 'es_ES').format(_currentDateTime)} ${DateFormat('HH:mm:ss', 'es_ES').format(_currentDateTime)}',
        style: style,
        textAlign: TextAlign.right,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.showDate)
          Text(
            DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES').format(_currentDateTime),
            style: style.copyWith(
              fontSize: style.fontSize ?? 16,
            ),
            textAlign: TextAlign.center,
          ),
        if (widget.showDate && widget.showTime) const SizedBox(height: 4),
        if (widget.showTime)
          Text(
            DateFormat('HH:mm:ss', 'es_ES').format(_currentDateTime),
            style: style.copyWith(
              fontSize: (style.fontSize ?? 16) + 4,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

