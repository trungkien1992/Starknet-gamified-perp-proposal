import 'package:flutter/material.dart';
import '../../territory/models/territory_models.dart';

enum EcosystemLevel {
  rookie,      // 0-2 territories
  rising,      // 3-5 territories  
  veteran,     // 6-8 territories
  master,      // 9-12 territories
  legend,      // 13+ territories
}

enum ArtworkStyle {
  cyberpunk,
  traditional,
  abstract,
  neon,
  graffiti,
  digital,
}

class TradingEcosystem {
  final String userId;
  final EcosystemLevel level;
  final List<Territory> controlledTerritories;
  final List<CompletedMural> completedMurals;
  final EcosystemStats stats;
  final String displayName;
  final ArtworkStyle dominantStyle;
  final DateTime lastUpdated;
  final Map<String, dynamic> personalizations;

  const TradingEcosystem({
    required this.userId,
    required this.level,
    required this.controlledTerritories,
    required this.completedMurals,
    required this.stats,
    required this.displayName,
    required this.dominantStyle,
    required this.lastUpdated,
    this.personalizations = const {},
  });

  int get territoryCount => controlledTerritories.length;
  int get muralCount => completedMurals.length;
  
  double get completionRate => stats.totalTrades > 0 
      ? (stats.successfulTrades / stats.totalTrades) 
      : 0.0;

  Color get ecosystemColor {
    switch (level) {
      case EcosystemLevel.rookie:
        return const Color(0xFF00FF41); // Green
      case EcosystemLevel.rising:
        return const Color(0xFF00FFFF); // Cyan
      case EcosystemLevel.veteran:
        return const Color(0xFFFF0080); // Pink
      case EcosystemLevel.master:
        return const Color(0xFFFFD700); // Gold
      case EcosystemLevel.legend:
        return const Color(0xFF9D4EDD); // Purple
    }
  }

  String get levelDisplayName {
    switch (level) {
      case EcosystemLevel.rookie:
        return 'Rookie Writer';
      case EcosystemLevel.rising:
        return 'Rising Artist';
      case EcosystemLevel.veteran:
        return 'Veteran Tagger';
      case EcosystemLevel.master:
        return 'Master Graffiti';
      case EcosystemLevel.legend:
        return 'Legendary King';
    }
  }

  String get ecosystemDescription {
    switch (level) {
      case EcosystemLevel.rookie:
        return 'Just starting to make their mark on Hong Kong streets';
      case EcosystemLevel.rising:
        return 'Building reputation across multiple districts';
      case EcosystemLevel.veteran:
        return 'Established street art presence throughout the city';
      case EcosystemLevel.master:
        return 'Commanding respect from the Hong Kong art scene';
      case EcosystemLevel.legend:
        return 'Living legend of Hong Kong street culture';
    }
  }

  // Calculate ecosystem level based on territories and performance
  static EcosystemLevel calculateLevel(List<Territory> territories, EcosystemStats stats) {
    final territoryCount = territories.length;
    final winRate = stats.totalTrades > 0 ? stats.successfulTrades / stats.totalTrades : 0.0;
    
    // Weighted score: territories * 10 + win rate bonus
    final score = territoryCount * 10 + (winRate * 20);
    
    if (score >= 150) return EcosystemLevel.legend;
    if (score >= 100) return EcosystemLevel.master;
    if (score >= 60) return EcosystemLevel.veteran;
    if (score >= 30) return EcosystemLevel.rising;
    return EcosystemLevel.rookie;
  }

  TradingEcosystem copyWith({
    EcosystemLevel? level,
    List<Territory>? controlledTerritories,
    List<CompletedMural>? completedMurals,
    EcosystemStats? stats,
    String? displayName,
    ArtworkStyle? dominantStyle,
    DateTime? lastUpdated,
    Map<String, dynamic>? personalizations,
  }) {
    return TradingEcosystem(
      userId: userId,
      level: level ?? this.level,
      controlledTerritories: controlledTerritories ?? this.controlledTerritories,
      completedMurals: completedMurals ?? this.completedMurals,
      stats: stats ?? this.stats,
      displayName: displayName ?? this.displayName,
      dominantStyle: dominantStyle ?? this.dominantStyle,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      personalizations: personalizations ?? this.personalizations,
    );
  }
}

