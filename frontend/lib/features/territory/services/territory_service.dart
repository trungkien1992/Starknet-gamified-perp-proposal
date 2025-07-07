import '../models/territory_models.dart';

class TerritoryService {
  List<Territory> getTerritories() {
    return TerritoryData.getHongKongTerritories();
  }
  
  Territory? getTerritoryById(String id) {
    try {
      return getTerritories().firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
  
  List<Territory> getTerritoriesByDistrict(TerritoryDistrict district) {
    return getTerritories().where((t) => t.district == district).toList();
  }
  
  List<Territory> getAvailableTerritories() {
    return getTerritories().where((t) => t.canTrade).toList();
  }
  
  bool canUnlockTerritory(String territoryId, int userPrestige) {
    final territory = getTerritoryById(territoryId);
    if (territory == null) return false;
    
    // Unlock logic based on prestige and other territories
    switch (territory.district) {
      case TerritoryDistrict.central:
        return userPrestige >= 100; // Need high prestige for Central
      case TerritoryDistrict.tsimShaTsui:
        return userPrestige >= 50;
      case TerritoryDistrict.wanChai:
        return userPrestige >= 25;
      case TerritoryDistrict.causewyBay:
        return true; // Always unlocked
    }
  }
  
  int calculateTradeContribution(double tradeAmount, double leverage) {
    // Larger trades contribute more to territory progress
    final baseContribution = (tradeAmount * leverage / 100).round().clamp(1, 5);
    return baseContribution;
  }
  
  String getDistrictDisplayName(TerritoryDistrict district) {
    switch (district) {
      case TerritoryDistrict.central:
        return '中環 Central';
      case TerritoryDistrict.tsimShaTsui:
        return '尖沙咀 Tsim Sha Tsui';
      case TerritoryDistrict.wanChai:
        return '灣仔 Wan Chai';
      case TerritoryDistrict.causewyBay:
        return '銅鑼灣 Causeway Bay';
    }
  }
  
  String getTerritoryStatusText(TerritoryStatus status) {
    switch (status) {
      case TerritoryStatus.locked:
        return 'LOCKED';
      case TerritoryStatus.inProgress:
        return 'IN PROGRESS';
      case TerritoryStatus.conquered:
        return 'CONQUERED';
      case TerritoryStatus.legendary:
        return 'LEGENDARY';
    }
  }
  
  /// Calculate XP reward for territory milestone
  int calculateTerritoryXP(Territory territory) {
    return territory.prestige * 10; // Higher prestige = more XP
  }
  
  /// Check if territory conquest unlocks special rewards
  List<String> getConquestRewards(Territory territory) {
    final rewards = <String>[];
    
    if (territory.district == TerritoryDistrict.central) {
      rewards.add('Central District Master NFT');
      rewards.add('VIP Trading Multiplier');
    }
    
    if (territory.prestige >= 100) {
      rewards.add('Legendary Artist Title');
    }
    
    if (territory.status == TerritoryStatus.legendary) {
      rewards.add('Territory Legend NFT');
      rewards.add('Exclusive Spray Can Design');
    }
    
    return rewards;
  }
}