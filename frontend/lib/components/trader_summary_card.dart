import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class TradeSummary {
  final double pnl;
  final int xpGained;
  final String? dripRarity;
  final int? totalXp;

  const TradeSummary({
    required this.pnl,
    required this.xpGained,
    this.dripRarity,
    this.totalXp,
  });
}

class TraderSummaryCard extends StatefulWidget {
  final TradeSummary summary;
  final VoidCallback? onDismiss;
  final Duration displayDuration;
  final bool autoHide;

  const TraderSummaryCard({
    super.key,
    required this.summary,
    this.onDismiss,
    this.displayDuration = const Duration(milliseconds: 2500),
    this.autoHide = true,
  });

  @override
  State<TraderSummaryCard> createState() => _TraderSummaryCardState();

  /// Show the trader summary card as an overlay
  static void show(
    BuildContext context, {
    required TradeSummary summary,
    VoidCallback? onDismiss,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => TraderSummaryCard(
        summary: summary,
        onDismiss: () {
          overlayEntry.remove();
          onDismiss?.call();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _TraderSummaryCardState extends State<TraderSummaryCard>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _xpController;
  late AnimationController _glowController;
  late AnimationController _sparkleController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _xpCountAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _sparkleAnimation;

  List<SparkleParticle> _sparkles = [];
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateSparkles();
    _startAnimations();
    _scheduleAutoDismiss();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _xpController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _xpCountAnimation = Tween<double>(
      begin: 0,
      end: widget.summary.xpGained.toDouble(),
    ).animate(CurvedAnimation(
      parent: _xpController,
      curve: Curves.easeOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.linear,
    ));
  }

  void _generateSparkles() {
    if (widget.summary.pnl > 0 || widget.summary.dripRarity != null) {
      _sparkles = List.generate(15, (index) {
        return SparkleParticle(
          position: Offset(
            math.Random().nextDouble() * 300 - 150,
            math.Random().nextDouble() * 200 - 100,
          ),
          size: math.Random().nextDouble() * 4 + 2,
          opacity: math.Random().nextDouble() * 0.8 + 0.2,
          twinkleSpeed: math.Random().nextDouble() * 2 + 1,
        );
      });
    }
  }

  void _startAnimations() {
    _slideController.forward();
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _xpController.forward();
        _glowController.repeat(reverse: true);
        
        if (_sparkles.isNotEmpty) {
          _sparkleController.repeat();
        }
      }
    });
  }

  void _scheduleAutoDismiss() {
    if (widget.autoHide) {
      Future.delayed(widget.displayDuration, () {
        if (mounted && !_isDismissed) {
          _dismiss();
        }
      });
    }
  }

