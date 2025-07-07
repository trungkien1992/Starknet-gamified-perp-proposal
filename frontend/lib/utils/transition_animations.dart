import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Reusable animation transitions for the gamified trading app.
/// 
/// This utility provides pre-built animation effects that can be easily
/// applied to widgets throughout the app for consistent, snappy UX.
/// All animations are optimized for performance and keep duration < 600ms.
class TransitionAnimations {
  
  /// Creates a fade + scale modal transition effect.
  /// 
  /// Perfect for modals that need to appear with impact.
  /// 
  /// Example usage:
  /// ```dart
  /// // In a showDialog:
  /// showDialog(
  ///   context: context,
  ///   builder: (context) => TransitionAnimations.fadeScaleModal(
  ///     child: MyModal(),
  ///   ),
  /// );
  /// 
  /// // As a wrapper:
  /// TransitionAnimations.fadeScaleModal(
  ///   child: DripRewardModal(...),
  /// )
  /// ```
  static Widget fadeScaleModal({
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.elasticOut,
    double initialScale = 0.8,
  }) {
    return _FadeScaleTransition(
      child: child,
      duration: duration,
      curve: curve,
      initialScale: initialScale,
    );
  }

  /// Creates a confetti burst overlay that can be placed over any widget.
  /// 
  /// Automatically triggers and fades out. Perfect for celebration effects.
  /// 
  /// Example usage:
  /// ```dart
  /// // Overlay on a widget:
  /// Stack(
  ///   children: [
  ///     MyContent(),
  ///     TransitionAnimations.confettiBurst(
  ///       particleCount: 30,
  ///       colors: [Colors.yellow, Colors.orange, Colors.pink],
  ///     ),
  ///   ],
  /// )
  /// 
  /// // In a positioned overlay:
  /// Positioned.fill(
  ///   child: TransitionAnimations.confettiBurst(),
  /// )
  /// ```
  static Widget confettiBurst({
    int particleCount = 25,
    List<Color>? colors,
    Duration duration = const Duration(milliseconds: 1500),
    Offset? origin,
  }) {
    return _ConfettiBurstOverlay(
      particleCount: particleCount,
      colors: colors ?? _defaultConfettiColors,
      duration: duration,
      origin: origin,
    );
  }

  /// Creates a shake effect for indicating errors or invalid actions.
  /// 
  /// Useful for form validation, invalid swipes, or failed actions.
  /// 
  /// Example usage:
  /// ```dart
  /// // Shake a button on error:
  /// TransitionAnimations.shakeEffect(
  ///   child: ElevatedButton(...),
  ///   trigger: hasError,
  /// )
  /// 
  /// // Shake a form field:
  /// TransitionAnimations.shakeEffect(
  ///   child: TextField(...),
  ///   intensity: 10.0,
  /// )
  /// ```
  static Widget shakeEffect({
    required Widget child,
    bool trigger = true,
    Duration duration = const Duration(milliseconds: 500),
    double intensity = 8.0,
    int shakeCount = 4,
  }) {
    return _ShakeEffectWrapper(
      child: child,
      trigger: trigger,
      duration: duration,
      intensity: intensity,
      shakeCount: shakeCount,
    );
  }

  /// Creates a glow pulse effect for highlighting important elements.
  /// 
  /// Perfect for XP bars, level-ups, or drawing attention to features.
  /// 
  /// Example usage:
  /// ```dart
  /// // Pulsing XP bar:
  /// TransitionAnimations.glowPulse(
  ///   child: XpBar(),
  ///   glowColor: Colors.cyan,
  /// )
  /// 
  /// // Attention-grabbing button:
  /// TransitionAnimations.glowPulse(
  ///   child: ActionButton(),
  ///   glowColor: Colors.orange,
  ///   pulseIntensity: 0.8,
  /// )
  /// ```
  static Widget glowPulse({
    required Widget child,
    Color glowColor = Colors.cyan,
    Duration duration = const Duration(milliseconds: 1500),
    double pulseIntensity = 0.5,
    double blurRadius = 10.0,
  }) {
    return _GlowPulseWrapper(
      child: child,
      glowColor: glowColor,
      duration: duration,
      pulseIntensity: pulseIntensity,
      blurRadius: blurRadius,
    );
  }

  /// Creates a slide up spring transition for pop-ups and notifications.
  /// 
  /// Great for streak reminders, notifications, or bottom sheets.
  /// 
  /// Example usage:
  /// ```dart
  /// // Slide up notification:
  /// TransitionAnimations.slideUpSpring(
  ///   child: StreakReminder(),
  ///   slideDistance: 100.0,
  /// )
  /// 
  /// // Bottom sheet style:
  /// TransitionAnimations.slideUpSpring(
  ///   child: SettingsPanel(),
  ///   curve: Curves.bounceOut,
  /// )
  /// ```
  static Widget slideUpSpring({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
    Curve curve = Curves.elasticOut,
    double slideDistance = 50.0,
    bool autoStart = true,
  }) {
    return _SlideUpSpringTransition(
      child: child,
      duration: duration,
      curve: curve,
      slideDistance: slideDistance,
      autoStart: autoStart,
    );
  }

