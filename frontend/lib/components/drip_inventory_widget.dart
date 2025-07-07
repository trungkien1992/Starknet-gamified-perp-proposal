import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class DripNFT {
  final String name;
  final String rarity;
  final String imageUrl;
  final String? id;

  const DripNFT({
    required this.name,
    required this.rarity,
    required this.imageUrl,
    this.id,
  });
}

class DripInventoryWidget extends StatefulWidget {
  final List<DripNFT> drips;
  final Function(DripNFT)? onDripTap;
  final double cardWidth;
  final double cardHeight;
  final int crossAxisCount;
  final EdgeInsets padding;

  const DripInventoryWidget({
    super.key,
    required this.drips,
    this.onDripTap,
    this.cardWidth = 140.0,
    this.cardHeight = 180.0,
    this.crossAxisCount = 2,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  State<DripInventoryWidget> createState() => _DripInventoryWidgetState();
}

class _DripInventoryWidgetState extends State<DripInventoryWidget>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.drips.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Padding(
          padding: widget.padding,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.crossAxisCount,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: widget.cardWidth / widget.cardHeight,
            ),
            itemCount: widget.drips.length,
            itemBuilder: (context, index) {
              return _buildDripCard(widget.drips[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildDripCard(DripNFT drip) {
    final rarityData = _getRarityData(drip.rarity);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onDripTap?.call(drip);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[900]!,
              Colors.grey[800]!,
            ],
          ),
          border: Border.all(
            color: rarityData.color.withValues(alpha: 0.8),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: rarityData.color.withValues(alpha: 0.3 * _glowAnimation.value),
              blurRadius: rarityData.isHighRarity ? 15 : 8,
              spreadRadius: rarityData.isHighRarity ? 3 : 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background shimmer for high rarity
            if (rarityData.isHighRarity)
              _buildShimmerEffect(rarityData.color),
            
            // Main card content
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image section
                Expanded(
                  flex: 3,
                  child: _buildImageSection(drip, rarityData),
                ),
                
                // Info section
                Expanded(
                  flex: 1,
                  child: _buildInfoSection(drip, rarityData),
                ),
              ],
            ),
            
            // Rarity badge
            Positioned(
              top: 8,
              right: 8,
              child: _buildRarityBadge(rarityData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(DripNFT drip, RarityData rarityData) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rarityData.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: drip.imageUrl.isNotEmpty
            ? Image.network(
                drip.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildLoadingPlaceholder(rarityData);
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildErrorPlaceholder(rarityData);
                },
              )
            : _buildPlaceholderImage(rarityData),
      ),
    );
  }

  Widget _buildInfoSection(DripNFT drip, RarityData rarityData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            drip.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            rarityData.displayName,
            style: TextStyle(
              color: rarityData.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRarityBadge(RarityData rarityData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: rarityData.color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: rarityData.color.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        rarityData.symbol,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildShimmerEffect(Color color) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.1 * _glowAnimation.value),
                Colors.transparent,
                color.withValues(alpha: 0.05 * _glowAnimation.value),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage(RarityData rarityData) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            rarityData.color.withValues(alpha: 0.2),
            rarityData.color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Center(
        child: Icon(
          Icons.emoji_events,
          size: 40,
          color: rarityData.color,
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(RarityData rarityData) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(11),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(rarityData.color),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(RarityData rarityData) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(11),
      ),
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: 30,
          color: rarityData.color.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No Drips Yet',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete trades to earn your first NFT Drips!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  RarityData _getRarityData(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return RarityData(
          color: Colors.grey,
          displayName: 'Common',
          symbol: '●',
          isHighRarity: false,
        );
      case 'rare':
        return RarityData(
          color: Colors.blue,
          displayName: 'Rare',
          symbol: '◆',
          isHighRarity: false,
        );
      case 'epic':
        return RarityData(
          color: Colors.purple,
          displayName: 'Epic',
          symbol: '★',
          isHighRarity: true,
        );
      case 'legendary':
        return RarityData(
          color: Colors.orange,
          displayName: 'Legendary',
          symbol: '✦',
          isHighRarity: true,
        );
      default:
        return RarityData(
          color: Colors.grey,
          displayName: 'Common',
          symbol: '●',
          isHighRarity: false,
        );
    }
  }
}

class RarityData {
  final Color color;
  final String displayName;
  final String symbol;
  final bool isHighRarity;

  const RarityData({
    required this.color,
    required this.displayName,
    required this.symbol,
    required this.isHighRarity,
  });
}

// Extension widget for scrollable inventory
class ScrollableDripInventory extends StatelessWidget {
  final List<DripNFT> drips;
  final Function(DripNFT)? onDripTap;
  final double cardWidth;
  final double cardHeight;
  final int crossAxisCount;

  const ScrollableDripInventory({
    super.key,
    required this.drips,
    this.onDripTap,
    this.cardWidth = 140.0,
    this.cardHeight = 180.0,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: DripInventoryWidget(
        drips: drips,
        onDripTap: onDripTap,
        cardWidth: cardWidth,
        cardHeight: cardHeight,
        crossAxisCount: crossAxisCount,
      ),
    );
  }
}

// Utility class for creating sample data
class DripNFTSamples {
  static List<DripNFT> getSampleDrips() {
    return [
      const DripNFT(
        name: "Golden Crown",
        rarity: "legendary",
        imageUrl: "https://example.com/crown.png",
        id: "drip_001",
      ),
      const DripNFT(
        name: "Neon Shades",
        rarity: "epic",
        imageUrl: "https://example.com/shades.png",
        id: "drip_002",
      ),
      const DripNFT(
        name: "Street Chain",
        rarity: "rare",
        imageUrl: "https://example.com/chain.png",
        id: "drip_003",
      ),
      const DripNFT(
        name: "Basic Cap",
        rarity: "common",
        imageUrl: "https://example.com/cap.png",
        id: "drip_004",
      ),
    ];
  }
}