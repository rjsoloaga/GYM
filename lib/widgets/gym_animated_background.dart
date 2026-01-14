import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Background animado con elementos de gimnasio
/// Incluye partículas flotantes de discos de pesas, barras y efectos de energía
class GymAnimatedBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final bool showGrid;
  final bool weightsOnly; // Si es true, solo muestra discos de pesas

  const GymAnimatedBackground({
    super.key,
    required this.child,
    this.particleCount = 15,
    this.showGrid = true,
    this.weightsOnly = false, // Por defecto muestra todos los tipos
  });

  @override
  State<GymAnimatedBackground> createState() => _GymAnimatedBackgroundState();
}

class _GymAnimatedBackgroundState extends State<GymAnimatedBackground>
    with TickerProviderStateMixin {
  late List<Particle> _particles;
  late AnimationController _particleController;
  late AnimationController _gridController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Controlador para partículas flotantes (más rápido para mejor visibilidad)
    _particleController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    // Controlador para grid/energía
    _gridController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Controlador para efectos de pulso
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Inicializar partículas
    _particles = List.generate(
      widget.particleCount,
      (index) => Particle.random(weightsOnly: widget.weightsOnly),
    );
  }

  @override
  void dispose() {
    _particleController.dispose();
    _gridController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background base con gradiente (sin tono rojo para no opacar los discos)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF000000),
                const Color(0xFF0A0A0A),
                const Color(0xFF050505),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Grid animado (opcional) - completamente deshabilitado si weightsOnly
        if (widget.showGrid && !widget.weightsOnly)
          AnimatedBuilder(
            animation: _gridController,
            builder: (context, child) {
              return CustomPaint(
                painter: GridPainter(
                  progress: _gridController.value,
                  color: const Color(0xFF333333).withValues(alpha: 0.08), // Muy sutil, gris oscuro
                ),
              );
            },
          ),

        // Efectos de pulso/energía - completamente deshabilitados si weightsOnly
        if (!widget.weightsOnly)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
                return CustomPaint(
                  painter: PulsePainter(
                    progress: _pulseController.value,
                    color: const Color(0xFF444444).withValues(alpha: 0.05), // Muy sutil, casi invisible
                  ),
                );
            },
          ),

        // Partículas flotantes (solo discos si weightsOnly es true)
        AnimatedBuilder(
          animation: _particleController,
          builder: (context, child) {
            return CustomPaint(
              painter: ParticlePainter(
                particles: _particles,
                progress: _particleController.value,
              ),
            );
          },
        ),

        // Contenido principal
        widget.child,
      ],
    );
  }
}

/// Clase para representar una partícula
class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double angle;
  final ParticleType type;
  final Color color;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.angle,
    required this.type,
    required this.color,
  });

  factory Particle.random({bool weightsOnly = false}) {
    final random = math.Random();
    ParticleType selectedType;
    
    if (weightsOnly) {
      // Solo mancuernas
      selectedType = ParticleType.weight;
    } else {
      // Priorizar mancuernas para mejor visibilidad
      final types = [ParticleType.weight, ParticleType.weight, ParticleType.weight, ParticleType.bar, ParticleType.energy];
      selectedType = types[random.nextInt(types.length)];
    }
    
    // Generar tamaño - hacer mancuernas más grandes
    final particleSize = selectedType == ParticleType.weight 
        ? 80 + random.nextDouble() * 100  // 80-180px para mancuernas (más grandes)
        : 50 + random.nextDouble() * 80;  // 50-130px para otros
    
    // Para mancuernas, usar área central de la pantalla (evitar bordes)
    final marginX = 0.12; // Margen horizontal reducido
    final marginY = 0.15; // Margen vertical reducido pero suficiente
    
    double x, y;
    if (selectedType == ParticleType.weight) {
      // Para mancuernas, usar área central visible (evitar bordes superiores donde está el AppBar)
      x = marginX + random.nextDouble() * (1.0 - 2 * marginX);
      y = marginY + random.nextDouble() * (0.85 - marginY); // Evitar parte superior (15% del top)
    } else {
      // Para otros tipos, distribución normal
      x = random.nextDouble();
      y = random.nextDouble();
    }
    
    return Particle(
      x: x,
      y: y,
      size: particleSize,
      speed: 0.5 + random.nextDouble() * 1.0, // Movimiento más rápido
      angle: random.nextDouble() * 2 * math.pi,
      type: selectedType,
      color: _getColorForType(selectedType),
    );
  }

  static Color _getColorForType(ParticleType type) {
    switch (type) {
      case ParticleType.weight:
        return const Color(0xFF6B7280).withValues(alpha: 0.9); // Gris metálico para discos de pesas
      case ParticleType.bar:
        return const Color(0xFFFF6B35).withValues(alpha: 0.5); // Reducido para no competir con discos
      case ParticleType.energy:
        return const Color(0xFF4CAF50).withValues(alpha: 0.4); // Reducido para no competir con discos
    }
  }

}

