import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';

enum DripRarity {
  common,
  rare,
  epic,
  legendary,
}

class DripReward {
  final String id;
  final String name;
  final DripRarity rarity;
  final String? imageUrl;

  const DripReward({
    required this.id,
    required this.name,
    required this.rarity,
    this.imageUrl,
  });
}

class DripRewardModal extends StatefulWidget {
  final DripReward reward;
  final Function(String dripId) onEquip;
  final VoidCallback onClose;

  const DripRewardModal({
    super.key,
    required this.reward,
    required this.onEquip,
    required this.onClose,
  });

  @override
  State<DripRewardModal> createState() => _DripRewardModalState();
}

class _DripRewardModalState extends State<DripRewardModal>
    with TickerProviderStateMixin {
  late AnimationController _modalController;
  late AnimationController _glowController;
  late AnimationController _confettiController;
  late AnimationController _sparkleController;
  late AnimationController _wiggleController;

  late Animation<double> _modalScaleAnimation;
  late Animation<double> _modalOpacityAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _confettiAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _wiggleAnimation;

  bool _isHoveringEquip = false;
  List<ConfettiParticle> _confettiParticles = [];
  List<SparkleParticle> _sparkleParticles = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _modalController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _wiggleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _modalScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _modalController,
      curve: Curves.elasticOut,
    ));

    _modalOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _modalController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _confettiAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    ));

    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.linear,
    ));

    _wiggleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _wiggleController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() {
    _modalController.forward();
    _glowController.repeat(reverse: true);
    
    Future.delayed(const Duration(milliseconds: 300), () {
      _generateConfetti();
      _confettiController.forward();
    });

    if (_isHighRarity) {
      _generateSparkles();
      _sparkleController.repeat();
    }
  }

  void _generateConfetti() {
    _confettiParticles = List.generate(30, (index) {
      return ConfettiParticle(
        position: Offset(0, 0),
        velocity: Offset(
          (math.Random().nextDouble() - 0.5) * 400,
          -math.Random().nextDouble() * 200 - 100,
        ),
        color: _getRandomConfettiColor(),
        size: math.Random().nextDouble() * 8 + 4,
        rotation: math.Random().nextDouble() * math.pi * 2,
        rotationSpeed: (math.Random().nextDouble() - 0.5) * 10,
      );
    });
  }

  void _generateSparkles() {
    _sparkleParticles = List.generate(20, (index) {
      return SparkleParticle(
        position: Offset(
          math.Random().nextDouble() * 300 - 150,
          math.Random().nextDouble() * 300 - 150,
        ),
        size: math.Random().nextDouble() * 4 + 2,
        opacity: math.Random().nextDouble() * 0.8 + 0.2,
        twinkleSpeed: math.Random().nextDouble() * 2 + 1,
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
      Colors.green,
    ];
    return colors[math.Random().nextInt(colors.length)];
  }

  bool get _isHighRarity => 
      widget.reward.rarity == DripRarity.epic || 
      widget.reward.rarity == DripRarity.legendary;

  Color get _rarityColor {
    switch (widget.reward.rarity) {
      case DripRarity.common:
        return Colors.grey;
      case DripRarity.rare:
        return Colors.blue;
      case DripRarity.epic:
        return Colors.purple;
      case DripRarity.legendary:
        return Colors.orange;
    }
  }

  String get _rarityName {
    switch (widget.reward.rarity) {
      case DripRarity.common:
        return "COMMON";
      case DripRarity.rare:
        return "RARE";
      case DripRarity.epic:
        return "EPIC";
      case DripRarity.legendary:
        return "LEGENDARY";
    }
  }

  @override
  void dispose() {
    _modalController.dispose();
    _glowController.dispose();
    _confettiController.dispose();
    _sparkleController.dispose();
    _wiggleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _modalController,
        _glowController,
        _confettiController,
        _sparkleController,
        _wiggleController,
      ]),
      builder: (context, child) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // Backdrop blur
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.7),
                ),
              ),

              // Confetti layer
              if (_confettiParticles.isNotEmpty)
                CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: ConfettiPainter(
                    particles: _confettiParticles,
                    animation: _confettiAnimation,
                  ),
                ),

              // Main modal
              Center(
                child: Transform.scale(
                  scale: _modalScaleAnimation.value,
                  child: Opacity(
                    opacity: _modalOpacityAnimation.value,
                    child: Container(
                      width: 320,
                      height: 400,
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _rarityColor.withValues(alpha: 0.8),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _rarityColor.withValues(alpha: 0.3 * _glowAnimation.value),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Sparkles for high rarity
                          if (_isHighRarity)
                            CustomPaint(
                              size: const Size(320, 400),
                              painter: SparklePainter(
                                particles: _sparkleParticles,
                                animation: _sparkleAnimation,
                              ),
                            ),

                          // Content
                          _buildContent(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Close button
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: widget.onClose,
              icon: const Icon(Icons.close, color: Colors.white54),
            ),
          ),

          // NFT Image placeholder
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: _rarityColor.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: widget.reward.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.network(
                      widget.reward.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderImage(),
                    ),
                  )
                : _buildPlaceholderImage(),
          ),

          const SizedBox(height: 20),

          // Rarity badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _rarityColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _rarityColor.withValues(alpha: 0.5 * _glowAnimation.value),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              _rarityName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 15),

          // NFT name
          Text(
            widget.reward.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onClose,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: MouseRegion(
                  onEnter: (_) {
                    setState(() => _isHoveringEquip = true);
                    _wiggleController.forward();
                  },
                  onExit: (_) {
                    setState(() => _isHoveringEquip = false);
                    _wiggleController.reverse();
                  },
                  child: Transform.rotate(
                    angle: math.sin(_wiggleAnimation.value * math.pi * 2) * 0.05,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        widget.onEquip(widget.reward.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _rarityColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        elevation: _isHoveringEquip ? 8 : 4,
                      ),
                      child: const Text(
                        "Equip",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _rarityColor.withValues(alpha: 0.3),
            _rarityColor.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Center(
        child: Icon(
          Icons.emoji_events,
          size: 60,
          color: _rarityColor,
        ),
      ),
    );
  }
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

class SparkleParticle {
  Offset position;
  double size;
  double opacity;
  double twinkleSpeed;

  SparkleParticle({
    required this.position,
    required this.size,
    required this.opacity,
    required this.twinkleSpeed,
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
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (var particle in particles) {
      final progress = animation.value;
      final x = centerX + particle.position.dx + (particle.velocity.dx * progress);
      final y = centerY + particle.position.dy + (particle.velocity.dy * progress) + (200 * progress * progress);

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

class SparklePainter extends CustomPainter {
  final List<SparkleParticle> particles;
  final Animation<double> animation;

  SparklePainter({
    required this.particles,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (var particle in particles) {
      final twinkle = math.sin(animation.value * math.pi * 2 * particle.twinkleSpeed) * 0.5 + 0.5;
      final opacity = particle.opacity * twinkle;

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final x = centerX + particle.position.dx;
      final y = centerY + particle.position.dy;

      canvas.drawCircle(Offset(x, y), particle.size, paint);
      
      // Add cross sparkle effect
      canvas.drawLine(
        Offset(x - particle.size * 2, y),
        Offset(x + particle.size * 2, y),
        paint..strokeWidth = 1,
      );
      canvas.drawLine(
        Offset(x, y - particle.size * 2),
        Offset(x, y + particle.size * 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}