import 'package:flutter/material.dart';
import '../../../app/theme/street_cred_theme.dart';
import 'dart:math' as math;

class BrandSymbol extends StatefulWidget {
  final double size;
  final Color? primaryColor;
  final Color? accentColor;
  final bool animated;
  final bool isAppIcon;

  const BrandSymbol({
    Key? key,
    this.size = 60,
    this.primaryColor,
    this.accentColor,
    this.animated = true,
    this.isAppIcon = false,
  }) : super(key: key);

  @override
  State<BrandSymbol> createState() => _BrandSymbolState();
}

class _BrandSymbolState extends State<BrandSymbol>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _shimmerController;
  late Animation<double> _glowAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    if (widget.animated) {
      _glowController = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      );

      _shimmerController = AnimationController(
        duration: const Duration(seconds: 3),
        vsync: this,
      );

      _glowAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
      );

      _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
      );

      _glowController.repeat(reverse: true);
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    if (widget.animated) {
      _glowController.dispose();
      _shimmerController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    // Create container with dark background for app icon style
    final container = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: widget.isAppIcon ? const Color(0xFF1A1A1A) : null,
        borderRadius: widget.isAppIcon
            ? BorderRadius.circular(size * 0.2) // 20% border radius
            : null,
      ),
      child: !widget.animated
          ? CustomPaint(
              size: Size(size, size),
              painter: NeonGraffitiTrendPainter(
                size: size,
                glowIntensity: 1.0,
                shimmerProgress: 0.0,
                isAppIcon: widget.isAppIcon,
              ),
            )
          : AnimatedBuilder(
              animation: Listenable.merge([_glowAnimation, _shimmerAnimation]),
              builder: (context, child) {
                return CustomPaint(
                  size: Size(size, size),
                  painter: NeonGraffitiTrendPainter(
                    size: size,
                    glowIntensity: _glowAnimation.value,
                    shimmerProgress: _shimmerAnimation.value,
                    isAppIcon: widget.isAppIcon,
                  ),
                );
              },
            ),
    );

    if (!widget.animated || widget.isAppIcon) {
      return container;
    }

    // Add outer glow for non-app-icon versions
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFFFF00FF,
                ).withValues(alpha: _glowAnimation.value * 0.4),
                blurRadius: size * 0.3 * _glowAnimation.value,
                spreadRadius: size * 0.05 * _glowAnimation.value,
              ),
              BoxShadow(
                color: const Color(
                  0xFF00FFFF,
                ).withValues(alpha: _glowAnimation.value * 0.3),
                blurRadius: size * 0.2 * _glowAnimation.value,
                spreadRadius: size * 0.02 * _glowAnimation.value,
              ),
            ],
          ),
          child: container,
        );
      },
    );
  }
}

class NeonGraffitiTrendPainter extends CustomPainter {
  final double size;
  final double glowIntensity;
  final double shimmerProgress;
  final bool isAppIcon;

  NeonGraffitiTrendPainter({
    required this.size,
    required this.glowIntensity,
    required this.shimmerProgress,
    required this.isAppIcon,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint();
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);

    // Neon gradient colors: #FF00FF -> #8A2BE2 -> #00FFFF
    final neonGradient = LinearGradient(
      colors: [
        const Color(0xFFFF00FF), // Magenta/Pink
        const Color(0xFF8A2BE2), // Blue Violet
        const Color(0xFF00FFFF), // Cyan
      ],
    );

    // Draw the main trend line
    _drawTrendLine(canvas, canvasSize, paint, neonGradient);

    // Draw spray splatter effect
    _drawSpraySplatter(canvas, canvasSize, paint, neonGradient);
  }

  void _drawTrendLine(
    Canvas canvas,
    Size canvasSize,
    Paint paint,
    LinearGradient gradient,
  ) {
    // Calculate line dimensions and position
    final lineLength = canvasSize.width * 0.6;
    final lineWidth = canvasSize.width * 0.08;
    final startX = canvasSize.width * 0.15;
    final startY = canvasSize.height * 0.75;
    final endX =
        startX + lineLength * math.cos(-math.pi / 6); // 30 degree upward slope
    final endY = startY + lineLength * math.sin(-math.pi / 6);

    // Create gradient shader
    paint.shader = gradient.createShader(
      Rect.fromPoints(Offset(startX, startY), Offset(endX, endY)),
    );

    // Draw glow effect
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = lineWidth * 1.5;
    paint.strokeCap = StrokeCap.round;
    paint.maskFilter = MaskFilter.blur(
      BlurStyle.normal,
      lineWidth * 0.8 * glowIntensity,
    );

    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);

