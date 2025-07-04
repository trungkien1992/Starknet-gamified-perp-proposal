import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/drip_nft.dart';
import '../state/drip_provider.dart';
import 'dart:math' as math;

class DripInventoryWidget extends ConsumerStatefulWidget {
  const DripInventoryWidget({super.key});

  @override
  ConsumerState<DripInventoryWidget> createState() =>
      _DripInventoryWidgetState();
}

class _DripInventoryWidgetState extends ConsumerState<DripInventoryWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _equipController;
  late AnimationController _sparkleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _equipAnimation;
  late Animation<double> _sparkleAnimation;
  String? _lastEquippedId;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _equipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _equipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _equipController, curve: Curves.elasticOut),
    );

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeOut),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _equipController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  Color _rarityColor(DripRarity rarity) {
    switch (rarity) {
      case DripRarity.common:
        return Colors.grey.shade400;
      case DripRarity.rare:
        return Colors.blue.shade400;
      case DripRarity.epic:
        return Colors.purple.shade400;
      case DripRarity.legendary:
        return Colors.amber.shade400;
    }
  }

  void _onNFTTapped(String nftId, DripRarity rarity) {
    // Trigger equip celebration
    HapticFeedback.mediumImpact();
    _equipController.forward().then((_) => _equipController.reset());

    // Legendary items get extra sparkle effect
    if (rarity == DripRarity.legendary) {
      _sparkleController.forward().then((_) => _sparkleController.reset());
      HapticFeedback.heavyImpact();
    }

    setState(() => _lastEquippedId = nftId);
    ref.read(dripProvider.notifier).equip(nftId);
  }

  @override
  Widget build(BuildContext context) {
    final drip = ref.watch(dripProvider);
    if (drip.loading) {
      return GridView.builder(
        shrinkWrap: true,
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemBuilder: (_, __) => Card(
          child: Container(
            color: Colors.grey[300],
            width: 80,
            height: 80,
            margin: const EdgeInsets.all(16),
          ),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      itemCount: drip.nfts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemBuilder: (context, i) {
        final nft = drip.nfts[i];
        final equipped = drip.equippedId == nft.id;
        final justEquipped = _lastEquippedId == nft.id;

        return GestureDetector(
          onTap: () => _onNFTTapped(nft.id, nft.rarity),
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _pulseAnimation,
              _equipAnimation,
              _sparkleAnimation,
            ]),
            builder: (context, child) {
              final pulseEffect =
                  nft.isNew || nft.rarity == DripRarity.legendary
                  ? _pulseAnimation.value
                  : 1.0;
              final equipEffect = justEquipped ? _equipAnimation.value : 0.0;

              return Transform.scale(
                scale: pulseEffect + equipEffect * 0.1,
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: equipped
                              ? Colors.green.shade400
                              : _rarityColor(nft.rarity),
                          width: equipped ? 4 : 2 + equipEffect * 2,
                        ),
                        boxShadow: [
                          // Rarity-specific glows
                          if (nft.rarity == DripRarity.legendary)
                            BoxShadow(
                              color: Colors.amber.withValues(
                                alpha: 0.6 + 0.4 * pulseEffect,
                              ),
                              blurRadius: 16 + 8 * pulseEffect,
                              spreadRadius: 2 + 2 * pulseEffect,
                            ),
                          if (nft.rarity == DripRarity.epic)
                            BoxShadow(
                              color: Colors.purple.withValues(
                                alpha: 0.4 + 0.3 * pulseEffect,
                              ),
                              blurRadius: 12 + 6 * pulseEffect,
                              spreadRadius: 1 + pulseEffect,
                            ),
                          if (nft.rarity == DripRarity.rare)
                            BoxShadow(
                              color: Colors.blue.withValues(
                                alpha: 0.3 + 0.2 * pulseEffect,
                              ),
                              blurRadius: 8 + 4 * pulseEffect,
                              spreadRadius: pulseEffect,
                            ),
                          if (nft.isNew)
                            BoxShadow(
                              color: Colors.cyanAccent.withValues(
                                alpha: 0.5 + 0.3 * pulseEffect,
                              ),
                              blurRadius: 12 + 6 * pulseEffect,
                              spreadRadius: 1 + pulseEffect,
                            ),
                          // Equip celebration effect
                          if (justEquipped && equipEffect > 0)
                            BoxShadow(
                              color: Colors.green.withValues(
                                alpha: equipEffect * 0.8,
                              ),
                              blurRadius: 20 * equipEffect,
                              spreadRadius: 4 * equipEffect,
                            ),
                        ],
                        borderRadius: BorderRadius.circular(20),
                        gradient: equipped
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.green.withValues(alpha: 0.1),
                                  Colors.green.withValues(alpha: 0.05),
                                ],
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  nft.imageUrl,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // Sparkle overlay for legendary items
                              if (nft.rarity == DripRarity.legendary &&
                                  _sparkleAnimation.value > 0)
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _SparklePainter(
                                      animation: _sparkleAnimation.value,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            nft.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12 + equipEffect * 2,
                              color: equipped ? Colors.green.shade700 : null,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            nft.rarity.name.toUpperCase(),
                            style: TextStyle(
                              color: _rarityColor(nft.rarity),
                              fontSize: 10 + equipEffect,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (equipped)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green.shade600,
                                      size: 16 + equipEffect * 4,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'EQUIPPED',
                                      style: TextStyle(
                                        color: Colors.green.shade600,
                                        fontSize: 10 + equipEffect,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (nft.isNew)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.cyanAccent,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Colors.cyanAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Celebration confetti for equipped items
                    if (justEquipped && equipEffect > 0.5)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _ConfettiPainter(
                            animation: equipEffect,
                            color: _rarityColor(nft.rarity),
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

class _SparklePainter extends CustomPainter {
  final double animation;
  final Color color;

  _SparklePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for consistent animation
    final sparkleCount = 8;

    for (int i = 0; i < sparkleCount; i++) {
      final progress = (animation - (i / sparkleCount * 0.3)).clamp(0.0, 1.0);
      if (progress <= 0) continue;

      final angle = (i / sparkleCount) * 2 * math.pi;
      final radius = size.width * 0.4 * progress;
      final x = size.width * 0.5 + math.cos(angle) * radius;
      final y = size.height * 0.5 + math.sin(angle) * radius;

      final sparkleSize = 2.0 + 4.0 * (1.0 - progress);
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      final sparklePaint = Paint()
        ..color = color.withValues(alpha: opacity * 0.9)
        ..style = PaintingStyle.fill;

      // Draw sparkle as a 4-pointed star
      final path = Path();
      final starSize = sparkleSize;
      path.moveTo(x, y - starSize);
      path.lineTo(x + starSize * 0.3, y - starSize * 0.3);
      path.lineTo(x + starSize, y);
      path.lineTo(x + starSize * 0.3, y + starSize * 0.3);
      path.lineTo(x, y + starSize);
      path.lineTo(x - starSize * 0.3, y + starSize * 0.3);
      path.lineTo(x - starSize, y);
      path.lineTo(x - starSize * 0.3, y - starSize * 0.3);
      path.close();

      canvas.drawPath(path, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class _ConfettiPainter extends CustomPainter {
  final double animation;
  final Color color;

  _ConfettiPainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for consistent animation
    final particleCount = 12;

    for (int i = 0; i < particleCount; i++) {
      final progress = (animation - (i / particleCount * 0.2)).clamp(0.0, 1.0);
      if (progress <= 0) continue;

      final startX = size.width * 0.5 + (random.nextDouble() - 0.5) * 20;
      final startY = size.height * 0.5 + (random.nextDouble() - 0.5) * 20;

      final endX = startX + (random.nextDouble() - 0.5) * 60 * progress;
      final endY =
          startY - 30 * progress + 15 * progress * progress; // Gravity effect

      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final particleSize = 2.0 + random.nextDouble() * 2.0;

      final particlePaint = Paint()
        ..color = [
          color,
          Colors.white,
          Colors.yellow.shade300,
        ][i % 3].withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(endX, endY), particleSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
