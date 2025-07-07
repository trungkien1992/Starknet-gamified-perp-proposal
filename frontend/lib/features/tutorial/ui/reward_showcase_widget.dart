import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/street_cred_theme.dart';
import '../../../app/theme/street_cred_design_system.dart';
import '../../../app/widgets/street_cred_button.dart' as scb;
import '../models/tutorial_models.dart';

class RewardShowcaseWidget extends ConsumerStatefulWidget {
  final TutorialReward reward;
  final VoidCallback onDismiss;

  const RewardShowcaseWidget({
    Key? key,
    required this.reward,
    required this.onDismiss,
  }) : super(key: key);

  @override
  ConsumerState<RewardShowcaseWidget> createState() => _RewardShowcaseWidgetState();
}

class _RewardShowcaseWidgetState extends ConsumerState<RewardShowcaseWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _sparkleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.linear),
    );

    _scaleController.forward();
    _glowController.repeat(reverse: true);
    _sparkleController.repeat();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _glowAnimation, _sparkleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.reward.color.withValues(alpha: 0.3),
                  widget.reward.color.withValues(alpha: 0.1),
                  StreetCredTheme.darkGrey,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.reward.color,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.reward.color.withValues(alpha: _glowAnimation.value * 0.6),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Sparkle effects
                _buildSparkleEffects(),
                
                // Main content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Reward type badge
                    _buildRewardTypeBadge(),
                    
                    const SizedBox(height: 20),
                    
                    // Reward emoji/icon
                    _buildRewardIcon(),
                    
                    const SizedBox(height: 20),
                    
                    // Reward name
                    Text(
                      widget.reward.name,
                      style: StreetCredDesignSystem.titleStyle(widget.reward.color).copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Reward description
                    Text(
                      widget.reward.description,
                      style: StreetCredDesignSystem.bodyStyle().copyWith(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Rarity indicator for NFTs
                    if (widget.reward.rarity != null)
                      _buildRarityIndicator(),
                    
                    const SizedBox(height: 24),
                    
                    // Amount/quantity
                    _buildAmountDisplay(),
                    
                    const SizedBox(height: 32),
                    
                    // Claim button
                    scb.StreetCredButton(
                      text: 'CLAIM REWARD',
                      themeColor: widget.reward.color,
                      style: scb.ButtonStyle.primary,
                      width: 200,
                      height: 48,
                      onPressed: () {
                        _claimReward();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSparkleEffects() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _SparklePainter(
          animationValue: _sparkleAnimation.value,
          color: widget.reward.color,
        ),
      ),
    );
  }

  Widget _buildRewardTypeBadge() {
    String badgeText;
    Color badgeColor;
    
    switch (widget.reward.type) {
      case TutorialRewardType.nft:
        badgeText = 'NFT REWARD';
        badgeColor = StreetCredTheme.neonPink;
        break;
      case TutorialRewardType.ink:
        badgeText = 'INK REWARD';
        badgeColor = StreetCredTheme.neonYellow;
        break;
      case TutorialRewardType.xp:
        badgeText = 'XP REWARD';
        badgeColor = StreetCredTheme.neonBlue;
        break;
      case TutorialRewardType.badge:
        badgeText = 'BADGE EARNED';
        badgeColor = StreetCredTheme.neonGreen;
        break;
      case TutorialRewardType.territory:
        badgeText = 'TERRITORY ACCESS';
        badgeColor = StreetCredTheme.neonPink;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor, width: 2),
      ),
      child: Text(
        badgeText,
        style: StreetCredDesignSystem.captionStyle().copyWith(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildRewardIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            widget.reward.color.withValues(alpha: 0.3),
            widget.reward.color.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
        border: Border.all(
          color: widget.reward.color.withValues(alpha: _glowAnimation.value),
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          widget.reward.emoji,
          style: const TextStyle(fontSize: 64),
        ),
      ),
    );
  }

  Widget _buildRarityIndicator() {
    if (widget.reward.rarity == null) return const SizedBox.shrink();

    Color rarityColor;
    String rarityText;

    switch (widget.reward.rarity!) {
      case StarterNFTRarity.common:
        rarityColor = Colors.grey;
        rarityText = 'COMMON';
        break;
      case StarterNFTRarity.rare:
        rarityColor = StreetCredTheme.neonBlue;
        rarityText = 'RARE';
        break;
      case StarterNFTRarity.epic:
        rarityColor = StreetCredTheme.neonPink;
        rarityText = 'EPIC';
        break;
      case StarterNFTRarity.legendary:
        rarityColor = StreetCredTheme.neonYellow;
        rarityText = 'LEGENDARY';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            rarityColor.withValues(alpha: 0.6),
            rarityColor.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rarityColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: rarityColor.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRarityIcon(widget.reward.rarity!),
            color: rarityColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            rarityText,
            style: StreetCredDesignSystem.bodyStyle().copyWith(
              color: rarityColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay() {
    if (widget.reward.amount <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.reward.color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '+${widget.reward.amount}',
        style: StreetCredDesignSystem.titleStyle(widget.reward.color).copyWith(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getRarityIcon(StarterNFTRarity rarity) {
    switch (rarity) {
      case StarterNFTRarity.common:
        return Icons.star_border;
      case StarterNFTRarity.rare:
        return Icons.star_half;
      case StarterNFTRarity.epic:
        return Icons.star;
      case StarterNFTRarity.legendary:
        return Icons.auto_awesome;
    }
  }

  void _claimReward() {
    // Play claim animation
    _scaleController.reverse().then((_) {
      widget.onDismiss();
    });

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reward claimed: ${widget.reward.name}!',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: widget.reward.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _SparklePainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // Create sparkle effect
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * 3.14159;
      final radius = (size.width / 3) + (20 * (animationValue % 1));
      
      final x = size.width / 2 + (radius * (animationValue % 1)) * (1 + 0.3 * i) * 0.1 * i;
      final y = size.height / 2 + (radius * (animationValue % 1)) * (1 + 0.3 * i) * 0.1 * i;
      
      final sparkleSize = 3 + (2 * (1 - (animationValue % 1)));
      
      // Draw sparkle
      canvas.drawCircle(
        Offset(x, y),
        sparkleSize,
        paint..color = color.withValues(alpha: 0.8 * (1 - (animationValue % 1))),
      );
    }

    // Draw center glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 3,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}