import 'package:flutter/material.dart';

/// Widget animado que muestra un lobo haciendo ejercicio
/// Simula movimientos de flexiones/saltos con efectos visuales
class AnimatedGymWolf extends StatefulWidget {
  final double size;
  final bool showGlow;

  const AnimatedGymWolf({
    super.key,
    this.size = 240,
    this.showGlow = true,
  });

  @override
  State<AnimatedGymWolf> createState() => _AnimatedGymWolfState();
}

class _AnimatedGymWolfState extends State<AnimatedGymWolf>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _glowController;

  late Animation<double> _bounceAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Controlador para el movimiento de arriba-abajo (flexiones/saltos)
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Controlador para rotación sutil
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Controlador para pulso (efecto de respiración/energía)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Controlador para el brillo/glow
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Animación de rebote (simula flexiones - movimiento vertical)
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 15.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));

    // Animación de rotación sutil (simula movimiento de brazos)
    _rotationAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));

    // Animación de pulso (escalado)
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Animación de brillo
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Iniciar animaciones
    _bounceController.repeat(reverse: true);
    _rotationController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _bounceAnimation,
        _rotationAnimation,
        _pulseAnimation,
        _glowAnimation,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_bounceAnimation.value),
          child: Transform.rotate(
            angle: _rotationAnimation.value,
              child: Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: widget.size > 100
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15 + _glowAnimation.value * 0.2),
                          width: 3,
                        ),
                        boxShadow: [
                          // Sombra principal
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                            spreadRadius: 3,
                          ),
                          // Efecto de brillo rojo cuando showGlow es true
                          if (widget.showGlow)
                            BoxShadow(
                              color: const Color(0xFFFF4444).withValues(
                                alpha: _glowAnimation.value * 0.4,
                              ),
                              blurRadius: 30 + _glowAnimation.value * 20,
                              spreadRadius: 5 + _glowAnimation.value * 5,
                            ),
                        ],
                      )
                    : null,
                child: ClipOval(
                  child: ColorFiltered(
                    colorFilter: ColorFilter.matrix([
                      // Aumentar brillo dinámicamente
                      1.25 + _glowAnimation.value * 0.1,
                      0,
                      0,
                      0,
                      20 + _glowAnimation.value * 10,
                      0,
                      1.25 + _glowAnimation.value * 0.1,
                      0,
                      0,
                      20 + _glowAnimation.value * 10,
                      0,
                      0,
                      1.25 + _glowAnimation.value * 0.1,
                      0,
                      20 + _glowAnimation.value * 10,
                      0,
                      0,
                      0,
                      1,
                      0,
                    ]),
                    child: Image.asset(
                      'lobo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

