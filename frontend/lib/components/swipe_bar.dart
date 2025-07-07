import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class SwipeBar extends StatefulWidget {
  final Function(String direction, int leverage) onSwipeComplete;
  final double width;
  final double height;

  const SwipeBar({
    super.key,
    required this.onSwipeComplete,
    this.width = 80.0,
    this.height = 300.0,
  });

  @override
  State<SwipeBar> createState() => _SwipeBarState();
}

class _SwipeBarState extends State<SwipeBar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _trailController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _trailAnimation;

  double _currentSwipe = 0.0;
  bool _isActive = false;
  List<SwipePoint> _trailPoints = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _trailController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));
    _trailAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _trailController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _trailController.dispose();
    super.dispose();
  }

  double get _leverage {
    double normalizedSwipe = _currentSwipe.abs() / (widget.height / 2);
    return math.max(1.0, math.min(10.0, normalizedSwipe * 10));
  }

  String get _direction {
    return _currentSwipe > 0 ? "short" : "long";
  }

  Color get _trailColor {
    return _currentSwipe > 0 
        ? Colors.red.withValues(alpha: 0.8) 
        : Colors.green.withValues(alpha: 0.8);
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isActive = true;
      _trailPoints.clear();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentSwipe += details.delta.dy;
      _currentSwipe = math.max(
        -widget.height / 2,
        math.min(widget.height / 2, _currentSwipe),
      );
      
      _trailPoints.add(SwipePoint(
        offset: Offset(widget.width / 2, widget.height / 2 + _currentSwipe),
        timestamp: DateTime.now(),
      ));
      
      if (_trailPoints.length > 20) {
        _trailPoints.removeAt(0);
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentSwipe.abs() > 20) {
      HapticFeedback.lightImpact();
      _pulseController.forward().then((_) {
        _pulseController.reverse();
      });
      
      widget.onSwipeComplete(_direction, _leverage.round());
    }
    
    _trailController.forward().then((_) {
      _trailController.reset();
      setState(() {
        _trailPoints.clear();
      });
    });
    
    setState(() {
      _isActive = false;
      _currentSwipe = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _trailAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: _isActive ? _trailColor : Colors.grey[700]!,
                width: 2,
              ),
            ),
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Stack(
                children: [
                  // Background grid
                  _buildBackground(),
                  
                  // Spray paint trail
                  if (_trailPoints.isNotEmpty)
                    CustomPaint(
                      size: Size(widget.width, widget.height),
                      painter: SprayPaintPainter(
                        points: _trailPoints,
                        color: _trailColor,
                        fadeAnimation: _trailAnimation,
                      ),
                    ),
                  
                  // Power bar
                  _buildPowerBar(),
                  
                  // Center indicator
                  _buildCenterIndicator(),
                  
                  // Dynamic labels
                  _buildLabels(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackground() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green.withValues(alpha: 0.1),
            Colors.grey[900]!,
            Colors.red.withValues(alpha: 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerBar() {
    double powerLevel = _currentSwipe.abs() / (widget.height / 2);
    
    return Positioned(
      left: 8,
      top: 0,
      bottom: 0,
      child: Container(
        width: 6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: Colors.grey[800],
        ),
        child: Align(
          alignment: _currentSwipe > 0 
              ? Alignment.topCenter 
              : Alignment.bottomCenter,
          child: Container(
            width: 6,
            height: powerLevel * (widget.height / 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(
                begin: _currentSwipe > 0 
                    ? Alignment.bottomCenter 
                    : Alignment.topCenter,
                end: _currentSwipe > 0 
                    ? Alignment.topCenter 
                    : Alignment.bottomCenter,
                colors: [
                  _trailColor.withValues(alpha: 0.3),
                  _trailColor,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterIndicator() {
    return Positioned(
      left: 0,
      right: 0,
      top: widget.height / 2 - 15,
      child: Container(
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Icon(
            Icons.drag_handle,
            color: Colors.white54,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildLabels() {
    if (!_isActive || _currentSwipe.abs() < 10) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 8,
      top: _currentSwipe > 0 ? 20 : null,
      bottom: _currentSwipe > 0 ? null : 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _trailColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _direction.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_leverage.round()}x',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SwipePoint {
  final Offset offset;
  final DateTime timestamp;

  SwipePoint({required this.offset, required this.timestamp});
}

class SprayPaintPainter extends CustomPainter {
  final List<SwipePoint> points;
  final Color color;
  final Animation<double> fadeAnimation;

  SprayPaintPainter({
    required this.points,
    required this.color,
    required this.fadeAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.8 * (1 - fadeAnimation.value))
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final sprayPaint = Paint()
      ..color = color.withValues(alpha: 0.4 * (1 - fadeAnimation.value))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      
      double alpha = (i / points.length) * (1 - fadeAnimation.value);
      paint.color = color.withValues(alpha: alpha * 0.8);
      
      canvas.drawLine(current.offset, next.offset, paint);
      
      for (int j = 0; j < 5; j++) {
        double offsetX = (math.Random().nextDouble() - 0.5) * 12;
        double offsetY = (math.Random().nextDouble() - 0.5) * 12;
        
        sprayPaint.color = color.withValues(alpha: alpha * 0.3);
        canvas.drawCircle(
          Offset(current.offset.dx + offsetX, current.offset.dy + offsetY),
          math.Random().nextDouble() * 2 + 1,
          sprayPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}