  /// Utility method to create a custom animation controller with standard settings.
  /// 
  /// Useful for building custom animations that follow app conventions.
  static AnimationController createController({
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 400),
    Duration? reverseDuration,
    String? debugLabel,
  }) {
    return AnimationController(
      duration: duration,
      reverseDuration: reverseDuration,
      debugLabel: debugLabel,
      vsync: vsync,
    );
  }

  /// Utility to create a curved animation with common settings.
  static CurvedAnimation createCurvedAnimation({
    required Animation<double> parent,
    Curve curve = Curves.easeInOut,
    Curve? reverseCurve,
  }) {
    return CurvedAnimation(
      parent: parent,
      curve: curve,
      reverseCurve: reverseCurve,
    );
  }

  // Default confetti colors
  static const List<Color> _defaultConfettiColors = [
    Colors.yellow,
    Colors.orange,
    Colors.pink,
    Colors.purple,
    Colors.cyan,
    Colors.lime,
    Colors.red,
    Colors.blue,
  ];
}

// Internal implementation widgets

class _FadeScaleTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double initialScale;

  const _FadeScaleTransition({
    required this.child,
    required this.duration,
    required this.curve,
    required this.initialScale,
  });

  @override
  State<_FadeScaleTransition> createState() => _FadeScaleTransitionState();
}

class _FadeScaleTransitionState extends State<_FadeScaleTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    
    _scaleAnimation = Tween<double>(
      begin: widget.initialScale,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.6, curve: widget.curve),
    ));
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _ConfettiBurstOverlay extends StatefulWidget {
  final int particleCount;
  final List<Color> colors;
  final Duration duration;
  final Offset? origin;

  const _ConfettiBurstOverlay({
    required this.particleCount,
    required this.colors,
    required this.duration,
    this.origin,
  });

  @override
  State<_ConfettiBurstOverlay> createState() => _ConfettiBurstOverlayState();
}

class _ConfettiBurstOverlayState extends State<_ConfettiBurstOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _generateParticles();
    _controller.forward();
  }

  void _generateParticles() {
    _particles = List.generate(widget.particleCount, (index) {
      return _ConfettiParticle(
        color: widget.colors[math.Random().nextInt(widget.colors.length)],
        size: math.Random().nextDouble() * 8 + 4,
        velocity: Offset(
          (math.Random().nextDouble() - 0.5) * 400,
          -math.Random().nextDouble() * 200 - 100,
        ),
        rotation: math.Random().nextDouble() * math.pi * 2,
        rotationSpeed: (math.Random().nextDouble() - 0.5) * 10,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
            origin: widget.origin,
          ),
        );
      },
    );
  }
}

class _ShakeEffectWrapper extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final Duration duration;
  final double intensity;
  final int shakeCount;

  const _ShakeEffectWrapper({
    required this.child,
    required this.trigger,
    required this.duration,
    required this.intensity,
    required this.shakeCount,
  });

  @override
  State<_ShakeEffectWrapper> createState() => _ShakeEffectWrapperState();
}

class _ShakeEffectWrapperState extends State<_ShakeEffectWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    
    if (widget.trigger) {
      _startShake();
    }
  }

  @override
  void didUpdateWidget(_ShakeEffectWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _startShake();
    }
  }

  void _startShake() {
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shakeValue = math.sin(_shakeAnimation.value * math.pi * widget.shakeCount * 2);
        return Transform.translate(
          offset: Offset(shakeValue * widget.intensity, 0),
          child: widget.child,
        );
      },
    );
  }
}

class _GlowPulseWrapper extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final Duration duration;
  final double pulseIntensity;
  final double blurRadius;

  const _GlowPulseWrapper({
    required this.child,
    required this.glowColor,
    required this.duration,
    required this.pulseIntensity,
    required this.blurRadius,
  });

  @override
  State<_GlowPulseWrapper> createState() => _GlowPulseWrapperState();
}

class _GlowPulseWrapperState extends State<_GlowPulseWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _glowAnimation = Tween<double>(
      begin: 1.0 - widget.pulseIntensity,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.3 * _glowAnimation.value),
                blurRadius: widget.blurRadius,
                spreadRadius: 2,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _SlideUpSpringTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double slideDistance;
  final bool autoStart;

  const _SlideUpSpringTransition({
    required this.child,
    required this.duration,
    required this.curve,
    required this.slideDistance,
    required this.autoStart,
  });

  @override
  State<_SlideUpSpringTransition> createState() => _SlideUpSpringTransitionState();
}

class _SlideUpSpringTransitionState extends State<_SlideUpSpringTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideDistance),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    
    if (widget.autoStart) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

// Helper classes for confetti
class _ConfettiParticle {
  final Color color;
  final double size;
  final Offset velocity;
  final double rotation;
  final double rotationSpeed;

  _ConfettiParticle({
    required this.color,
    required this.size,
    required this.velocity,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;
  final Offset? origin;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
    this.origin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = origin?.dx ?? size.width / 2;
    final centerY = origin?.dy ?? size.height / 2;

    for (var particle in particles) {
      final x = centerX + (particle.velocity.dx * progress);
      final y = centerY + (particle.velocity.dy * progress) + (200 * progress * progress);

      if (x < -50 || x > size.width + 50 || y > size.height + 50) continue;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: 1.0 - progress)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + (particle.rotationSpeed * progress));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size),
          Radius.circular(particle.size / 4),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Extension methods for common animation patterns
extension AnimationControllerExtensions on AnimationController {
  /// Animate with a completion callback
  Future<void> forwardWithCallback(VoidCallback onComplete) async {
    await forward();
    onComplete();
  }

  /// Repeat animation a specific number of times
  Future<void> repeatTimes(int count) async {
    for (int i = 0; i < count; i++) {
      await forward();
      await reverse();
    }
  }
}

/// Common animation curves used throughout the app
class AppCurves {
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve backOut = Curves.easeOutBack;
  static const Curve snappy = Curves.easeOutCubic;
  static const Curve smooth = Curves.easeInOutCubic;
}