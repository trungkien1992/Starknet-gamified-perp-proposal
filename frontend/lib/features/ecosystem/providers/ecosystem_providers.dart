import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ecosystem_models.dart';
import '../services/ecosystem_service.dart';
import '../../trade/state/trade_tracker_provider.dart';

// Service provider
final ecosystemServiceProvider = Provider<EcosystemService>((ref) {
  return EcosystemService();
});

// Current user's ecosystem
final userEcosystemProvider = StateNotifierProvider<UserEcosystemNotifier, AsyncValue<TradingEcosystem?>>((ref) {
  final ecosystemService = ref.read(ecosystemServiceProvider);
  return UserEcosystemNotifier(ecosystemService);
});

class UserEcosystemNotifier extends StateNotifier<AsyncValue<TradingEcosystem?>> {
  final EcosystemService _ecosystemService;

  UserEcosystemNotifier(this._ecosystemService) : super(const AsyncValue.loading()) {
    _loadEcosystem();
  }

  Future<void> _loadEcosystem() async {
    try {
      final ecosystem = await _ecosystemService.getUserEcosystem('current_user');
      state = AsyncValue.data(ecosystem);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateFromTrade(TradePosition trade, bool isSuccess) async {
    final currentEcosystem = state.value;
    if (currentEcosystem == null) return;

    try {
      state = const AsyncValue.loading();
      final updatedEcosystem = await _ecosystemService.updateEcosystemFromTrade(
        'current_user',
        trade,
        isSuccess,
      );
      state = AsyncValue.data(updatedEcosystem);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshEcosystem() async {
    await _loadEcosystem();
  }

  Future<void> resetEcosystem() async {
    try {
      await _ecosystemService.resetEcosystem('current_user');
      await _loadEcosystem();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// User achievements
final userAchievementsProvider = FutureProvider<List<EcosystemAchievement>>((ref) async {
  final ecosystemService = ref.read(ecosystemServiceProvider);
  return await ecosystemService.getUserAchievements('current_user');
});

// Ecosystem leaderboard
final ecosystemLeaderboardProvider = FutureProvider<List<TradingEcosystem>>((ref) async {
  final ecosystemService = ref.read(ecosystemServiceProvider);
  return await ecosystemService.getEcosystemLeaderboard();
});

// Ecosystem share data
final ecosystemShareDataProvider = FutureProvider.family<EcosystemShareData?, TradingEcosystem?>((ref, ecosystem) async {
  if (ecosystem == null) return null;
  
  final ecosystemService = ref.read(ecosystemServiceProvider);
  return await ecosystemService.generateShareData(ecosystem);
});

// Available achievements
final availableAchievementsProvider = Provider<List<EcosystemAchievement>>((ref) {
  return EcosystemAchievement.getAvailableAchievements();
});

// Ecosystem stats computed providers
final ecosystemStatsProvider = Provider<Map<String, dynamic>?>((ref) {
  final ecosystemAsync = ref.watch(userEcosystemProvider);
  
  return ecosystemAsync.when(
    data: (ecosystem) {
      if (ecosystem == null) return null;
      
      return {
        'level': ecosystem.levelDisplayName,
        'territories': ecosystem.territoryCount,
        'murals': ecosystem.muralCount,
        'winRate': ecosystem.completionRate,
        'totalTrades': ecosystem.stats.totalTrades,
        'totalPnL': ecosystem.stats.totalPnL,
        'daysActive': ecosystem.stats.daysActive,
        'dominantStyle': ecosystem.dominantStyle.name,
        'nextLevelProgress': _calculateLevelProgress(ecosystem),
      };
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

double _calculateLevelProgress(TradingEcosystem ecosystem) {
  // Calculate progress toward next level
  final currentLevel = ecosystem.level;
  final territories = ecosystem.territoryCount;
  final winRate = ecosystem.completionRate;
  
  switch (currentLevel) {
    case EcosystemLevel.rookie:
      // Need 3 territories for rising
      return (territories / 3).clamp(0.0, 1.0);
    case EcosystemLevel.rising:
      // Need 6 territories for veteran
      return ((territories - 3) / 3).clamp(0.0, 1.0);
    case EcosystemLevel.veteran:
      // Need 9 territories for master
      return ((territories - 6) / 3).clamp(0.0, 1.0);
    case EcosystemLevel.master:
      // Need 13+ territories for legend
      return ((territories - 9) / 4).clamp(0.0, 1.0);
    case EcosystemLevel.legend:
      return 1.0; // Max level
  }
}

// Territory progression
final territoryProgressionProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final ecosystemAsync = ref.watch(userEcosystemProvider);
  
  return ecosystemAsync.when(
    data: (ecosystem) {
      if (ecosystem == null) return [];
      
      return ecosystem.controlledTerritories.map((territory) => {
        'territory': territory,
        'progress': territory.completionPercentage,
        'timeToComplete': _estimateTimeToComplete(territory),
        'difficulty': _calculateDifficulty(territory),
        'rewards': _calculateRewards(territory),
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

Duration _estimateTimeToComplete(Territory territory) {
  final remainingTrades = territory.requiredTrades - territory.completedTrades;
  // Assume 1 trade per hour average
  return Duration(hours: remainingTrades);
}

String _calculateDifficulty(Territory territory) {
  if (territory.prestige >= 90) return 'Legendary';
  if (territory.prestige >= 75) return 'Hard';
  if (territory.prestige >= 60) return 'Medium';
  return 'Easy';
}

Map<String, dynamic> _calculateRewards(Territory territory) {
  return {
    'xp': territory.prestige * 10,
    'ink': territory.prestige,
    'muralRarity': territory.prestige >= 85 ? 'Epic' : 
                   territory.prestige >= 70 ? 'Rare' : 'Common',
  };
}

// Recent murals (last 5 completed)
final recentMuralsProvider = Provider<List<CompletedMural>>((ref) {
  final ecosystemAsync = ref.watch(userEcosystemProvider);
  
  return ecosystemAsync.when(
    data: (ecosystem) {
      if (ecosystem == null) return [];
      
      final murals = [...ecosystem.completedMurals];
      murals.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return murals.take(5).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// District dominance
final districtDominanceProvider = Provider<Map<TerritoryDistrict, double>>((ref) {
  final ecosystemAsync = ref.watch(userEcosystemProvider);
  
  return ecosystemAsync.when(
    data: (ecosystem) {
      if (ecosystem == null) return {};
      
      final districtProgress = <TerritoryDistrict, double>{};
      
      for (final district in TerritoryDistrict.values) {
        final userTerritories = ecosystem.controlledTerritories
            .where((t) => t.district == district && t.isConquered)
            .length;
        
        // Mock total territories per district (in real app would be dynamic)
        final totalTerritories = district == TerritoryDistrict.central ? 3 : 2;
        
        districtProgress[district] = userTerritories / totalTerritories;
      }
      
      return districtProgress;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

// Ecosystem comparison provider
final ecosystemComparisonProvider = StateNotifierProvider<EcosystemComparisonNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  final ecosystemService = ref.read(ecosystemServiceProvider);
  return EcosystemComparisonNotifier(ecosystemService);
});

class EcosystemComparisonNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final EcosystemService _ecosystemService;

  EcosystemComparisonNotifier(this._ecosystemService) : super(const AsyncValue.data(null));

  Future<void> compareWithUser(TradingEcosystem userEcosystem, String otherUserId) async {
    state = const AsyncValue.loading();
    try {
      final otherEcosystem = await _ecosystemService.getUserEcosystem(otherUserId);
      if (otherEcosystem != null) {
        final comparison = await _ecosystemService.compareEcosystems(userEcosystem, otherEcosystem);
        state = AsyncValue.data(comparison);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearComparison() {
    state = const AsyncValue.data(null);
  }
}

// Listen to trade completion and update ecosystem
final ecosystemTradeListenerProvider = Provider<void>((ref) {
  ref.listen(activePositionsProvider, (previous, next) {
    next.whenData((positions) {
      if (previous?.value != null) {
        final prevPositions = previous!.value!;
        final currentPositions = positions;
        
        // Find completed trades
        for (final prevPosition in prevPositions) {
          final currentPosition = currentPositions
              .where((p) => p.id == prevPosition.id)
              .firstOrNull;
          
          // If position is no longer active, it was closed
          if (currentPosition == null && prevPosition.isActive) {
            final isSuccess = prevPosition.pnl > 0;
            ref.read(userEcosystemProvider.notifier)
                .updateFromTrade(prevPosition, isSuccess);
          }
        }
      }
    });
  });
});

// Mock ecosystem for other users (for comparison)
final mockEcosystemProvider = Provider.family<TradingEcosystem, String>((ref, userId) {
  // Return mock ecosystem for comparison purposes
  return EcosystemFactory.createSampleEcosystem(userId);
});