class CompletedMural {
  final String id;
  final String territoryId;
  final String name;
  final ArtworkStyle style;
  final List<ArtLayer> layers;
  final DateTime completedAt;
  final int tradesRequired;
  final Color dominantColor;
  final double complexity; // 0.0 to 1.0
  final List<String> tags; // User-defined hashtags
  final MuralRarity rarity;
  final Map<String, dynamic> shareableData;

  const CompletedMural({
    required this.id,
    required this.territoryId,
    required this.name,
    required this.style,
    required this.layers,
    required this.completedAt,
    required this.tradesRequired,
    required this.dominantColor,
    required this.complexity,
    this.tags = const [],
    required this.rarity,
    this.shareableData = const {},
  });

  String get rarityDisplayName {
    switch (rarity) {
      case MuralRarity.common:
        return 'Street Art';
      case MuralRarity.rare:
        return 'Featured Piece';
      case MuralRarity.epic:
        return 'Gallery Worthy';
      case MuralRarity.legendary:
        return 'Masterpiece';
      case MuralRarity.mythic:
        return 'Cultural Icon';
    }
  }

  Color get rarityColor {
    switch (rarity) {
      case MuralRarity.common:
        return Colors.grey;
      case MuralRarity.rare:
        return const Color(0xFF00FFFF);
      case MuralRarity.epic:
        return const Color(0xFF9D4EDD);
      case MuralRarity.legendary:
        return const Color(0xFFFFD700);
      case MuralRarity.mythic:
        return const Color(0xFFFF0080);
    }
  }
}

enum MuralRarity {
  common,
  rare,
  epic,
  legendary,
  mythic,
}

class ArtLayer {
  final String id;
  final ArtPieceType type;
  final String name;
  final Color color;
  final double opacity;
  final Map<String, dynamic> effects; // Glow, shadow, animation properties

  const ArtLayer({
    required this.id,
    required this.type,
    required this.name,
    required this.color,
    this.opacity = 1.0,
    this.effects = const {},
  });
}

class EcosystemStats {
  final int totalTrades;
  final int successfulTrades;
  final double totalVolume;
  final double totalPnL;
  final int daysActive;
  final int streaksBroken;
  final int territoriesLost;
  final Duration averageHoldTime;
  final Map<TerritoryDistrict, int> districtDominance;

  const EcosystemStats({
    required this.totalTrades,
    required this.successfulTrades,
    required this.totalVolume,
    required this.totalPnL,
    required this.daysActive,
    required this.streaksBroken,
    required this.territoriesLost,
    required this.averageHoldTime,
    this.districtDominance = const {},
  });

  double get winRate => totalTrades > 0 ? successfulTrades / totalTrades : 0.0;
  double get averageTradeSize => totalTrades > 0 ? totalVolume / totalTrades : 0.0;
  double get profitPerDay => daysActive > 0 ? totalPnL / daysActive : 0.0;

  EcosystemStats copyWith({
    int? totalTrades,
    int? successfulTrades,
    double? totalVolume,
    double? totalPnL,
    int? daysActive,
    int? streaksBroken,
    int? territoriesLost,
    Duration? averageHoldTime,
    Map<TerritoryDistrict, int>? districtDominance,
  }) {
    return EcosystemStats(
      totalTrades: totalTrades ?? this.totalTrades,
      successfulTrades: successfulTrades ?? this.successfulTrades,
      totalVolume: totalVolume ?? this.totalVolume,
      totalPnL: totalPnL ?? this.totalPnL,
      daysActive: daysActive ?? this.daysActive,
      streaksBroken: streaksBroken ?? this.streaksBroken,
      territoriesLost: territoriesLost ?? this.territoriesLost,
      averageHoldTime: averageHoldTime ?? this.averageHoldTime,
      districtDominance: districtDominance ?? this.districtDominance,
    );
  }
}

class EcosystemAchievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final DateTime unlockedAt;
  final bool isRare;
  final Map<String, dynamic> criteria;

  const EcosystemAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.unlockedAt,
    this.isRare = false,
    this.criteria = const {},
  });

  static List<EcosystemAchievement> getAvailableAchievements() {
    return [
      EcosystemAchievement(
        id: 'first_tag',
        title: 'First Tag',
        description: 'Complete your first territory conquest',
        icon: Icons.brush,
        color: const Color(0xFF00FF41),
        unlockedAt: DateTime.now(),
        criteria: {'territories': 1},
      ),
      EcosystemAchievement(
        id: 'district_master',
        title: 'District Master',
        description: 'Control all territories in a single district',
        icon: Icons.domain,
        color: const Color(0xFF00FFFF),
        unlockedAt: DateTime.now(),
        isRare: true,
        criteria: {'districts_completed': 1},
      ),
      EcosystemAchievement(
        id: 'neon_legend',
        title: 'Neon Legend',
        description: 'Complete 10 legendary murals',
        icon: Icons.auto_awesome,
        color: const Color(0xFFFFD700),
        unlockedAt: DateTime.now(),
        isRare: true,
        criteria: {'legendary_murals': 10},
      ),
      EcosystemAchievement(
        id: 'hong_kong_king',
        title: 'Hong Kong King',
        description: 'Control territories in all districts',
        icon: Icons.emoji_events,
        color: const Color(0xFF9D4EDD),
        unlockedAt: DateTime.now(),
        isRare: true,
        criteria: {'all_districts': true},
      ),
    ];
  }
}

class EcosystemShareData {
  final String ecosystemId;
  final String imageUrl;
  final String title;
  final String description;
  final List<String> hashtags;
  final Map<String, dynamic> stats;
  final DateTime generatedAt;

  const EcosystemShareData({
    required this.ecosystemId,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.hashtags,
    required this.stats,
    required this.generatedAt,
  });

  String get shareText => '''
$title

$description

${hashtags.map((tag) => '#$tag').join(' ')}

🎨 Level: ${stats['level']}
🏢 Territories: ${stats['territories']}
📈 Win Rate: ${(stats['winRate'] * 100).toStringAsFixed(1)}%
💎 Murals: ${stats['murals']}

#StreetCredClash #HongKongStreetArt #CryptArt
  ''';
}

// Factory for creating sample ecosystems
class EcosystemFactory {
  static TradingEcosystem createSampleEcosystem(String userId) {
    final territories = TerritoryData.getHongKongTerritories().take(3).toList();
    final stats = const EcosystemStats(
      totalTrades: 85,
      successfulTrades: 62,
      totalVolume: 15000.0,
      totalPnL: 2750.0,
      daysActive: 28,
      streaksBroken: 2,
      territoriesLost: 1,
      averageHoldTime: Duration(hours: 4),
      districtDominance: {
        TerritoryDistrict.central: 2,
        TerritoryDistrict.tsimShaTsui: 1,
      },
    );

    final murals = [
      CompletedMural(
        id: 'mural_1',
        territoryId: 'central_ifc',
        name: 'Neon Dragon Rising',
        style: ArtworkStyle.cyberpunk,
        layers: [
          const ArtLayer(
            id: 'bg_1',
            type: ArtPieceType.background,
            name: 'City Skyline',
            color: Color(0xFF1a1a2e),
          ),
          const ArtLayer(
            id: 'char_1',
            type: ArtPieceType.character,
            name: 'Dragon',
            color: Color(0xFFFF0080),
            effects: {'glow': true, 'intensity': 0.8},
          ),
        ],
        completedAt: DateTime.now().subtract(const Duration(days: 7)),
        tradesRequired: 25,
        dominantColor: const Color(0xFFFF0080),
        complexity: 0.85,
        tags: ['dragon', 'neon', 'central', 'trading'],
        rarity: MuralRarity.rare,
        shareableData: {
          'completion_time': '7 days',
          'trade_efficiency': 'High',
          'style_points': 95,
        },
      ),
    ];

    return TradingEcosystem(
      userId: userId,
      level: TradingEcosystem.calculateLevel(territories, stats),
      controlledTerritories: territories,
      completedMurals: murals,
      stats: stats,
      displayName: 'Neon Warrior',
      dominantStyle: ArtworkStyle.cyberpunk,
      lastUpdated: DateTime.now(),
      personalizations: {
        'preferred_colors': ['#FF0080', '#00FFFF', '#FFD700'],
        'signature_style': 'cyberpunk_dragon',
        'favorite_district': 'central',
      },
    );
  }
}