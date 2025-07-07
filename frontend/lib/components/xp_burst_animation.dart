import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class XpBurstAnimation extends StatefulWidget {
  final int currentXp;
  final int xpGained;
  final int xpToLevelUp;
  final VoidCallback? onLevelUp;
  final double width;
  final double height;

  const XpBurstAnimation({
    super.key,
    required this.currentXp,
    required this.xpGained,
    required this.xpToLevelUp,
    this.onLevelUp,
    this.width = 300.0,
    this.height = 60.0,
  });

  @override
  State<XpBurstAnimation> createState() => _XpBurstAnimationState();
}

class _XpBurstAnimationState extends State<XpBurstAnimation>
    with TickerProviderStateMixin {
  late AnimationController _fillController;
  late AnimationController _glowController;
  late AnimationController _popupController;
  late AnimationController _levelUpController;
  late AnimationController _confettiController;

  late Animation<double> _fillAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _popupAnimation;
  late Animation<double> _levelUpScaleAnimation;
  late Animation<double> _levelUpOpacityAnimation;
  late Animation<double> _confettiAnimation;

  bool _showLevelUp = false;
  bool _hasLeveledUp = false;
  List<ConfettiParticle> _confettiParticles = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimation();
  }

  void _initializeAnimations() {
    _fillController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _popupController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _levelUpController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fillAnimation = Tween<double>(
      begin: widget.currentXp.toDouble(),
      end: (widget.currentXp + widget.xpGained).toDouble(),
    ).animate(CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _popupAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _popupController,
      curve: Curves.elasticOut,
    ));

    _levelUpScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _levelUpController,
      curve: Curves.elasticOut,
    ));

    _levelUpOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _levelUpController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _confettiAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    ));
  }

  void _startAnimation() {
    _fillController.forward();
    _glowController.repeat(reverse: true);
    _popupController.forward();

    _fillController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkLevelUp();
      }
    });
  }

  void _checkLevelUp() {
    if (widget.currentXp + widget.xpGained >= widget.xpToLevelUp && !_hasLeveledUp) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showLevelUp = true;
            _hasLeveledUp = true;
          });
          _generateConfetti();
          _levelUpController.forward();
          _confettiController.forward();
          HapticFeedback.mediumImpact();
          widget.onLevelUp?.call();
        }
      });
    }
  }

  void _generateConfetti() {
    _confettiParticles = List.generate(25, (index) {
      return ConfettiParticle(
        position: Offset(widget.width / 2, widget.height / 2),
        velocity: Offset(
          (math.Random().nextDouble() - 0.5) * 300,
          -math.Random().nextDouble() * 150 - 50,
        ),
        color: _getRandomConfettiColor(),
        size: math.Random().nextDouble() * 6 + 3,
        rotation: math.Random().nextDouble() * math.pi * 2,
        rotationSpeed: (math.Random().nextDouble() - 0.5) * 8,
      );
    });
  }

  Color _getRandomConfettiColor() {
    final colors = [
      Colors.yellow,
      Colors.orange,
      Colors.pink,
      Colors.purple,
      Colors.cyan,
      Colors.lime,
    ];
    return colors[math.Random().nextInt(colors.length)];
  }

  double get _fillProgress {
    return math.min(_fillAnimation.value / widget.xpToLevelUp, 1.0);
  }

  @override
  void dispose() {
    _fillController.dispose();
    _glowController.dispose();
    _popupController.dispose();
    _levelUpController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _fillController,
        _glowController,
        _popupController,
        _levelUpController,
        _confettiController,
      ]),
      builder: (context, child) {
        return SizedBox(
          width: widget.width,
          height: widget.height + 60, // Extra space for popup and level-up
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Confetti layer
              if (_confettiParticles.isNotEmpty)
                CustomPaint(
                  size: Size(widget.width, widget.height + 60),
                  painter: ConfettiPainter(
                    particles: _confettiParticles,
                    animation: _confettiAnimation,
                  ),
                ),

              // XP Bar
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: _buildXpBar(),
              ),

              // XP Popup
              if (_popupAnimation.value > 0)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildXpPopup(),
                ),

              // Level Up Banner
              if (_showLevelUp)
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: _buildLevelUpBanner(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildXpBar() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.height / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withValues(alpha: 0.3 * _glowAnimation.value),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(widget.height / 2),
              border: Border.all(
                color: Colors.cyan.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
          ),

          // Fill
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.height / 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.height / 2),
              child: LinearProgressIndicator(
                value: _fillProgress,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.transparent,
                ),
                semanticsLabel: 'XP Progress',
              ),
            ),
          ),

          // Custom fill with gradient
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.height / 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.height / 2),
              child: CustomPaint(
                size: Size(widget.width, widget.height),
                painter: XpFillPainter(
                  progress: _fillProgress,
                  glowIntensity: _glowAnimation.value,
                ),
              ),
            ),
          ),

          // XP Text
          Center(
            child: Text(
              '${_fillAnimation.value.round()} / ${widget.xpToLevelUp} XP',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpPopup() {
    final popupOffset = Offset(
      0,
      -20 * _popupAnimation.value,
    );

    return Transform.translate(
      offset: popupOffset,
      child: Opacity(
        opacity: math.max(0, 1 - _popupAnimation.value),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.cyan.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              '+${widget.xpGained} XP',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelUpBanner() {
    return Transform.scale(
      scale: _levelUpScaleAnimation.value,
      child: Opacity(
        opacity: _levelUpOpacityAnimation.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.purple, Colors.pink, Colors.orange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.5),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Text(
            'Level Up! 🎉',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class XpFillPainter extends CustomPainter {
  final double progress;
  final double glowIntensity;

  XpFillPainter({
    required this.progress,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final fillWidth = size.width * progress;
    final rect = Rect.fromLTWH(0, 0, fillWidth, size.height);

    // Main gradient fill
    final gradient = LinearGradient(
      colors: [
        Colors.cyan.withValues(alpha: 0.8),
        Colors.blue.withValues(alpha: 0.9),
        Colors.purple.withValues(alpha: 0.8),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    // Add glow effect
    final glowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.cyan.withValues(alpha: 0.3 * glowIntensity),
          Colors.blue.withValues(alpha: 0.4 * glowIntensity),
          Colors.purple.withValues(alpha: 0.3 * glowIntensity),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(rect)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2)),
      glowPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2)),
      paint,
    );

    // Add sparkle effect at the front
    if (progress > 0.1) {
      final sparkleX = fillWidth - 10;
      final sparkleY = size.height / 2;
      
      final sparklePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8 * glowIntensity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(sparkleX, sparkleY), 3, sparklePaint);
      
      // Cross sparkle
      canvas.drawLine(
        Offset(sparkleX - 6, sparkleY),
        Offset(sparkleX + 6, sparkleY),
        sparklePaint..strokeWidth = 2,
      );
      canvas.drawLine(
        Offset(sparkleX, sparkleY - 6),
        Offset(sparkleX, sparkleY + 6),
        sparklePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ConfettiParticle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  double rotation;
  double rotationSpeed;

  ConfettiParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final Animation<double> animation;

  ConfettiPainter({
    required this.particles,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final progress = animation.value;
      final x = particle.position.dx + (particle.velocity.dx * progress);
      final y = particle.position.dy + (particle.velocity.dy * progress) + (150 * progress * progress);

      if (x < -20 || x > size.width + 20 || y > size.height + 20) continue;

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