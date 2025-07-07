import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/street_cred_theme.dart';
import 'dart:math' as math;

/// Callback signature for trade action
/// direction: 'LONG' or 'SHORT', leverage: 1.0-3.0
typedef OnTrade = void Function(String direction, double leverage);

class SwipeSprayGauge extends StatefulWidget {
  final OnTrade onTrade;
  final bool isEnabled;
  final bool isDemoMode;

  const SwipeSprayGauge({
    Key? key,
    required this.onTrade,
    this.isEnabled = true,
    this.isDemoMode = false,
  }) : super(key: key);

  @override
  State<SwipeSprayGauge> createState() => _SwipeSprayGaugeState();
}

class _SwipeSprayGaugeState extends State<SwipeSprayGauge>
    with TickerProviderStateMixin {
  List<Offset> sprayPath = [];
  String direction = 'NEUTRAL';
  double leverage = 1.0;
  bool isSpraying = false;
  Color sprayColor = StreetCredTheme.neutralColor;
  double sprayGlow = 0.0;
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late AnimationController _confettiController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _confettiAnimation;
  bool _showReactionFeedback = false;
  String _reactionEmoji = '';
  double _velocity = 0.0;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: 0.0,
      upperBound: 1.0,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );

    _confettiAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isEnabled) return;
    setState(() {
      sprayPath = [details.localPosition];
      isSpraying = true;
      direction = 'NEUTRAL';
      leverage = 1.0;
      sprayColor = StreetCredTheme.neutralColor;
      sprayGlow = 0.0;
    });
    HapticFeedback.selectionClick();
    _glowController.forward();
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (!widget.isEnabled) return;
    final Offset pos = details.localPosition;

    // Calculate velocity for more responsive feedback
    _velocity = details.delta.distance;

    setState(() {
      sprayPath = List.from(sprayPath)..add(pos);

      // Determine direction with velocity-based sensitivity
      final dy = pos.dy - sprayPath.first.dy;
      final sensitivity = math.max(
        15,
        30 - _velocity * 2,
      ); // More sensitive with faster swipes

      String newDirection = direction;
      if (dy < -sensitivity) {
        newDirection = 'LONG';
        sprayColor = StreetCredTheme.longColor;
        _reactionEmoji = '🚀';
      } else if (dy > sensitivity) {
        newDirection = 'SHORT';
        sprayColor = StreetCredTheme.shortColor;
        _reactionEmoji = '📉';
      } else {
        newDirection = 'NEUTRAL';
        sprayColor = StreetCredTheme.neutralColor;
        _reactionEmoji = '⚡';
      }

      // Trigger pulse animation on direction change
      if (direction != newDirection && newDirection != 'NEUTRAL') {
        _pulseController.forward().then((_) => _pulseController.reverse());
        HapticFeedback.lightImpact();
      }
      direction = newDirection;

      // Enhanced leverage calculation with velocity boost
      final dragDistance = (pos.dy - sprayPath.first.dy).abs();
      final maxDrag = constraints.maxHeight * 0.4; // Slightly more sensitive
      final velocityBonus = (_velocity / 20).clamp(0.0, 0.5);
      leverage = (1.0 + (dragDistance / maxDrag) * 2.0 + velocityBonus).clamp(
        1.0,
        3.0,
      );
      sprayGlow = (leverage - 1.0) / 2.0;
    });

    // Progressive haptic feedback based on leverage
    if (leverage > 2.5) {
      HapticFeedback.heavyImpact();
    } else if (leverage > 2.0) {
      HapticFeedback.mediumImpact();
    } else if (leverage > 1.5) {
      HapticFeedback.lightImpact();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isEnabled) return;

    setState(() {
      isSpraying = false;
      _showReactionFeedback = direction != 'NEUTRAL';
    });

    _glowController.reverse();

    // Enhanced completion feedback
    if (direction != 'NEUTRAL') {
      // Trigger celebration animations
      HapticFeedback.heavyImpact();
      _confettiController.forward();
      _pulseController.forward().then((_) => _pulseController.reverse());

      // Callback with enhanced feedback
      widget.onTrade(direction, leverage);

      // Show reaction feedback briefly
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _showReactionFeedback = false);
          _confettiController.reset();
        }
      });
    } else {
      // Light feedback for incomplete gesture
      HapticFeedback.selectionClick();
    }

    // Reset spray path with smooth transition
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => sprayPath = []);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: (details) => _onPanUpdate(details, constraints),
          onPanEnd: _onPanEnd,
          child: AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: 320,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: sprayColor.withValues(
                      alpha: 0.5 + 0.5 * _glowController.value,
                    ),
                    width: 3 + 6 * _glowController.value,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: sprayColor.withValues(
                        alpha: 0.3 + 0.4 * _glowController.value,
                      ),
                      blurRadius: 24 + 24 * _glowController.value,
                      spreadRadius: 2 + 4 * _glowController.value,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Spray trail
                    CustomPaint(
                      size: Size.infinite,
                      painter: _SprayTrailPainter(
                        points: sprayPath,
                        color: sprayColor,
                        glow: sprayGlow * _glowController.value,
                        isActive: isSpraying,
                        velocity: _velocity,
                      ),
                    ),

                    // Confetti effect overlay
                    if (_showReactionFeedback)
                      CustomPaint(
                        size: Size.infinite,
                        painter: _ConfettiPainter(
                          animation: _confettiAnimation.value,
                          color: sprayColor,
                        ),
                      ),

                    // Direction indicator with pulse animation
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_showReactionFeedback) ...[
                                    Text(
                                      _reactionEmoji,
                                      style: TextStyle(fontSize: 28),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    direction,
                                    style: StreetCredTheme.graffitiSubtitle
                                        .copyWith(
                                          color: sprayColor,
                                          fontSize:
                                              22 + 6 * _glowController.value,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Enhanced leverage indicator
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + 0.1 * _pulseAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: sprayColor.withValues(
                                    alpha: 0.18 + 0.12 * _glowController.value,
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: sprayColor,
                                    width: 1.5 + 1.5 * _glowController.value,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: sprayColor.withValues(
                                        alpha: 0.4 * _glowController.value,
                                      ),
                                      blurRadius: 8 + 8 * _glowController.value,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      leverage > 2.5
                                          ? Icons.flash_on
                                          : leverage > 2.0
                                          ? Icons.trending_up
                                          : Icons.adjust,
                                      color: sprayColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${((leverage - 1.0) / 2.0 * 100).round()}%',
                                      style: StreetCredTheme.graffitiBody
                                          .copyWith(
                                            color: sprayColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize:
                                                18 + 2 * _glowController.value,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Velocity indicator (for high-speed swipes)
                    if (_velocity > 10 && isSpraying)
                      Positioned(
                        top: 60,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.speed, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'FAST',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SprayTrailPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double glow;
  final bool isActive;
  final double velocity;

  _SprayTrailPainter({
    required this.points,
    required this.color,
    required this.glow,
    required this.isActive,
    this.velocity = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // Enhanced stroke with velocity consideration
    final velocityMultiplier = 1.0 + (velocity / 20).clamp(0.0, 0.8);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7 + 0.2 * glow)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (18 + 12 * glow) * velocityMultiplier
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        (8 + 8 * glow) * velocityMultiplier,
      )
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);

    // Enhanced spray particles with velocity effect
    if (isActive) {
      final random = math.Random();
      final particleCount = (12 + 12 * glow + velocity * 2).round();

      for (int i = 0; i < particleCount; i++) {
        final angle = random.nextDouble() * 2 * math.pi;
        final distance = random.nextDouble() * (18 + 18 * glow + velocity * 3);
        final px = points.last.dx + math.cos(angle) * distance;
        final py = points.last.dy + math.sin(angle) * distance;

        final particleSize = (2.5 + 2.5 * glow + velocity / 10).clamp(1.0, 8.0);
        final particlePaint = Paint()
          ..color = color.withValues(
            alpha: (0.18 + 0.18 * glow + velocity / 50).clamp(0.1, 0.8),
          )
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(px, py), particleSize, particlePaint);
      }

      // Add velocity streaks for fast swipes
      if (velocity > 15) {
        final streakPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

        for (int i = 0; i < 3; i++) {
          final offset = (i - 1) * 5.0;
          final streakPath = Path();
          if (points.length > 3) {
            final lastPoints = points.skip(points.length - 4).toList();
            streakPath.moveTo(
              lastPoints.first.dx + offset,
              lastPoints.first.dy,
            );
            for (final p in lastPoints.skip(1)) {
              streakPath.lineTo(p.dx + offset, p.dy);
            }
            canvas.drawPath(streakPath, streakPaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SprayTrailPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.glow != glow ||
        oldDelegate.isActive != isActive ||
        oldDelegate.velocity != velocity;
  }
}

// New confetti painter for celebration effect
class _ConfettiPainter extends CustomPainter {
  final double animation;
  final Color color;

  _ConfettiPainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for consistent animation
    final particleCount = 20;

    for (int i = 0; i < particleCount; i++) {
      final progress = (animation - (i / particleCount * 0.5)).clamp(0.0, 1.0);
      if (progress <= 0) continue;

      final startX = size.width * 0.5 + (random.nextDouble() - 0.5) * 100;
      final startY = size.height * 0.5 + (random.nextDouble() - 0.5) * 100;

      final endX = startX + (random.nextDouble() - 0.5) * 200 * progress;
      final endY =
          startY - 100 * progress + 50 * progress * progress; // Gravity effect

      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final size_particle = 3.0 + random.nextDouble() * 4.0;

      final particlePaint = Paint()
        ..color = [
          color,
          Colors.white,
          Colors.yellow,
          Colors.orange,
        ][i % 4].withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(endX, endY), size_particle, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
