import 'dart:math' as math;

enum DripRarity {
  common,
  rare,
  epic,
  legendary,
}

class MockTradeResult {
  final double pnl;
  final int xpGained;
  final DripRarity? dripRarity;

  const MockTradeResult({
    required this.pnl,
    required this.xpGained,
    this.dripRarity,
  });

  @override
  String toString() {
    return 'MockTradeResult{pnl: $pnl, xpGained: $xpGained, dripRarity: $dripRarity}';
  }
}

class MockTradeEngine {
  static final _random = math.Random();
  
  static const Map<DripRarity, double> _rarityWeights = {
    DripRarity.common: 0.60,     // 60% chance
    DripRarity.rare: 0.25,       // 25% chance
    DripRarity.epic: 0.12,       // 12% chance
    DripRarity.legendary: 0.03,  // 3% chance
  };

  static const Map<String, double> _assetVolatility = {
    'BTC': 0.8,
    'ETH': 1.0,
    'SOL': 1.4,
    'DOGE': 2.0,
    'STRK': 1.2,
  };

  /// Resolves a trade and returns simulated results
  static MockTradeResult resolveTrade({
    required String direction,
    required int leverage,
    String? asset,
  }) {
    assert(direction == "long" || direction == "short", 
           "Direction must be 'long' or 'short'");
    assert(leverage >= 1 && leverage <= 10, 
           "Leverage must be between 1 and 10");

    final double pnl = _generatePnL(direction, leverage, asset);
    final int xpGained = _calculateXP(pnl, leverage);
    final DripRarity? dripRarity = _rollForDrip(pnl, leverage);

    return MockTradeResult(
      pnl: pnl,
      xpGained: xpGained,
      dripRarity: dripRarity,
    );
  }

  /// Generates realistic PnL based on direction, leverage, and asset volatility
  static double _generatePnL(String direction, int leverage, String? asset) {
    final double volatility = _assetVolatility[asset?.toUpperCase()] ?? 1.0;
    
    // Base price movement (normal distribution around 0)
    final double basePnL = _gaussianRandom() * 0.5 * volatility;
    
    // Apply leverage multiplier
    final double leveragedPnL = basePnL * leverage;
    
    // Add some bias based on direction (slightly favor the house)
    final double directionBias = direction == "long" ? -0.1 : -0.05;
    
    // Cap extreme values
    final double finalPnL = (leveragedPnL + directionBias)
        .clamp(-50.0, 50.0);
    
    return double.parse(finalPnL.toStringAsFixed(2));
  }

  /// Calculates XP based on PnL and leverage
  static int _calculateXP(double pnl, int leverage) {
    // Base XP for participating
    int baseXP = 10;
    
    // Bonus XP for profits
    int profitXP = 0;
    if (pnl > 0) {
      profitXP = (pnl * 5).round(); // 5 XP per 1% profit
    }
    
    // Leverage multiplier (higher leverage = more XP)
    double leverageMultiplier = 1.0 + (leverage - 1) * 0.1;
    
    // Consolation XP for losses (smaller amount)
    int consolationXP = 0;
    if (pnl < 0) {
      consolationXP = math.max(5, (pnl.abs() * 1.5).round());
    }
    
    int totalXP = ((baseXP + profitXP + consolationXP) * leverageMultiplier).round();
    
    return math.max(5, totalXP); // Minimum 5 XP
  }

  /// Rolls for drip NFT based on performance and leverage
  static DripRarity? _rollForDrip(double pnl, int leverage) {
    // Base drop chance (40% for any drip)
    double baseDripChance = 0.4;
    
    // Increase chance based on profit
    if (pnl > 0) {
      baseDripChance += pnl * 0.01; // +1% per 1% profit
    }
    
    // Increase chance based on leverage
    baseDripChance += (leverage - 1) * 0.05; // +5% per leverage level
    
    // Big win bonus
    if (pnl > 10) {
      baseDripChance += 0.2; // +20% for big wins
    }
    
    // Cap at 80% max chance
    baseDripChance = math.min(0.8, baseDripChance);
    
    // Roll for drip
    if (_random.nextDouble() > baseDripChance) {
      return null; // No drip
    }
    
    // Determine rarity based on performance
    Map<DripRarity, double> adjustedWeights = Map.from(_rarityWeights);
    
    if (pnl > 5) {
      // Boost rare+ chances for good performance
      adjustedWeights[DripRarity.rare] = adjustedWeights[DripRarity.rare]! * 1.5;
      adjustedWeights[DripRarity.epic] = adjustedWeights[DripRarity.epic]! * 2.0;
      adjustedWeights[DripRarity.legendary] = adjustedWeights[DripRarity.legendary]! * 3.0;
    }
    
    if (leverage >= 8) {
      // High leverage bonus
      adjustedWeights[DripRarity.epic] = adjustedWeights[DripRarity.epic]! * 1.5;
      adjustedWeights[DripRarity.legendary] = adjustedWeights[DripRarity.legendary]! * 2.0;
    }
    
    return _rollWeightedRarity(adjustedWeights);
  }

  /// Rolls for rarity based on weighted probabilities
  static DripRarity _rollWeightedRarity(Map<DripRarity, double> weights) {
    double totalWeight = weights.values.reduce((a, b) => a + b);
    double roll = _random.nextDouble() * totalWeight;
    
    double currentWeight = 0;
    for (final entry in weights.entries) {
      currentWeight += entry.value;
      if (roll <= currentWeight) {
        return entry.key;
      }
    }
    
    return DripRarity.common; // Fallback
  }

  /// Generates a random number with normal distribution (mean=0, std=1)
  static double _gaussianRandom() {
    // Box-Muller transform for normal distribution
    static double? spare;
    if (spare != null) {
      double result = spare!;
      spare = null;
      return result;
    }
    
    double u = _random.nextDouble();
    double v = _random.nextDouble();
    double mag = math.sqrt(-2.0 * math.log(u));
    spare = mag * math.cos(2.0 * math.pi * v);
    return mag * math.sin(2.0 * math.pi * v);
  }

  /// Utility method to simulate multiple trades for testing
  static List<MockTradeResult> simulateTrades({
    required String direction,
    required int leverage,
    String? asset,
    int count = 10,
  }) {
    return List.generate(count, (_) => resolveTrade(
      direction: direction,
      leverage: leverage,
      asset: asset,
    ));
  }

  /// Get statistics for a list of trade results
  static Map<String, dynamic> getTradeStats(List<MockTradeResult> results) {
    if (results.isEmpty) return {};
    
    final pnls = results.map((r) => r.pnl).toList();
    final xps = results.map((r) => r.xpGained).toList();
    final drips = results.where((r) => r.dripRarity != null).toList();
    
    return {
      'totalTrades': results.length,
      'avgPnL': pnls.reduce((a, b) => a + b) / pnls.length,
      'avgXP': xps.reduce((a, b) => a + b) / xps.length,
      'dripRate': drips.length / results.length,
      'profitableTrades': pnls.where((p) => p > 0).length,
      'winRate': pnls.where((p) => p > 0).length / pnls.length,
    };
  }
}