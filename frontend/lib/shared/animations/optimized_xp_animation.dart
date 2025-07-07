import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants/animation_constants.dart';
import '../utils/haptic_manager.dart';

/// Optimized XP Animation with performance improvements
/// - Uses AnimatedBuilder for better performance
/// - Implements proper controller disposal
/// - Reduces unnecessary rebuilds with RepaintBoundary
/// - Uses const constructors where possible
class OptimizedXpAnimation extends StatefulWidget {
  final int currentXp;
  final int xpGained;
  final int xpToLevelUp;
  final VoidCallback? onLevelUp;
  final VoidCallback? onComplete;
  final double width;
  final double height;
  final Color primaryColor;
  final Color secondaryColor;

  const OptimizedXpAnimation({
    super.key,
    required this.currentXp,
    required this.xpGained,
    required this.xpToLevelUp,
    this.onLevelUp,
    this.onComplete,
    this.width = 300.0,
    this.height = 60.0,
    this.primaryColor = Colors.cyan,
    this.secondaryColor = Colors.yellow,
  });

  @override
  State<OptimizedXpAnimation> createState() => _OptimizedXpAnimationState();
}

class _OptimizedXpAnimationState extends State<OptimizedXpAnimation>
    with TickerProviderStateMixin {
  // Animation controllers - using late for better performance
  late final AnimationController _masterController;
  late final AnimationController _glowController;
  late final AnimationController _levelUpController;

  // Animations
  late final Animation<double> _fillAnimation;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  // State variables
  bool _hasLeveledUp = false;
  double _initialProgress = 0.0;
  double _targetProgress = 0.0;
  List<ConfettiParticle> _confettiParticles = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _calculateProgress();
    _startAnimation();
  }

  void _initializeAnimations() {
    // Master controller for main animation
    _masterController = AnimationController(
      duration: AnimationConstants.xpFillDuration,
      vsync: this,
    );

    // Glow controller for background effects
    _glowController = AnimationController(
      duration: AnimationConstants.xpGlowDuration,
      vsync: this,
    );

    // Level up controller for celebration
    _levelUpController = AnimationController(
      duration: AnimationConstants.confettiDuration,
      vsync: this,
    );

    // Create animations with proper curves
    _fillAnimation = Tween<double>(
      begin: _initialProgress,
      end: _targetProgress,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: AnimationConstants.smoothCurve,
    ));

    _glowAnimation = Tween<double>(
      begin: AnimationConstants.minOpacity,
      end: AnimationConstants.glowOpacity,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AnimationConstants.levelUpScale,
    ).animate(CurvedAnimation(
      parent: _levelUpController,
      curve: AnimationConstants.elasticCurve,
    ));

    _opacityAnimation = Tween<double>(
      begin: AnimationConstants.maxOpacity,
      end: AnimationConstants.minOpacity,
    ).animate(CurvedAnimation(
      parent: _levelUpController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    // Add listeners for state changes
    _masterController.addStatusListener(_onAnimationComplete);
    _levelUpController.addStatusListener(_onLevelUpComplete);
  }

  void _calculateProgress() {
    _initialProgress = widget.currentXp / widget.xpToLevelUp;
    final newXp = widget.currentXp + widget.xpGained;
    
    if (newXp >= widget.xpToLevelUp) {
      _hasLeveledUp = true;
      _targetProgress = 1.0;
      _generateConfetti();
    } else {
      _targetProgress = newXp / widget.xpToLevelUp;
    }
  }

  void _startAnimation() {
    _masterController.forward();
    _glowController.repeat(reverse: true);
  }

  void _onAnimationComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (_hasLeveledUp) {
        _triggerLevelUp();
      } else {
        widget.onComplete?.call();
      }
    }
  }

  void _triggerLevelUp() {
    HapticManager.provideFeedback(HapticFeedbackType.levelUp);
    widget.onLevelUp?.call();
    _levelUpController.forward();
  }

  void _onLevelUpComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onComplete?.call();
    }
  }

  void _generateConfetti() {
    final random = math.Random();
    _confettiParticles = List.generate(20, (index) {
      return ConfettiParticle(
        x: random.nextDouble() * widget.width,
        y: widget.height / 2,
        velocity: Offset(
          (random.nextDouble() - 0.5) * 200,
          -random.nextDouble() * 300 - 100,
        ),
        color: [widget.primaryColor, widget.secondaryColor, Colors.white][random.nextInt(3)],
        size: random.nextDouble() * 6 + 2,
      );
    });
  }

  @override
  void dispose() {
    _masterController.dispose();
    _glowController.dispose();
    _levelUpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          children: [
            // Background glow effect
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) => _buildGlowEffect(),
            ),
            
            // Main XP bar
            AnimatedBuilder(
              animation: _fillAnimation,
              builder: (context, child) => _buildXpBar(),
            ),
            
            // XP text overlay
            _buildXpText(),
            
            // Level up celebration
            if (_hasLeveledUp)
              AnimatedBuilder(
                animation: Listenable.merge([_scaleAnimation, _opacityAnimation]),
                builder: (context, child) => _buildLevelUpCelebration(),
              ),
            
            // Confetti effect
            if (_hasLeveledUp)
              AnimatedBuilder(
                animation: _levelUpController,
                builder: (context, child) => _buildConfetti(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowEffect() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.height / 2),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: _glowAnimation.value * 0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildXpBar() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.height / 2),
        color: Colors.grey[800],
        border: Border.all(color: widget.primaryColor.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.height / 2),
        child: LinearProgressIndicator(
          value: _fillAnimation.value,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(
            _hasLeveledUp ? widget.secondaryColor : widget.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildXpText() {
    return Positioned.fill(
      child: Center(
        child: Text(
          '+${widget.xpGained} XP',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelUpCelebration() {
    return Positioned.fill(
      child: Transform.scale(
        scale: _scaleAnimation.value,
        child: Opacity(
          opacity: _opacityAnimation.value,
          child: const Center(
            child: Text(
              'LEVEL UP!',
              style: TextStyle(
                color: Colors.yellow,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: Colors.black, blurRadius: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return Positioned.fill(
      child: CustomPaint(
        painter: ConfettiPainter(
          particles: _confettiParticles,
          progress: _levelUpController.value,
        ),
      ),
    );
  }
}

class ConfettiParticle {
  final double x;
  final double y;
  final Offset velocity;
  final Color color;
  final double size;

  const ConfettiParticle({
    required this.x,
    required this.y,
    required this.velocity,
    required this.color,
    required this.size,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  const ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    for (final particle in particles) {
      final currentX = particle.x + particle.velocity.dx * progress;
      final currentY = particle.y + particle.velocity.dy * progress + 
                      0.5 * 500 * progress * progress; // Gravity effect
      
      paint.color = particle.color.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0));
      canvas.drawCircle(
        Offset(currentX, currentY),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}