enum ParticleType { weight, bar, energy }

/// Painter para las partículas
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Calcular posición actual basada en el progreso (movimiento más visible)
      // Usar coordenadas normalizadas (0-1) y luego escalar al tamaño de la pantalla
      final distance = particle.speed * progress * 0.1; // Movimiento suave
      var normalizedX = particle.x + math.cos(particle.angle) * distance;
      var normalizedY = particle.y + math.sin(particle.angle) * distance;
      
      // Para mancuernas, mantener dentro de márgenes seguros y área visible
      if (particle.type == ParticleType.weight) {
        final marginX = 0.12;
        final marginY = 0.15;
        final maxY = 0.85; // No pasar del 85% de altura (evitar área del AppBar)
        
        // Limitar movimiento dentro del área segura
        normalizedX = normalizedX.clamp(marginX, 1.0 - marginX);
        normalizedY = normalizedY.clamp(marginY, maxY);
        
        // Si se sale del área, invertir dirección suavemente
        if (normalizedX <= marginX || normalizedX >= 1.0 - marginX) {
          normalizedX = particle.x.clamp(marginX, 1.0 - marginX);
        }
        if (normalizedY <= marginY || normalizedY >= maxY) {
          normalizedY = particle.y.clamp(marginY, maxY);
        }
      } else {
        // Para otros tipos, wrap normal
        normalizedX = normalizedX % 1.0;
        normalizedY = normalizedY % 1.0;
        if (normalizedX < 0) normalizedX += 1.0;
        if (normalizedY < 0) normalizedY += 1.0;
      }
      
      // Escalar a píxeles
      final x = normalizedX * size.width;
      final y = normalizedY * size.height;

      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      switch (particle.type) {
        case ParticleType.weight:
          // Dibujar mancuerna
          _drawWeight(canvas, paint, x, y, particle.size);
          break;
        case ParticleType.bar:
          // Dibujar barra (rectángulo largo)
          _drawBar(canvas, paint, x, y, particle.size);
          break;
        case ParticleType.energy:
          // Dibujar efecto de energía (estrella/brillo)
          _drawEnergy(canvas, paint, x, y, particle.size);
          break;
      }
    }
  }

  void _drawWeight(Canvas canvas, Paint paint, double x, double y, double size) {
    // Dibujar mancuerna: barra central horizontal con dos pesos en los extremos
    // Aumentar proporciones para mejor visibilidad
    final barLength = size * 0.7; // Longitud de la barra (más larga)
    final weightRadius = size * 0.28; // Radio de los pesos (más grandes)
    final barWidth = size * 0.12; // Ancho de la barra central (más gruesa)
    
    // Color base metálico más claro y visible (gris plateado brillante)
    final baseColor = const Color(0xFF9CA3AF); // Más claro
    final basePaint = Paint()
      ..color = baseColor.withValues(alpha: 1.0)
      ..style = PaintingStyle.fill;
    
    // Borde oscuro más grueso para máximo contraste
    final borderPaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 1.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0; // Más grueso
    
    // Dibujar barra central horizontal
    final barRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, y),
        width: barLength,
        height: barWidth,
      ),
      Radius.circular(barWidth / 2),
    );
    canvas.drawRRect(barRect, basePaint);
    canvas.drawRRect(barRect, borderPaint);
    
    // Dibujar peso izquierdo
    final leftWeightCenter = Offset(x - barLength / 2, y);
    canvas.drawCircle(leftWeightCenter, weightRadius, basePaint);
    canvas.drawCircle(leftWeightCenter, weightRadius, borderPaint);
    
    // Agujero del peso izquierdo
    final holeRadius = weightRadius * 0.4;
    final holePaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(leftWeightCenter, holeRadius, holePaint);
    
    // Borde interior del agujero izquierdo
    final holeBorderPaint = Paint()
      ..color = const Color(0xFF9CA3AF).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(leftWeightCenter, holeRadius, holeBorderPaint);
    
    // Resaltado del peso izquierdo
    final highlightPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(leftWeightCenter.dx - weightRadius * 0.3, leftWeightCenter.dy - weightRadius * 0.3),
      weightRadius * 0.2,
      highlightPaint,
    );
    
    // Dibujar peso derecho
    final rightWeightCenter = Offset(x + barLength / 2, y);
    canvas.drawCircle(rightWeightCenter, weightRadius, basePaint);
    canvas.drawCircle(rightWeightCenter, weightRadius, borderPaint);
    
    // Agujero del peso derecho
    canvas.drawCircle(rightWeightCenter, holeRadius, holePaint);
    canvas.drawCircle(rightWeightCenter, holeRadius, holeBorderPaint);
    
    // Resaltado del peso derecho
    canvas.drawCircle(
      Offset(rightWeightCenter.dx - weightRadius * 0.3, rightWeightCenter.dy - weightRadius * 0.3),
      weightRadius * 0.2,
      highlightPaint,
    );
    
    // Líneas radiales en ambos pesos (marcas decorativas)
    final radialPaint = Paint()
      ..color = const Color(0xFF1F2937).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    final innerRadius = weightRadius * 0.5;
    final outerRadius = weightRadius * 0.85;
    
    // Líneas radiales del peso izquierdo
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi * 2) / 6;
      final startX = leftWeightCenter.dx + innerRadius * math.cos(angle);
      final startY = leftWeightCenter.dy + innerRadius * math.sin(angle);
      final endX = leftWeightCenter.dx + outerRadius * math.cos(angle);
      final endY = leftWeightCenter.dy + outerRadius * math.sin(angle);
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        radialPaint,
      );
    }
    
    // Líneas radiales del peso derecho
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi * 2) / 6;
      final startX = rightWeightCenter.dx + innerRadius * math.cos(angle);
      final startY = rightWeightCenter.dy + innerRadius * math.sin(angle);
      final endX = rightWeightCenter.dx + outerRadius * math.cos(angle);
      final endY = rightWeightCenter.dy + outerRadius * math.sin(angle);
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        radialPaint,
      );
    }
    
    // Detalles en la barra (textura de agarre)
    final gripPaint = Paint()
      ..color = const Color(0xFF4B5563).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Líneas verticales en la barra para simular textura
    for (int i = -2; i <= 2; i++) {
      final offsetX = x + (i * barLength / 5);
      canvas.drawLine(
        Offset(offsetX, y - barWidth / 2),
        Offset(offsetX, y + barWidth / 2),
        gripPaint,
      );
    }
  }

  void _drawBar(Canvas canvas, Paint paint, double x, double y, double size) {
    // Barra más gruesa y visible
    final barWidth = size;
    final barHeight = size / 3;
    
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, y),
        width: barWidth,
        height: barHeight,
      ),
      const Radius.circular(4),
    );
    
    // Borde
    final strokePaint = Paint()
      ..color = paint.color.withValues(alpha: paint.color.a * 1.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawRRect(rect, paint);
    canvas.drawRRect(rect, strokePaint);
    
    // Resaltado más visible
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final highlightRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, y - barHeight / 4),
        width: barWidth * 0.8,
        height: barHeight / 3,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(highlightRect, highlightPaint);
  }

  void _drawEnergy(Canvas canvas, Paint paint, double x, double y, double size) {
    // Estrella más visible con borde
    final strokePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final path = Path();
    final points = 8;
    for (int i = 0; i < points; i++) {
      final angle = (i * 2 * math.pi / points) + (math.pi / points);
      final radius = (i % 2 == 0) ? size / 2 : size / 4;
      final px = x + radius * math.cos(angle);
      final py = y + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
    
    // Brillo central más visible
    final centerPaint = Paint()
      ..color = paint.color.withValues(alpha: 1.0)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), size / 6, centerPaint);
    
    // Efecto de brillo exterior
    final glowPaint = Paint()
      ..color = paint.color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), size / 3, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Painter para el grid/estructura
class GridPainter extends CustomPainter {
  final double progress;
  final Color color;

  GridPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final spacing = 60.0;
    final offset = progress * spacing;

    // Líneas verticales
    for (double x = -offset; x < size.width + spacing; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Líneas horizontales
    for (double y = -offset; y < size.height + spacing; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Painter para efectos de pulso
class PulsePainter extends CustomPainter {
  final double progress;
  final Color color;

  PulsePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Múltiples ondas concéntricas
    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + i * 0.33) % 1.0;
      final radius = size.width * 0.3 * waveProgress;
      final alpha = (1 - waveProgress) * color.a;
      
      final wavePaint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.2),
        radius,
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

