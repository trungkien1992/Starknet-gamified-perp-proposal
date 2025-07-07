import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/territory_models.dart';
import '../services/territory_service.dart';

// Territory state management
final territoryServiceProvider = Provider<TerritoryService>((ref) => TerritoryService());

final territoriesProvider = StateNotifierProvider<TerritoriesNotifier, List<Territory>>((ref) {
  return TerritoriesNotifier(ref.read(territoryServiceProvider));
});

final currentTerritoryProvider = StateProvider<String?>((ref) => null);

final selectedTerritoryProvider = Provider<Territory?>((ref) {
  final territories = ref.watch(territoriesProvider);
  final currentId = ref.watch(currentTerritoryProvider);
  
  if (currentId == null) return null;
  
  try {
    return territories.firstWhere((t) => t.id == currentId);
  } catch (e) {
    return null;
  }
});

final conqueredTerritoriesProvider = Provider<List<Territory>>((ref) {
  final territories = ref.watch(territoriesProvider);
  return territories.where((t) => t.isConquered).toList();
});

final userPrestigeProvider = Provider<int>((ref) {
  final conquered = ref.watch(conqueredTerritoriesProvider);
  return conquered.fold(0, (total, territory) => total + territory.prestige);
});

final territoryLeaderboardProvider = Provider<List<TerritoryRanking>>((ref) {
  // Mock leaderboard data - in production this would come from backend
  return [
    TerritoryRanking(userId: 'user1', username: 'NeonDragon', prestige: 285, territoriesOwned: 3),
    TerritoryRanking(userId: 'user2', username: 'CentralKing', prestige: 170, territoriesOwned: 2),
    TerritoryRanking(userId: 'user3', username: 'HKArtist', prestige: 145, territoriesOwned: 2),
    TerritoryRanking(userId: 'current', username: 'You', prestige: ref.watch(userPrestigeProvider), territoriesOwned: ref.watch(conqueredTerritoriesProvider).length),
  ]..sort((a, b) => b.prestige.compareTo(a.prestige));
});

class TerritoriesNotifier extends StateNotifier<List<Territory>> {
  final TerritoryService _service;
  
  TerritoriesNotifier(this._service) : super([]) {
    _loadTerritories();
  }
  
  void _loadTerritories() {
    state = _service.getTerritories();
  }
  
  void addTradeProgress(String territoryId, {int tradesCompleted = 1}) {
    state = state.map((territory) {
      if (territory.id == territoryId) {
        final newCompletedTrades = (territory.completedTrades + tradesCompleted)
            .clamp(0, territory.requiredTrades);
        
        final newStatus = _calculateStatus(newCompletedTrades, territory.requiredTrades, territory.status);
        
        return territory.copyWith(
          completedTrades: newCompletedTrades,
          status: newStatus,
          conqueredAt: newStatus == TerritoryStatus.conquered ? DateTime.now() : territory.conqueredAt,
          ownerId: newStatus == TerritoryStatus.conquered ? 'current_user' : territory.ownerId,
          artPieces: _updateArtPieces(territory.artPieces, newCompletedTrades, territory.requiredTrades),
        );
      }
      return territory;
    }).toList();
  }
  
  TerritoryStatus _calculateStatus(int completed, int required, TerritoryStatus currentStatus) {
    if (completed >= required) {
      return currentStatus == TerritoryStatus.conquered 
          ? TerritoryStatus.legendary 
          : TerritoryStatus.conquered;
    } else if (completed > 0) {
      return TerritoryStatus.inProgress;
    } else {
      return TerritoryStatus.locked;
    }
  }
  
  List<ArtPiece> _updateArtPieces(List<ArtPiece> pieces, int completed, int required) {
    final progress = completed / required;
    final piecesPerStage = pieces.length;
    
    return pieces.asMap().entries.map((entry) {
      final index = entry.key;
      final piece = entry.value;
      final pieceThreshold = (index + 1) / piecesPerStage;
      final pieceProgress = (progress / pieceThreshold).clamp(0.0, 1.0);
      
      return piece.copyWith(
        progress: pieceProgress,
        isCompleted: progress >= pieceThreshold,
      );
    }).toList();
  }
  
  void unlockTerritory(String territoryId) {
    state = state.map((territory) {
      if (territory.id == territoryId && territory.status == TerritoryStatus.locked) {
        return territory.copyWith(status: TerritoryStatus.inProgress);
      }
      return territory;
    }).toList();
  }
  
  void resetTerritory(String territoryId) {
    state = state.map((territory) {
      if (territory.id == territoryId) {
        return territory.copyWith(
          completedTrades: 0,
          status: TerritoryStatus.inProgress,
          ownerId: '',
          conqueredAt: null,
          artPieces: territory.artPieces.map((piece) => piece.copyWith(
            progress: 0.0,
            isCompleted: false,
          )).toList(),
        );
      }
      return territory;
    }).toList();
  }
}

class TerritoryRanking {
  final String userId;
  final String username;
  final int prestige;
  final int territoriesOwned;
  
  TerritoryRanking({
    required this.userId,
    required this.username,
    required this.prestige,
    required this.territoriesOwned,
  });
}