import 'package:flutter/foundation.dart';
import '../models/ecosystem_models.dart';
import '../../territory/models/territory_models.dart';
import '../../trade/state/trade_tracker_provider.dart';

class EcosystemService {
  static const String _storageKey = 'trading_ecosystem';
  
  // Mock data for demo purposes
  final Map<String, TradingEcosystem> _ecosystems = {};
  final Map<String, List<EcosystemAchievement>> _userAchievements = {};

  EcosystemService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Create sample ecosystem for demo
    final sampleEcosystem = EcosystemFactory.createSampleEcosystem('current_user');
    _ecosystems['current_user'] = sampleEcosystem;

    // Create achievements
    _userAchievements['current_user'] = [
      EcosystemAchievement.getAvailableAchievements().first,
    ];
  }

  // Get user's trading ecosystem
  Future<TradingEcosystem?> getUserEcosystem(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate API delay
    return _ecosystems[userId];
  }

  // Update ecosystem based on trading activity
  Future<TradingEcosystem> updateEcosystemFromTrade(
    String userId,
    TradePosition trade,
    bool isSuccess,
  ) async {
    final ecosystem = _ecosystems[userId] ?? _createNewEcosystem(userId);
    
    // Update stats
    final updatedStats = ecosystem.stats.copyWith(
      totalTrades: ecosystem.stats.totalTrades + 1,
      successfulTrades: ecosystem.stats.successfulTrades + (isSuccess ? 1 : 0),
      totalVolume: ecosystem.stats.totalVolume + trade.size,
      totalPnL: ecosystem.stats.totalPnL + trade.pnl,
    );

    // Check for territory progress
    final updatedTerritories = await _updateTerritoryProgress(
      ecosystem.controlledTerritories,
      trade,
      isSuccess,
    );

    // Check for completed murals
    final newMurals = await _checkForCompletedMurals(
      updatedTerritories,
      ecosystem.completedMurals,
    );

    // Recalculate level
    final newLevel = TradingEcosystem.calculateLevel(updatedTerritories, updatedStats);

    final updatedEcosystem = ecosystem.copyWith(
      level: newLevel,
      controlledTerritories: updatedTerritories,
      completedMurals: [...ecosystem.completedMurals, ...newMurals],
      stats: updatedStats,
      lastUpdated: DateTime.now(),
    );

    _ecosystems[userId] = updatedEcosystem;

    // Check for new achievements
    await _checkAchievements(userId, updatedEcosystem);

    return updatedEcosystem;
  }

  // Create a new ecosystem for first-time users
  TradingEcosystem _createNewEcosystem(String userId) {
    return TradingEcosystem(
      userId: userId,
      level: EcosystemLevel.rookie,
      controlledTerritories: [],
      completedMurals: [],
      stats: const EcosystemStats(
        totalTrades: 0,
        successfulTrades: 0,
        totalVolume: 0.0,
        totalPnL: 0.0,
        daysActive: 1,
        streaksBroken: 0,
        territoriesLost: 0,
        averageHoldTime: Duration(hours: 1),
        districtDominance: {},
      ),
      displayName: 'New Writer',
      dominantStyle: ArtworkStyle.graffiti,
      lastUpdated: DateTime.now(),
    );
  }

  // Update territory progress based on successful trades
  Future<List<Territory>> _updateTerritoryProgress(
    List<Territory> territories,
    TradePosition trade,
    bool isSuccess,
  ) async {
    if (!isSuccess) return territories;

    // Get available territories if user has none
    if (territories.isEmpty) {
      final availableTerritories = TerritoryData.getHongKongTerritories()
          .where((t) => t.prestige <= 60) // Start with easier territories
          .take(1)
          .toList();
      
      if (availableTerritories.isNotEmpty) {
        return [
          availableTerritories.first.copyWith(
            status: TerritoryStatus.inProgress,
            completedTrades: 1,
          )
        ];
      }
    }

    // Progress existing territories
    final updatedTerritories = <Territory>[];
    for (final territory in territories) {
      if (territory.status == TerritoryStatus.inProgress) {
        final newCompletedTrades = territory.completedTrades + 1;
        final isCompleted = newCompletedTrades >= territory.requiredTrades;
        
        updatedTerritories.add(territory.copyWith(
          completedTrades: newCompletedTrades,
          status: isCompleted ? TerritoryStatus.conquered : territory.status,
          conqueredAt: isCompleted ? DateTime.now() : territory.conqueredAt,
        ));
      } else {
        updatedTerritories.add(territory);
      }
    }

    // Add new territory if current ones are completed
    final hasInProgress = updatedTerritories.any((t) => t.status == TerritoryStatus.inProgress);
    if (!hasInProgress && updatedTerritories.length < 10) {
      final allTerritories = TerritoryData.getHongKongTerritories();
      final controlledIds = updatedTerritories.map((t) => t.id).toSet();
      final availableTerritory = allTerritories
          .where((t) => !controlledIds.contains(t.id))
          .firstOrNull;
      
      if (availableTerritory != null) {
        updatedTerritories.add(availableTerritory.copyWith(
          status: TerritoryStatus.inProgress,
          completedTrades: 0,
        ));
      }
    }

    return updatedTerritories;
  }

  // Check for completed murals
  Future<List<CompletedMural>> _checkForCompletedMurals(
    List<Territory> territories,
    List<CompletedMural> existingMurals,
  ) async {
    final newMurals = <CompletedMural>[];
    final existingMuralTerritories = existingMurals.map((m) => m.territoryId).toSet();

    for (final territory in territories) {
      if (territory.isConquered && !existingMuralTerritories.contains(territory.id)) {
        final mural = _generateMural(territory);
        newMurals.add(mural);
      }
    }

    return newMurals;
  }

  // Generate a mural for a conquered territory
  CompletedMural _generateMural(Territory territory) {
    final styles = ArtworkStyle.values;
    final selectedStyle = styles[territory.prestige % styles.length];
    
    // Determine rarity based on territory prestige and completion metrics
    MuralRarity rarity;
    if (territory.prestige >= 100) {
      rarity = MuralRarity.legendary;
    } else if (territory.prestige >= 85) {
      rarity = MuralRarity.epic;
    } else if (territory.prestige >= 70) {
      rarity = MuralRarity.rare;
    } else {
      rarity = MuralRarity.common;
    }

    return CompletedMural(
      id: 'mural_${territory.id}_${DateTime.now().millisecondsSinceEpoch}',
      territoryId: territory.id,
      name: '${territory.name} Masterpiece',
      style: selectedStyle,
      layers: territory.artPieces.map((piece) => ArtLayer(
        id: '${piece.id}_layer',
        type: piece.type,
        name: piece.name,
        color: piece.color,
        opacity: 0.9,
        effects: {
          'glow': rarity.index > 1,
          'intensity': rarity.index * 0.2,
        },
      )).toList(),
      completedAt: DateTime.now(),
      tradesRequired: territory.requiredTrades,
      dominantColor: territory.themeColor,
      complexity: (territory.prestige / 100).clamp(0.3, 1.0),
      tags: [
        territory.district.name,
        selectedStyle.name,
        'conquered',
        'streetart',
      ],
      rarity: rarity,
      shareableData: {
        'completion_time': '${territory.requiredTrades} trades',
        'district': territory.district.name,
        'prestige': territory.prestige,
        'style': selectedStyle.name,
      },
    );
  }

  // Check for new achievements
  Future<void> _checkAchievements(String userId, TradingEcosystem ecosystem) async {
    final currentAchievements = _userAchievements[userId] ?? [];
    final currentIds = currentAchievements.map((a) => a.id).toSet();
    final availableAchievements = EcosystemAchievement.getAvailableAchievements();

    for (final achievement in availableAchievements) {
      if (currentIds.contains(achievement.id)) continue;

      bool unlocked = false;
      switch (achievement.id) {
        case 'first_tag':
          unlocked = ecosystem.territoryCount >= 1;
          break;
        case 'district_master':
          unlocked = _hasCompletedDistrict(ecosystem);
          break;
        case 'neon_legend':
          unlocked = ecosystem.completedMurals
              .where((m) => m.rarity == MuralRarity.legendary)
              .length >= 10;
          break;
        case 'hong_kong_king':
          unlocked = _hasAllDistricts(ecosystem);
          break;
      }

      if (unlocked) {
        _userAchievements[userId] = [...currentAchievements, achievement];
        debugPrint('🏆 Achievement unlocked: ${achievement.title}');
      }
    }
  }

  bool _hasCompletedDistrict(TradingEcosystem ecosystem) {
    final districtCounts = <TerritoryDistrict, int>{};
    for (final territory in ecosystem.controlledTerritories) {
      if (territory.isConquered) {
        districtCounts[territory.district] = 
            (districtCounts[territory.district] ?? 0) + 1;
      }
    }
    
    // Check if any district has all its territories conquered
    final allTerritories = TerritoryData.getHongKongTerritories();
    for (final district in TerritoryDistrict.values) {
      final totalInDistrict = allTerritories
          .where((t) => t.district == district)
          .length;
      final conqueredInDistrict = districtCounts[district] ?? 0;
      
      if (conqueredInDistrict >= totalInDistrict) {
        return true;
      }
    }
    
    return false;
  }

  bool _hasAllDistricts(TradingEcosystem ecosystem) {
    final representedDistricts = ecosystem.controlledTerritories
        .where((t) => t.isConquered)
        .map((t) => t.district)
        .toSet();
    
    return representedDistricts.length >= TerritoryDistrict.values.length;
  }

  // Get user achievements
  Future<List<EcosystemAchievement>> getUserAchievements(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _userAchievements[userId] ?? [];
  }

  // Generate shareable content for ecosystem
  Future<EcosystemShareData> generateShareData(TradingEcosystem ecosystem) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate image generation
    
    return EcosystemShareData(
      ecosystemId: ecosystem.userId,
      imageUrl: 'https://mock.streetcred.com/ecosystem/${ecosystem.userId}.png',
      title: '${ecosystem.displayName}\'s Hong Kong Empire',
      description: ecosystem.ecosystemDescription,
      hashtags: [
        'StreetCredClash',
        'HongKongStreetArt',
        ecosystem.dominantStyle.name,
        ecosystem.level.name,
        'TradingArt',
      ],
      stats: {
        'level': ecosystem.levelDisplayName,
        'territories': ecosystem.territoryCount,
        'murals': ecosystem.muralCount,
        'winRate': ecosystem.completionRate,
        'pnl': ecosystem.stats.totalPnL,
        'volume': ecosystem.stats.totalVolume,
      },
      generatedAt: DateTime.now(),
    );
  }

  // Get leaderboard of top ecosystems
  Future<List<TradingEcosystem>> getEcosystemLeaderboard({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final ecosystems = _ecosystems.values.toList();
    ecosystems.sort((a, b) {
      // Sort by level first, then by territory count, then by PnL
      final levelCompare = b.level.index.compareTo(a.level.index);
      if (levelCompare != 0) return levelCompare;
      
      final territoryCompare = b.territoryCount.compareTo(a.territoryCount);
      if (territoryCompare != 0) return territoryCompare;
      
      return b.stats.totalPnL.compareTo(a.stats.totalPnL);
    });
    
    return ecosystems.take(limit).toList();
  }

  // Compare ecosystems
  Future<Map<String, dynamic>> compareEcosystems(
    TradingEcosystem ecosystem1,
    TradingEcosystem ecosystem2,
  ) async {
    return {
      'level_comparison': {
        'user1': ecosystem1.levelDisplayName,
        'user2': ecosystem2.levelDisplayName,
        'winner': ecosystem1.level.index > ecosystem2.level.index ? 'user1' : 'user2',
      },
      'territory_comparison': {
        'user1': ecosystem1.territoryCount,
        'user2': ecosystem2.territoryCount,
        'winner': ecosystem1.territoryCount > ecosystem2.territoryCount ? 'user1' : 'user2',
      },
      'mural_comparison': {
        'user1': ecosystem1.muralCount,
        'user2': ecosystem2.muralCount,
        'winner': ecosystem1.muralCount > ecosystem2.muralCount ? 'user1' : 'user2',
      },
      'performance_comparison': {
        'user1': ecosystem1.completionRate,
        'user2': ecosystem2.completionRate,
        'winner': ecosystem1.completionRate > ecosystem2.completionRate ? 'user1' : 'user2',
      },
    };
  }

  // Save ecosystem data (in real app would save to secure storage)
  Future<void> saveEcosystem(TradingEcosystem ecosystem) async {
    _ecosystems[ecosystem.userId] = ecosystem;
    debugPrint('💾 Ecosystem saved for user ${ecosystem.userId}');
  }

  // Reset ecosystem (for debugging/testing)
  Future<void> resetEcosystem(String userId) async {
    _ecosystems[userId] = _createNewEcosystem(userId);
    _userAchievements[userId] = [];
    debugPrint('🔄 Ecosystem reset for user $userId');
  }
}