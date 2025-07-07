import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../app/theme/street_cred_theme.dart';
import '../../../app/theme/street_cred_design_system.dart';
import '../models/territory_models.dart';

class TerritoryCard extends StatefulWidget {
  final Territory territory;
  final VoidCallback? onTap;

  const TerritoryCard({
    Key? key,
    required this.territory,
    this.onTap,
  }) : super(key: key);

  @override
  State<TerritoryCard> createState() => _TerritoryCardState();
}

class _TerritoryCardState extends State<TerritoryCard>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _progressController;
  late Animation<double> _glowAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: widget.territory.completionPercentage)
        .animate(CurvedAnimation(parent: _progressController, curve: Curves.easeOut));

    if (widget.territory.isConquered) {
      _glowController.repeat(reverse: true);
    }
    
    _progressController.forward();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.territory.canTrade ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_glowAnimation, _progressAnimation]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.territory.themeColor.withValues(alpha: 0.3),
                  widget.territory.themeColor.withValues(alpha: 0.1),
                  StreetCredTheme.darkGrey,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.territory.isConquered 
                    ? widget.territory.themeColor
                    : widget.territory.themeColor.withValues(alpha: 0.5),
                width: widget.territory.isConquered ? 3 : 2,
              ),
              boxShadow: [
                if (widget.territory.isConquered)
                  BoxShadow(
                    color: widget.territory.themeColor.withValues(alpha: _glowAnimation.value * 0.6),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
              ],
            ),
            child: Stack(
              children: [
                // Art preview background
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: CustomPaint(
                      painter: TerritoryArtPainter(
                        territory: widget.territory,
                        animationValue: _progressAnimation.value,
                      ),
                    ),
                  ),
                ),

                // Content overlay
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(),
                          style: StreetCredDesignSystem.captionStyle().copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Territory info
                      Text(
                        widget.territory.name,
                        style: StreetCredDesignSystem.subtitleStyle(
                          widget.territory.themeColor,
                        ).copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        _getDistrictName(),
                        style: StreetCredDesignSystem.captionStyle().copyWith(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Progress bar
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progressAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.territory.themeColor,
                                  widget.territory.themeColor.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Progress text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${widget.territory.completedTrades}/${widget.territory.requiredTrades}',
                            style: StreetCredDesignSystem.captionStyle().copyWith(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                color: StreetCredTheme.neonYellow,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${widget.territory.prestige}',
                                style: StreetCredDesignSystem.captionStyle().copyWith(
                                  fontSize: 10,
                                  color: StreetCredTheme.neonYellow,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Locked overlay
                if (!widget.territory.canTrade)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lock,
                          color: Colors.white54,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.territory.status) {
      case TerritoryStatus.locked:
        return Colors.grey;
      case TerritoryStatus.inProgress:
        return StreetCredTheme.neonYellow;
      case TerritoryStatus.conquered:
        return StreetCredTheme.neonGreen;
      case TerritoryStatus.legendary:
        return StreetCredTheme.neonPink;
    }
  }

  String _getStatusText() {
    switch (widget.territory.status) {
      case TerritoryStatus.locked:
        return 'LOCKED';
      case TerritoryStatus.inProgress:
        return 'ACTIVE';
      case TerritoryStatus.conquered:
        return 'OWNED';
      case TerritoryStatus.legendary:
        return 'LEGEND';
    }
  }

  String _getDistrictName() {
    switch (widget.territory.district) {
      case TerritoryDistrict.central:
        return '中環';
      case TerritoryDistrict.tsimShaTsui:
        return '尖沙咀';
      case TerritoryDistrict.wanChai:
        return '灣仔';
      case TerritoryDistrict.causewyBay:
        return '銅鑼灣';
    }
  }
}

class TerritoryArtPainter extends CustomPainter {
  final Territory territory;
  final double animationValue;

  TerritoryArtPainter({
    required this.territory,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw simplified street art based on territory progress
    final progress = territory.completionPercentage * animationValue;
    
    // Background
    _drawBackground(canvas, size, progress);
    
    // Art elements based on completed pieces
    _drawArtElements(canvas, size, progress);
  }

  void _drawBackground(Canvas canvas, Size size, double progress) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Base background
    paint.color = territory.themeColor.withValues(alpha: 0.1);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Grid pattern
    paint
      ..color = territory.themeColor.withValues(alpha: 0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < size.width; i += 20) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }

    for (int i = 0; i < size.height; i += 20) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }
  }

  void _drawArtElements(Canvas canvas, Size size, double progress) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw art pieces based on completion
    for (int i = 0; i < territory.artPieces.length; i++) {
      final piece = territory.artPieces[i];
      final pieceProgress = piece.progress * animationValue;
      
      if (pieceProgress > 0) {
        _drawArtPiece(canvas, size, piece, pieceProgress, i);
      }
    }
  }

  void _drawArtPiece(Canvas canvas, Size size, ArtPiece piece, double progress, int index) {
    final paint = Paint()
      ..color = piece.color.withValues(alpha: 0.8 * progress)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    switch (piece.type) {
      case ArtPieceType.background:
        // Draw background shapes
        canvas.drawCircle(
          Offset(centerX, centerY),
          (size.width * 0.3) * progress,
          paint,
        );
        break;

      case ArtPieceType.character:
        // Draw character silhouette
        final path = Path();
        path.moveTo(centerX, centerY - 20 * progress);
        path.lineTo(centerX + 15 * progress, centerY + 10 * progress);
        path.lineTo(centerX - 15 * progress, centerY + 10 * progress);
        path.close();
        canvas.drawPath(path, paint);
        break;

      case ArtPieceType.details:
        // Draw detail elements
        for (int i = 0; i < (progress * 5).round(); i++) {
          canvas.drawCircle(
            Offset(
              centerX + (i - 2) * 10 * progress,
              centerY + 20,
            ),
            3 * progress,
            paint,
          );
        }
        break;

      case ArtPieceType.effects:
        // Draw effect sparkles
        final sparkleCount = (progress * 8).round();
        for (int i = 0; i < sparkleCount; i++) {
          final angle = (i / sparkleCount) * 2 * math.pi;
          final radius = 25 * progress;
          final x = centerX + math.cos(angle) * radius;
          final y = centerY + math.sin(angle) * radius;
          
          canvas.drawCircle(
            Offset(x, y),
            2 * progress,
            paint..color = piece.color.withValues(alpha: 0.6 * progress),
          );
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant TerritoryArtPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.territory.completedTrades != territory.completedTrades;
  }
}