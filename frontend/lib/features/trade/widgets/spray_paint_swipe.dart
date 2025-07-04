import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/street_cred_theme.dart';
import 'spray_can_painter.dart';

class SprayPaintSwipe extends StatefulWidget {
  final Function(double leverage, String direction) onTradeExecuted;
  final double currentInk;
  final bool isEnabled;

  const SprayPaintSwipe({
    Key? key,
    required this.onTradeExecuted,
    required this.currentInk,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  State<SprayPaintSwipe> createState() => _SprayPaintSwipeState();
}

class _SprayPaintSwipeState extends State<SprayPaintSwipe>
    with TickerProviderStateMixin {
  List<Offset> currentPoints = [];
  List<SprayPaintTrail> trails = [];
  Color currentColor = StreetCredTheme.neutralColor;
  double currentStrokeWidth = 5.0;
  double currentIntensity = 1.0;
  bool isSpraying = false;
  String currentDirection = 'NEUTRAL';

  late AnimationController _sprayController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _sprayController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _sprayController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateColorBasedOnDirection(DragUpdateDetails details) {
    final deltaY = details.delta.dy;
    final deltaX = details.delta.dx;

    if (deltaY.abs() > deltaX.abs()) {
      if (deltaY < -5) {
        setState(() {
          currentColor = StreetCredTheme.longColor;
          currentDirection = 'LONG';
        });
      } else if (deltaY > 5) {
        setState(() {
          currentColor = StreetCredTheme.shortColor;
          currentDirection = 'SHORT';
        });
      }
    } else {
      setState(() {
        currentColor = StreetCredTheme.neutralColor;
        currentDirection = 'NEUTRAL';
      });
    }
  }

  void _increaseLeverage() {
    setState(() {
      currentStrokeWidth = (currentStrokeWidth + 0.5).clamp(5.0, 25.0);
      currentIntensity = (currentIntensity + 0.1).clamp(1.0, 3.0);
    });
  }

  void _triggerSprayEffect() {
    _sprayController.forward().then((_) {
      _sprayController.reverse();
    });

    // Add haptic feedback
    HapticFeedback.mediumImpact();

    // Calculate leverage based on stroke width and intensity
    final leverage = (currentStrokeWidth - 5.0) / 20.0 * currentIntensity;

    // Execute trade
    widget.onTradeExecuted(leverage, currentDirection);
  }

  void _clearExpiredTrails() {
    setState(() {
      trails.removeWhere((trail) => trail.isExpired);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: StreetCredTheme.sprayCanDecoration,
      child: Stack(
        children: [
          // Background spray paint trails
          ...trails.map(
            (trail) => CustomPaint(
              size: Size.infinite,
              painter: SprayCanPainter(
                points: trail.points,
                sprayColor: trail.color,
                strokeWidth: trail.strokeWidth,
                intensity: trail.intensity,
                isActive: false,
              ),
            ),
          ),

          // Current spray paint
          CustomPaint(
            size: Size.infinite,
            painter: SprayCanPainter(
              points: currentPoints,
              sprayColor: currentColor,
              strokeWidth: currentStrokeWidth,
              intensity: currentIntensity,
              isActive: isSpraying,
            ),
          ),

          // Spray can nozzle indicator
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: currentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: currentColor.withValues(alpha: 0.6),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Direction indicator
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                currentDirection,
                style: StreetCredTheme.graffitiSubtitle.copyWith(
                  color: currentColor,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // Leverage indicator
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: currentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: currentColor, width: 1),
                ),
                child: Text(
                  '${((currentStrokeWidth - 5.0) / 20.0 * 100).round()}%',
                  style: StreetCredTheme.graffitiBody.copyWith(
                    color: currentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Gesture detector for spray painting
          GestureDetector(
            onPanStart: (details) {
              if (!widget.isEnabled) return;

              setState(() {
                currentPoints = [details.localPosition];
                currentStrokeWidth = 5.0;
                currentIntensity = 1.0;
                isSpraying = true;
              });
            },
            onPanUpdate: (details) {
              if (!widget.isEnabled) return;

              setState(() {
                currentPoints = List.from(currentPoints)
                  ..add(details.localPosition);
                _updateColorBasedOnDirection(details);
                _increaseLeverage();
              });
            },
            onPanEnd: (details) {
              if (!widget.isEnabled) return;

              setState(() {
                isSpraying = false;

                // Save current trail
                if (currentPoints.length > 2) {
                  trails.add(
                    SprayPaintTrail(
                      points: List.from(currentPoints),
                      color: currentColor,
                      strokeWidth: currentStrokeWidth,
                      intensity: currentIntensity,
                      timestamp: DateTime.now(),
                    ),
                  );
                }

                // Clear current points
                currentPoints = [];
              });

              _triggerSprayEffect();

              // Clear expired trails after a delay
              Future.delayed(const Duration(seconds: 1), _clearExpiredTrails);
            },
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }
}
