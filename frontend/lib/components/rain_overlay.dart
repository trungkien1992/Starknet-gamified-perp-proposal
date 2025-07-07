import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../app/theme/street_cred_theme.dart';

class RainOverlay extends StatefulWidget {
  final double intensity; // 0.0 to 1.0
  final double windSpeed; // km/h, affects rain angle
  final bool enableNeonReflections;
  final Widget? child;

  const RainOverlay({
    Key? key,
    this.intensity = 0.5,
    this.windSpeed = 0.0,
    this.enableNeonReflections = true,
    this.child,
  }) : super(key: key);

  @override
  State<RainOverlay> createState() => _RainOverlayState();
}

class _RainOverlayState extends State<RainOverlay>
    with TickerProviderStateMixin {
  late AnimationController _rainController;
  late AnimationController _reflectionController;
  final List<RainDrop> _rainDrops = [];
  final List<NeonReflection> _reflections = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    
    _rainController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _reflectionController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _generateRainDrops();
    if (widget.enableNeonReflections) {
      _generateNeonReflections();
    }
  }

  @override
  void didUpdateWidget(RainOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Regenerate particles if intensity changed significantly
    if ((widget.intensity - oldWidget.intensity).abs() > 0.2) {
      _generateRainDrops();
    }
  }

  void _generateRainDrops() {
    _rainDrops.clear();
    
    if (widget.intensity <= 0) return;

    // Number of raindrops based on intensity
    final dropCount = (widget.intensity * 150).round().clamp(20, 200);
    
    for (int i = 0; i < dropCount; i++) {
      _rainDrops.add(RainDrop(
        startX: _random.nextDouble(),
        startY: _random.nextDouble(),
        speed: 0.8 + _random.nextDouble() * 0.4, // 0.8-1.2
        length: 0.02 + _random.nextDouble() * 0.03, // 0.02-0.05
        opacity: 0.3 + _random.nextDouble() * 0.4, // 0.3-0.7
        windOffset: widget.windSpeed / 50, // Convert wind to angle offset
      ));
    }
  }

  void _generateNeonReflections() {
    _reflections.clear();
    
    if (!widget.enableNeonReflections || widget.intensity <= 0) return;

    // Hong Kong neon colors for reflections
    final neonColors = [
      StreetCredTheme.neonPink,
      StreetCredTheme.neonBlue,
      StreetCredTheme.neonGreen,
      StreetCredTheme.neonYellow,
      StreetCredTheme.electricBlue,
    ];

    // Generate fewer, more impactful reflections
    final reflectionCount = (widget.intensity * 8).round().clamp(3, 12);
    
    for (int i = 0; i < reflectionCount; i++) {
      _reflections.add(NeonReflection(
        x: _random.nextDouble(),
        y: 0.6 + _random.nextDouble() * 0.4, // Bottom 40% of screen
        color: neonColors[_random.nextInt(neonColors.length)],
        intensity: 0.2 + _random.nextDouble() * 0.3,
        pulseSpeed: 0.5 + _random.nextDouble() * 1.0,
        width: 0.15 + _random.nextDouble() * 0.25,
      ));
    }
  }

  @override
  void dispose() {
    _rainController.dispose();
    _reflectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.intensity <= 0) {
      return widget.child ?? const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Child content first
        if (widget.child != null) widget.child!,
        
        // Rain overlay
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _rainController,
            builder: (context, child) {
              return CustomPaint(
                painter: RainPainter(
                  rainDrops: _rainDrops,
                  animationValue: _rainController.value,
                  intensity: widget.intensity,
                ),
              );
            },
          ),
        ),

        // Neon reflections overlay
        if (widget.enableNeonReflections)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _reflectionController,
              builder: (context, child) {
                return CustomPaint(
                  painter: NeonReflectionPainter(
                    reflections: _reflections,
                    animationValue: _reflectionController.value,
                    rainIntensity: widget.intensity,
                  ),
                );
              },
            ),
          ),

        // Atmospheric overlay for heavy rain
        if (widget.intensity > 0.7)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class RainDrop {
  final double startX;
  final double startY;
  final double speed;
  final double length;
  final double opacity;
  final double windOffset;

  RainDrop({
    required this.startX,
    required this.startY,
    required this.speed,
    required this.length,
    required this.opacity,
    required this.windOffset,
  });

  Offset getPosition(double animationValue, Size screenSize) {
    final progress = (animationValue + startY) % 1.0;
    final x = (startX + windOffset * progress) * screenSize.width;
    final y = progress * screenSize.height;
    return Offset(x, y);
  }

  Offset getEndPosition(double animationValue, Size screenSize) {
    final position = getPosition(animationValue, screenSize);
    return Offset(
      position.dx + windOffset * 10,
      position.dy + length * screenSize.height,
    );
  }
}