  void _dismiss() {
    if (_isDismissed) return;
    _isDismissed = true;
    
    _slideController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _xpController.dispose();
    _glowController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _slideController,
        _xpController,
        _glowController,
        _sparkleController,
      ]),
      builder: (context, child) {
        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: _dismiss,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _getGradientColors(),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getBorderColor(),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getBorderColor().withValues(alpha: 0.4 * _glowAnimation.value),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Sparkles overlay
                    if (_sparkles.isNotEmpty)
                      CustomPaint(
                        size: const Size(double.infinity, 200),
                        painter: SparklePainter(
                          sparkles: _sparkles,
                          animation: _sparkleAnimation,
                        ),
                      ),
                    
                    // Main content
                    _buildContent(),
                    
                    // Dismiss indicator
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Trade completed header
          const Text(
            'TRADE COMPLETED',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // PnL Display
          _buildPnLDisplay(),
          
          const SizedBox(height: 16),
          
          // XP Gained
          _buildXpDisplay(),
          
          // Drip earned (if any)
          if (widget.summary.dripRarity != null) ...[
            const SizedBox(height: 16),
            _buildDripDisplay(),
          ],
          
          // Total XP (if provided)
          if (widget.summary.totalXp != null) ...[
            const SizedBox(height: 12),
            _buildTotalXpDisplay(),
          ],
        ],
      ),
    );
  }

  Widget _buildPnLDisplay() {
    final isProfit = widget.summary.pnl > 0;
    final pnlText = isProfit 
        ? '+${widget.summary.pnl.toStringAsFixed(2)}%'
        : '${widget.summary.pnl.toStringAsFixed(2)}%';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isProfit ? Icons.trending_up : Icons.trending_down,
          color: isProfit ? Colors.green : Colors.red,
          size: 32,
        ),
        const SizedBox(width: 12),
        Text(
          pnlText,
          style: TextStyle(
            color: isProfit ? Colors.green : Colors.red,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildXpDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.cyan.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.cyan.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.stars,
            color: Colors.cyan,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            '+${_xpCountAnimation.value.round()} XP',
            style: const TextStyle(
              color: Colors.cyan,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDripDisplay() {
    final rarityColor = _getDripRarityColor(widget.summary.dripRarity!);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: rarityColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rarityColor.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: rarityColor.withValues(alpha: 0.3 * _glowAnimation.value),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events,
            color: rarityColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'Drip Earned!',
            style: TextStyle(
              color: rarityColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: rarityColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.summary.dripRarity!.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalXpDisplay() {
    return Text(
      'Your total XP is now ${widget.summary.totalXp}',
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  List<Color> _getGradientColors() {
    if (widget.summary.pnl > 0) {
      return [
        Colors.green.withValues(alpha: 0.8),
        Colors.green.withValues(alpha: 0.6),
        Colors.grey[900]!,
      ];
    } else {
      return [
        Colors.red.withValues(alpha: 0.6),
        Colors.red.withValues(alpha: 0.4),
        Colors.grey[900]!,
      ];
    }
  }

  Color _getBorderColor() {
    if (widget.summary.dripRarity != null) {
      return _getDripRarityColor(widget.summary.dripRarity!);
    }
    return widget.summary.pnl > 0 ? Colors.green : Colors.red;
  }

  Color _getDripRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return Colors.grey;
      case 'rare':
        return Colors.blue;
      case 'epic':
        return Colors.purple;
      case 'legendary':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class SparkleParticle {
  final Offset position;
  final double size;
  final double opacity;
  final double twinkleSpeed;

  SparkleParticle({
    required this.position,
    required this.size,
    required this.opacity,
    required this.twinkleSpeed,
  });
}

class SparklePainter extends CustomPainter {
  final List<SparkleParticle> sparkles;
  final Animation<double> animation;

  SparklePainter({
    required this.sparkles,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (var sparkle in sparkles) {
      final twinkle = math.sin(animation.value * math.pi * 2 * sparkle.twinkleSpeed) * 0.5 + 0.5;
      final opacity = sparkle.opacity * twinkle;

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final x = centerX + sparkle.position.dx;
      final y = centerY + sparkle.position.dy;

      canvas.drawCircle(Offset(x, y), sparkle.size, paint);
      
      // Add cross sparkle effect
      canvas.drawLine(
        Offset(x - sparkle.size * 2, y),
        Offset(x + sparkle.size * 2, y),
        paint..strokeWidth = 1,
      );
      canvas.drawLine(
        Offset(x, y - sparkle.size * 2),
        Offset(x, y + sparkle.size * 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Utility class for easy usage
class TraderSummaryCardHelper {
  /// Show summary after trade completion
  static void showTradeSummary(
    BuildContext context, {
    required double pnl,
    required int xpGained,
    String? dripRarity,
    int? totalXp,
    VoidCallback? onDismiss,
  }) {
    HapticFeedback.lightImpact();
    
    TraderSummaryCard.show(
      context,
      summary: TradeSummary(
        pnl: pnl,
        xpGained: xpGained,
        dripRarity: dripRarity,
        totalXp: totalXp,
      ),
      onDismiss: onDismiss,
    );
  }

  /// Create summary from trade result service
  static TradeSummary fromTradeResult({
    required double pnl,
    required int xpGained,
    String? dripRarity,
    int? currentTotalXp,
  }) {
    return TradeSummary(
      pnl: pnl,
      xpGained: xpGained,
      dripRarity: dripRarity,
      totalXp: currentTotalXp,
    );
  }
}