import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/drip_nft.dart';
import 'dart:math' as math;

class DripRewardModal extends StatefulWidget {
  final DripNFT nft;
  final VoidCallback? onClose;
  const DripRewardModal({super.key, required this.nft, this.onClose});

  @override
  State<DripRewardModal> createState() => _DripRewardModalState();
}

class _DripRewardModalState extends State<DripRewardModal>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _textController;
  late Animation<double> _scaleAnim;
  late Animation<double> _particleAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _textAnim;
  bool _visible = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  Color get rarityColor {
    switch (widget.nft.rarity) {
      case DripRarity.common:
        return Colors.grey;
      case DripRarity.rare:
        return Colors.blueAccent;
      case DripRarity.epic:
        return Colors.purpleAccent;
      case DripRarity.legendary:
        return Colors.amber;
    }
  }

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _particleAnim = CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _textAnim = CurvedAnimation(
      parent: _textController,
      curve: Curves.elasticOut,
    );

    Future.delayed(const Duration(milliseconds: 100), () async {
      setState(() => _visible = true);

      // Sequence the animations for maximum impact
      _scaleController.forward();

      // Add haptic feedback based on rarity
      switch (widget.nft.rarity) {
        case DripRarity.legendary:
          HapticFeedback.heavyImpact();
          break;
        case DripRarity.epic:
          HapticFeedback.mediumImpact();
          break;
        default:
          HapticFeedback.lightImpact();
      }

      // Start particle animation after a delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _particleController.forward();
      });

      // Start text animation
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _textController.forward();
      });

      // Start pulsing for legendary items
      if (widget.nft.rarity == DripRarity.legendary) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _pulseController.repeat(reverse: true);
        });
      }

      // Play sound effect on reveal
      try {
        // await _audioPlayer.play(AssetSource('sounds/reward_chime.mp3'));
        print('[Audio] Would play reward chime sound');
      } catch (_) {}
    });

    Future.delayed(const Duration(seconds: 4), _close);
  }

  void _close() {
    if (mounted) {
      setState(() => _visible = false);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (widget.onClose != null) widget.onClose!();
        if (Navigator.canPop(context)) Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _shareNFT() {
    final message =
        'I just unlocked a ${widget.nft.rarity.name.toUpperCase()} Drip: "${widget.nft.name}" in StreetCred!';
    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: _close,
        child: Container(
          color: Colors.black.withValues(alpha: 0.7),
          child: Stack(
            children: [
              // Particle effect background
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _particleAnim,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _RewardParticlePainter(
                        animation: _particleAnim.value,
                        color: rarityColor,
                        rarity: widget.nft.rarity,
                      ),
                    );
                  },
                ),
              ),

              // Main modal content
              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _scaleAnim,
                    _pulseAnim,
                    _textAnim,
                  ]),
                  builder: (context, child) {
                    final pulseEffect =
                        widget.nft.rarity == DripRarity.legendary
                        ? _pulseAnim.value
                        : 1.0;

                    return Transform.scale(
                      scale: _scaleAnim.value * pulseEffect,
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Colors.grey.shade50],
                          ),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: rarityColor,
                            width:
                                6 +
                                (widget.nft.rarity == DripRarity.legendary
                                    ? 2
                                    : 0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: rarityColor.withValues(alpha: 0.8),
                              blurRadius:
                                  40 +
                                  (widget.nft.rarity == DripRarity.legendary
                                      ? 20
                                      : 0),
                              spreadRadius:
                                  15 +
                                  (widget.nft.rarity == DripRarity.legendary
                                      ? 10
                                      : 0),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // NFT Image with enhanced effects
                            Stack(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOut,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: rarityColor.withValues(
                                          alpha: 0.6,
                                        ),
                                        blurRadius: 50,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: rarityColor.withValues(
                                            alpha: 0.3,
                                          ),
                                          width: 4,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Image.network(
                                        widget.nft.imageUrl,
                                        width: 140,
                                        height: 140,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),

                                // Sparkle overlay for epic+ items
                                if ((widget.nft.rarity == DripRarity.epic ||
                                        widget.nft.rarity ==
                                            DripRarity.legendary) &&
                                    _particleAnim.value > 0.3)
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _SparkleOverlayPainter(
                                        animation: _particleAnim.value,
                                        color: rarityColor,
                                        isLegendary:
                                            widget.nft.rarity ==
                                            DripRarity.legendary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Title with text animation
                            Transform.scale(
                              scale: _textAnim.value,
                              child: Text(
                                widget.nft.name,
                                style: TextStyle(
                                  fontSize:
                                      32 +
                                      (widget.nft.rarity == DripRarity.legendary
                                          ? 6
                                          : 0),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 8,
                                      color: rarityColor.withValues(alpha: 0.3),
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Rarity badge with enhanced styling
                            Transform.scale(
                              scale: _textAnim.value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      rarityColor.withValues(alpha: 0.2),
                                      rarityColor.withValues(alpha: 0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: rarityColor,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: rarityColor.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getRarityIcon(widget.nft.rarity),
                                      color: rarityColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.nft.rarity.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize:
                                            18 +
                                            (widget.nft.rarity ==
                                                    DripRarity.legendary
                                                ? 2
                                                : 0),
                                        color: rarityColor,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 8,
                                            color: rarityColor.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Celebration message
                            Transform.scale(
                              scale: _textAnim.value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          '🎉',
                                          style: TextStyle(fontSize: 24),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'NEW DRIP UNLOCKED!',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.orange.shade800,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          '🎉',
                                          style: TextStyle(fontSize: 24),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getRarityMessage(widget.nft.rarity),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.orange.shade700,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Share button with enhanced styling
                            Transform.scale(
                              scale: _textAnim.value,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  _shareNFT();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: rarityColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 8,
                                  shadowColor: rarityColor.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                icon: const Icon(Icons.share, size: 20),
                                label: const Text(
                                  'Share Achievement',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getRarityIcon(DripRarity rarity) {
    switch (rarity) {
      case DripRarity.common:
        return Icons.circle;
      case DripRarity.rare:
        return Icons.hexagon;
      case DripRarity.epic:
        return Icons.diamond;
      case DripRarity.legendary:
        return Icons.auto_awesome;
    }
  }

  String _getRarityMessage(DripRarity rarity) {
    switch (rarity) {
      case DripRarity.common:
        return 'A solid addition to your collection!';
      case DripRarity.rare:
        return 'Nice find! This one\'s pretty special.';
      case DripRarity.epic:
        return 'Wow! This is an incredible piece!';
      case DripRarity.legendary:
        return 'LEGENDARY DROP! You hit the jackpot!';
    }
  }
}

class _RewardParticlePainter extends CustomPainter {
  final double animation;
  final Color color;
  final DripRarity rarity;

  _RewardParticlePainter({
    required this.animation,
    required this.color,
    required this.rarity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);

    // More particles for higher rarities
    int particleCount;
    switch (rarity) {
      case DripRarity.common:
        particleCount = 15;
        break;
      case DripRarity.rare:
        particleCount = 25;
        break;
      case DripRarity.epic:
        particleCount = 40;
        break;
      case DripRarity.legendary:
        particleCount = 60;
        break;
    }

    for (int i = 0; i < particleCount; i++) {
      final progress = (animation - (i / particleCount * 0.5)).clamp(0.0, 1.0);
      if (progress <= 0) continue;

      final angle = (i / particleCount) * 2 * math.pi + animation * math.pi;
      final radius =
          size.width * 0.3 +
          (random.nextDouble() * size.width * 0.4) * progress;
      final x = size.width * 0.5 + math.cos(angle) * radius;
      final y = size.height * 0.5 + math.sin(angle) * radius;

      final particleSize =
          (2.0 + random.nextDouble() * 4.0) * (1.0 - progress * 0.5);
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      final particlePaint = Paint()
        ..color =
            [
              color,
              Colors.white,
              Colors.yellow.shade200,
              if (rarity == DripRarity.legendary) Colors.amber,
            ][i % (rarity == DripRarity.legendary ? 4 : 3)].withValues(
              alpha: opacity * 0.8,
            )
        ..style = PaintingStyle.fill;

      // Special shapes for different rarities
      if (rarity == DripRarity.legendary && i % 4 == 0) {
        _drawStar(canvas, Offset(x, y), particleSize, particlePaint);
      } else if (rarity == DripRarity.epic && i % 3 == 0) {
        _drawDiamond(canvas, Offset(x, y), particleSize, particlePaint);
      } else {
        canvas.drawCircle(Offset(x, y), particleSize, particlePaint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const numPoints = 5;
    final outerRadius = size;
    final innerRadius = size * 0.4;

    for (int i = 0; i < numPoints * 2; i++) {
      final angle = (i * math.pi) / numPoints;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + radius * math.cos(angle - math.pi / 2);
      final y = center.dy + radius * math.sin(angle - math.pi / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawDiamond(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size, center.dy);
    path.lineTo(center.dx, center.dy + size);
    path.lineTo(center.dx - size, center.dy);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RewardParticlePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class _SparkleOverlayPainter extends CustomPainter {
  final double animation;
  final Color color;
  final bool isLegendary;

  _SparkleOverlayPainter({
    required this.animation,
    required this.color,
    required this.isLegendary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(123);
    final sparkleCount = isLegendary ? 12 : 8;

    for (int i = 0; i < sparkleCount; i++) {
      final progress = (animation - 0.3 - (i / sparkleCount * 0.2)).clamp(
        0.0,
        1.0,
      );
      if (progress <= 0) continue;

      final angle = (i / sparkleCount) * 2 * math.pi + animation * math.pi * 2;
      final radius = (size.width * 0.4) + (random.nextDouble() * 20 - 10);
      final x = size.width * 0.5 + math.cos(angle) * radius;
      final y = size.height * 0.5 + math.sin(angle) * radius;

      final sparkleSize =
          (3.0 + random.nextDouble() * 3.0) * (1.0 - progress * 0.3);
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      final sparklePaint = Paint()
        ..color = isLegendary
            ? Colors.amber.withValues(alpha: opacity * 0.9)
            : color.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;

      // Draw 4-pointed star sparkle
      final path = Path();
      path.moveTo(x, y - sparkleSize);
      path.lineTo(x + sparkleSize * 0.3, y - sparkleSize * 0.3);
      path.lineTo(x + sparkleSize, y);
      path.lineTo(x + sparkleSize * 0.3, y + sparkleSize * 0.3);
      path.lineTo(x, y + sparkleSize);
      path.lineTo(x - sparkleSize * 0.3, y + sparkleSize * 0.3);
      path.lineTo(x - sparkleSize, y);
      path.lineTo(x - sparkleSize * 0.3, y - sparkleSize * 0.3);
      path.close();

      canvas.drawPath(path, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleOverlayPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