class NeonReflection {
  final double x;
  final double y;
  final Color color;
  final double intensity;
  final double pulseSpeed;
  final double width;

  NeonReflection({
    required this.x,
    required this.y,
    required this.color,
    required this.intensity,
    required this.pulseSpeed,
    required this.width,
  });
}

class RainPainter extends CustomPainter {
  final List<RainDrop> rainDrops;
  final double animationValue;
  final double intensity;

  RainPainter({
    required this.rainDrops,
    required this.animationValue,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (rainDrops.isEmpty) return;

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final drop in rainDrops) {
      final startPos = drop.getPosition(animationValue, size);
      final endPos = drop.getEndPosition(animationValue, size);

      // Skip drops that are off-screen
      if (startPos.dy > size.height || endPos.dy < 0) continue;

      paint
        ..color = const Color(0xFF7DF9FF).withValues(alpha: 
          drop.opacity * intensity,
        )
        ..strokeWidth = 1.0 + intensity;

      canvas.drawLine(startPos, endPos, paint);

      // Add subtle glow for heavier rain
      if (intensity > 0.6) {
        paint
          ..color = const Color(0xFF7DF9FF).withValues(alpha: 
            drop.opacity * intensity * 0.3,
          )
          ..strokeWidth = 2.0 + intensity;
        canvas.drawLine(startPos, endPos, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant RainPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.intensity != intensity ||
           oldDelegate.rainDrops.length != rainDrops.length;
  }
}

class NeonReflectionPainter extends CustomPainter {
  final List<NeonReflection> reflections;
  final double animationValue;
  final double rainIntensity;

  NeonReflectionPainter({
    required this.reflections,
    required this.animationValue,
    required this.rainIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (reflections.isEmpty || rainIntensity <= 0.2) return;

    for (final reflection in reflections) {
      final centerX = reflection.x * size.width;
      final centerY = reflection.y * size.height;
      
      // Pulsing effect
      final pulseValue = 0.7 + 0.3 * math.sin(
        animationValue * 2 * math.pi * reflection.pulseSpeed,
      );
      
      final reflectionWidth = reflection.width * size.width * pulseValue;
      final reflectionHeight = 8.0 * rainIntensity;

      // Create gradient for neon reflection
      final gradient = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          reflection.color.withValues(alpha: 
            reflection.intensity * rainIntensity * pulseValue,
          ),
          reflection.color.withValues(alpha: 0.1 * rainIntensity),
          Colors.transparent,
        ],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCenter(
            center: Offset(centerX, centerY),
            width: reflectionWidth,
            height: reflectionHeight,
          ),
        );

      // Draw reflection as ellipse
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: reflectionWidth,
          height: reflectionHeight,
        ),
        paint,
      );

      // Add extra glow for bright reflections
      if (reflection.intensity > 0.4) {
        final glowPaint = Paint()
          ..color = reflection.color.withValues(alpha: 
            0.1 * rainIntensity * pulseValue,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(centerX, centerY),
            width: reflectionWidth * 1.5,
            height: reflectionHeight * 1.5,
          ),
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant NeonReflectionPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.rainIntensity != rainIntensity;
  }
}