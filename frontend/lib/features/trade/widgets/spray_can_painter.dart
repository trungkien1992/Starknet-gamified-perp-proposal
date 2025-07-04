import 'dart:math' as math;
import 'package:flutter/material.dart';

class SprayCanPainter extends CustomPainter {
  final List<Offset> points;
  final Color sprayColor;
  final double strokeWidth;
  final double intensity;
  final bool isActive;

  SprayCanPainter({
    required this.points,
    required this.sprayColor,
    required this.strokeWidth,
    this.intensity = 1.0,
    this.isActive = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Create main spray paint path
    final mainPaint = Paint()
      ..color = sprayColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    // Create glow effect
    final glowPaint = Paint()
      ..color = sprayColor.withValues(alpha: 0.3)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth * 2
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    // Draw the main spray paint path
    final path = _createSprayPath();
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, mainPaint);

    // Add spray particles if active
    if (isActive && points.isNotEmpty) {
      _drawSprayParticles(canvas, points.last);
    }
  }

  Path _createSprayPath() {
    if (points.length < 2) {
      return Path();
    }

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    // Create smooth curve through points
    for (int i = 1; i < points.length; i++) {
      final current = points[i];

      // Add some randomness to simulate spray paint texture
      final random = math.Random(i);
      final offsetX = (random.nextDouble() - 0.5) * 2 * intensity;
      final offsetY = (random.nextDouble() - 0.5) * 2 * intensity;

      path.lineTo(current.dx + offsetX, current.dy + offsetY);
    }

    return path;
  }

  void _drawSprayParticles(Canvas canvas, Offset center) {
    final random = math.Random();
    final particleCount = (10 * intensity).round();

    for (int i = 0; i < particleCount; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = random.nextDouble() * 20 * intensity;
      final particleSize = random.nextDouble() * 3 + 1;

      final particleX = center.dx + math.cos(angle) * distance;
      final particleY = center.dy + math.sin(angle) * distance;

      final particlePaint = Paint()
        ..color = sprayColor.withValues(alpha: random.nextDouble() * 0.8 + 0.2)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particleX, particleY),
        particleSize,
        particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SprayCanPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.sprayColor != sprayColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.intensity != intensity ||
        oldDelegate.isActive != isActive;
  }
}

class SprayPaintTrail {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final double intensity;
  final DateTime timestamp;

  SprayPaintTrail({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.intensity = 1.0,
    required this.timestamp,
  });

  bool get isExpired {
    final age = DateTime.now().difference(timestamp);
    return age.inSeconds > 5; // Fade after 5 seconds
  }
}