    // Draw solid line on top
    paint.strokeWidth = lineWidth;
    paint.maskFilter = null;
    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);

    // Add shimmer effect
    if (shimmerProgress > 0) {
      _drawShimmer(
        canvas,
        canvasSize,
        paint,
        startX,
        startY,
        endX,
        endY,
        lineWidth,
      );
    }
  }

  void _drawShimmer(
    Canvas canvas,
    Size canvasSize,
    Paint paint,
    double startX,
    double startY,
    double endX,
    double endY,
    double lineWidth,
  ) {
    final shimmerPosition = shimmerProgress;
    final shimmerX = startX + (endX - startX) * shimmerPosition;
    final shimmerY = startY + (endY - startY) * shimmerPosition;

    // Create bright shimmer point
    paint.shader =
        RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.8),
            Colors.white.withValues(alpha: 0.4),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 1.0],
        ).createShader(
          Rect.fromCircle(
            center: Offset(shimmerX, shimmerY),
            radius: lineWidth * 1.5,
          ),
        );

    paint.style = PaintingStyle.fill;
    paint.maskFilter = MaskFilter.blur(BlurStyle.normal, lineWidth * 0.5);

    canvas.drawCircle(Offset(shimmerX, shimmerY), lineWidth * 1.2, paint);

    paint.maskFilter = null;
  }

  void _drawSpraySplatter(
    Canvas canvas,
    Size canvasSize,
    Paint paint,
    LinearGradient gradient,
  ) {
    // Position splatter at the upper right end of the trend line
    final lineLength = canvasSize.width * 0.6;
    final startX = canvasSize.width * 0.15;
    final startY = canvasSize.height * 0.75;
    final endX = startX + lineLength * math.cos(-math.pi / 6);
    final endY = startY + lineLength * math.sin(-math.pi / 6);

    // Create multiple angular fragments
    final fragmentCount = 8;
    final random = math.Random(42); // Fixed seed for consistent pattern

    for (int i = 0; i < fragmentCount; i++) {
      final angle = (i / fragmentCount) * 2 * math.pi + math.pi / 4;
      final distance = canvasSize.width * (0.08 + random.nextDouble() * 0.12);
      final fragmentSize =
          canvasSize.width * (0.03 + random.nextDouble() * 0.04);

      final fragmentX = endX + distance * math.cos(angle);
      final fragmentY = endY + distance * math.sin(angle);

      // Create angular fragment shape
      _drawAngularFragment(
        canvas,
        fragmentX,
        fragmentY,
        fragmentSize,
        angle,
        paint,
        gradient,
      );
    }
  }

  void _drawAngularFragment(
    Canvas canvas,
    double x,
    double y,
    double size,
    double angle,
    Paint paint,
    LinearGradient gradient,
  ) {
    // Create angular fragment path
    final path = Path();
    final vertices = 6; // Hexagonal fragments

    for (int i = 0; i < vertices; i++) {
      final vertexAngle = (i / vertices) * 2 * math.pi + angle;
      final radius =
          size * (0.5 + math.sin(i.toDouble()) * 0.3); // Irregular shape
      final vx = x + radius * math.cos(vertexAngle);
      final vy = y + radius * math.sin(vertexAngle);

      if (i == 0) {
        path.moveTo(vx, vy);
      } else {
        path.lineTo(vx, vy);
      }
    }
    path.close();

    // Apply gradient shader
    paint.shader = gradient.createShader(
      Rect.fromCircle(center: Offset(x, y), radius: size),
    );

    // Draw glow
    paint.style = PaintingStyle.fill;
    paint.maskFilter = MaskFilter.blur(
      BlurStyle.normal,
      size * 0.5 * glowIntensity,
    );
    canvas.drawPath(path, paint);

    // Draw solid fragment
    paint.maskFilter = null;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(NeonGraffitiTrendPainter oldDelegate) {
    return oldDelegate.glowIntensity != glowIntensity ||
        oldDelegate.shimmerProgress != shimmerProgress ||
        oldDelegate.size != size ||
        oldDelegate.isAppIcon != isAppIcon;
  }
}
