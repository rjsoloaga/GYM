import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// Widget que muestra un lobo haciendo ejercicio usando Rive
/// Si el archivo .riv no está disponible, muestra una animación alternativa mejorada
class RiveGymWolf extends StatefulWidget {
  final double size;
  final bool showGlow;

  const RiveGymWolf({
    super.key,
    this.size = 240,
    this.showGlow = true,
  });

  @override
  State<RiveGymWolf> createState() => _RiveGymWolfState();
}

class _RiveGymWolfState extends State<RiveGymWolf> {
  Artboard? _riveArtboard;
  StateMachineController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadRiveAnimation();
  }

  Future<void> _loadRiveAnimation() async {
    try {
      // Intentar cargar el archivo Rive
      final data = await RiveFile.asset('assets/animations/gym_wolf.riv');
      final artboard = data.mainArtboard;
      
      // Buscar el state machine (si existe)
      final controller = StateMachineController.fromArtboard(
        artboard,
        'State Machine 1', // Nombre del state machine en Rive
      );

      if (controller != null) {
        artboard.addController(controller);
        _controller = controller;
      }

      setState(() {
        _riveArtboard = artboard;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      // Si no se encuentra el archivo, usar animación alternativa
      print('⚠️ No se encontró el archivo Rive, usando animación alternativa: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF4444),
          ),
        ),
      );
    }

    if (_hasError || _riveArtboard == null) {
      // Mostrar animación alternativa mejorada
      return _AdvancedAnimatedWolf(
        size: widget.size,
        showGlow: widget.showGlow,
      );
    }

    // Mostrar animación Rive
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: widget.size > 100
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                  spreadRadius: 3,
                ),
                if (widget.showGlow)
                  BoxShadow(
                    color: const Color(0xFFFF4444).withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
              ],
            )
          : null,
      child: ClipOval(
        child: Rive(
          artboard: _riveArtboard!,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// Animación alternativa avanzada usando Flutter nativo
/// Simula movimientos más complejos de ejercicio
class _AdvancedAnimatedWolf extends StatefulWidget {
  final double size;
  final bool showGlow;

  const _AdvancedAnimatedWolf({
    required this.size,
    required this.showGlow,
  });

  @override
  State<_AdvancedAnimatedWolf> createState() => _AdvancedAnimatedWolfState();
}

class _AdvancedAnimatedWolfState extends State<_AdvancedAnimatedWolf>
    with TickerProviderStateMixin {
  late AnimationController _pushUpController; // Flexiones
  late AnimationController _breathingController; // Respiración
  late AnimationController _rotationController; // Rotación
  late AnimationController _glowController; // Brillo
  late AnimationController _scaleController; // Escalado

  late Animation<double> _pushUpAnimation;
  late Animation<double> _breathingAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Controlador para flexiones (movimiento más realista)
    _pushUpController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Controlador para respiración
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Controlador para rotación sutil
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    // Controlador para brillo
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Controlador para escalado (efecto de esfuerzo)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Animación de flexiones (movimiento más complejo)
    _pushUpAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -20.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 0.3,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -20.0, end: -20.0)
            .chain(CurveTween(curve: Curves.linear)),
        weight: 0.2,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -20.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 0.3,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.0)
            .chain(CurveTween(curve: Curves.linear)),
        weight: 0.2,
      ),
    ]).animate(_pushUpController);

    // Animación de respiración
    _breathingAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));

    // Animación de rotación (más sutil)
    _rotationAnimation = Tween<double>(
      begin: -0.03,
      end: 0.03,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));

    // Animación de brillo
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Animación de escalado (simula esfuerzo)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.03)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 0.5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.03, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.5,
      ),
    ]).animate(_scaleController);

    // Iniciar animaciones
    _pushUpController.repeat();
    _breathingController.repeat(reverse: true);
    _rotationController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
    _scaleController.repeat();
  }

  @override
  void dispose() {
    _pushUpController.dispose();
    _breathingController.dispose();
    _rotationController.dispose();
    _glowController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pushUpAnimation,
        _breathingAnimation,
        _rotationAnimation,
        _glowAnimation,
        _scaleAnimation,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _pushUpAnimation.value),
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Transform.scale(
              scale: _breathingAnimation.value * _scaleAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: widget.size > 100
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: 0.15 + _glowAnimation.value * 0.25,
                          ),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                            spreadRadius: 3,
                          ),
                          if (widget.showGlow)
                            BoxShadow(
                              color: const Color(0xFFFF4444).withValues(
                                alpha: _glowAnimation.value * 0.5,
                              ),
                              blurRadius: 30 + _glowAnimation.value * 25,
                              spreadRadius: 5 + _glowAnimation.value * 8,
                            ),
                        ],
                      )
                    : null,
                child: ClipOval(
                  child: ColorFiltered(
                    colorFilter: ColorFilter.matrix([
                      1.25 + _glowAnimation.value * 0.15,
                      0,
                      0,
                      0,
                      20 + _glowAnimation.value * 15,
                      0,
                      1.25 + _glowAnimation.value * 0.15,
                      0,
                      0,
                      20 + _glowAnimation.value * 15,
                      0,
                      0,
                      1.25 + _glowAnimation.value * 0.15,
                      0,
                      20 + _glowAnimation.value * 15,
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

