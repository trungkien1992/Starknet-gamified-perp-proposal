import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import '../components/drip_inventory_widget.dart';
import '../components/leaderboard_widget.dart';

/// User profile data structure for mock data
class UserProfile {
  final String username;
  final String? avatarUrl;
  final int level;
  final int currentXp;
  final int xpToLevelUp;
  final int totalXp;
  final int currentStreak;
  final DateTime? lastTradeDate;
  final int totalTrades;
  final double winRate;
  final List<String> unlockedBadges;
  final List<DripNFT> ownedDrips;

  const UserProfile({
    required this.username,
    this.avatarUrl,
    required this.level,
    required this.currentXp,
    required this.xpToLevelUp,
    required this.totalXp,
    required this.currentStreak,
    this.lastTradeDate,
    required this.totalTrades,
    required this.winRate,
    required this.unlockedBadges,
    required this.ownedDrips,
  });
}

/// Mock data loader for demo and offline mode
class MockDataLoader {
  static final MockDataLoader _instance = MockDataLoader._internal();
  factory MockDataLoader() => _instance;
  MockDataLoader._internal();

  static final math.Random _random = math.Random();
  static DateTime get _now => DateTime.now();
  
  // Demo-safe configuration
  static const int _minXp = 50;
  static const int _maxXp = 25000;
  static const int _minTrades = 10;
  static const int _maxTrades = 500;
  static const double _minWinRate = 0.2;
  static const double _maxWinRate = 0.85;
  
  /// Simulates network delay for realistic loading behavior
  Future<void> _simulateNetworkDelay([int maxMs = 800]) async {
    final delay = _random.nextInt(maxMs) + 200; // 200-800ms
    await Future.delayed(Duration(milliseconds: delay));
  }

  /// Generate mock drip NFTs with varied rarities and timestamps
  Future<List<DripNFT>> getMockDrips({int count = 20}) async {
    await _simulateNetworkDelay();
    
    final drips = <DripNFT>[];
    
    for (int i = 0; i < count; i++) {
      final rarity = _generateWeightedRarity();
      final name = _getDripNameForRarity(rarity);
      
      drips.add(DripNFT(
        id: 'drip_${i + 1}_${_now.millisecondsSinceEpoch}',
        name: name,
        rarity: rarity,
        imageUrl: _getDripImageUrl(rarity, name),
      ));
    }
    
    // Sort by rarity (legendary first) for demo impact
    drips.sort((a, b) => _getRarityWeight(b.rarity).compareTo(_getRarityWeight(a.rarity)));
    
    debugPrint('Generated ${drips.length} mock drips');
    return drips;
  }

  /// Generate mock user profile with realistic progression
  Future<UserProfile> getMockUserProfile({String? username}) async {
    await _simulateNetworkDelay();
    
    final level = _random.nextInt(15) + 3; // Level 3-17
    final baseXp = (level - 1) * 1000;
    final currentXp = _random.nextInt(800) + 100; // 100-900 XP in current level
    final xpToLevelUp = _calculateXpToLevelUp(level);
    final totalXp = baseXp + currentXp;
    
    final totalTrades = _generateRealisticTrades(level);
    final winRate = _generateRealisticWinRate(level);
    final currentStreak = _generateRealisticStreak();
    
    final ownedDrips = await getMockDrips(count: _random.nextInt(8) + 3); // 3-10 drips
    final badges = _generateUnlockedBadges(currentStreak, totalTrades);
    
    final profile = UserProfile(
      username: username ?? _generateRandomUsername(),
      avatarUrl: _getRandomAvatarUrl(),
      level: level,
      currentXp: currentXp,
      xpToLevelUp: xpToLevelUp,
      totalXp: totalXp,
      currentStreak: currentStreak,
      lastTradeDate: _generateRecentTradeDate(currentStreak),
      totalTrades: totalTrades,
      winRate: winRate,
      unlockedBadges: badges,
      ownedDrips: ownedDrips,
    );
    
    debugPrint('Generated mock user profile: ${profile.username} (Level ${profile.level})');
    return profile;
  }

  /// Generate mock leaderboard with competitive but realistic entries
  Future<List<LeaderboardEntry>> getMockLeaderboard({
    int count = 50,
    String? currentUsername,
  }) async {
    await _simulateNetworkDelay();
    
    final entries = <LeaderboardEntry>[];
    
    // Generate top performers with realistic but impressive stats
    for (int rank = 1; rank <= count; rank++) {
      final isTopTier = rank <= 10;
      final isMidTier = rank <= 25;
      
      int xp;
      double winRate;
      int totalTrades;
      
      if (isTopTier) {
        xp = _random.nextInt(15000) + 20000; // 20k-35k XP
        winRate = _random.nextDouble() * 0.25 + 0.65; // 65-90% win rate
        totalTrades = _random.nextInt(300) + 200; // 200-500 trades
      } else if (isMidTier) {
        xp = _random.nextInt(10000) + 10000; // 10k-20k XP
        winRate = _random.nextDouble() * 0.25 + 0.55; // 55-80% win rate
        totalTrades = _random.nextInt(200) + 100; // 100-300 trades
      } else {
        xp = _random.nextInt(8000) + 2000; // 2k-10k XP
        winRate = _random.nextDouble() * 0.35 + 0.35; // 35-70% win rate
        totalTrades = _random.nextInt(150) + 50; // 50-200 trades
      }
      
      entries.add(LeaderboardEntry(
        username: rank == 1 ? 'CryptoKing' : _generateCompetitiveUsername(rank),
        xp: xp,
        rank: rank,
        avatarUrl: _getRandomAvatarUrl(),
        winRate: double.parse(winRate.toStringAsFixed(3)),
        totalTrades: totalTrades,
      ));
    }
    
    // Insert current user if specified
    if (currentUsername != null) {
      final userRank = _random.nextInt(20) + 8; // Rank 8-28
      final userEntry = LeaderboardEntry(
        username: currentUsername,
        xp: _random.nextInt(8000) + 5000, // 5k-13k XP
        rank: userRank,
        winRate: _random.nextDouble() * 0.3 + 0.45, // 45-75% win rate
        totalTrades: _random.nextInt(100) + 50, // 50-150 trades
      );
      
      // Replace entry at user's rank
      if (userRank <= entries.length) {
        entries[userRank - 1] = userEntry;
        
        // Adjust subsequent ranks
        for (int i = userRank; i < entries.length; i++) {
          entries[i] = LeaderboardEntry(
            username: entries[i].username,
            xp: entries[i].xp,
            rank: i + 1,
            avatarUrl: entries[i].avatarUrl,
            winRate: entries[i].winRate,
            totalTrades: entries[i].totalTrades,
          );
        }
      }
    }
    
    debugPrint('Generated ${entries.length} leaderboard entries');
    return entries;
  }

  /// Generate recent trade activity for demo
  Future<List<TradeActivity>> getMockTradeActivity({int count = 10}) async {
    await _simulateNetworkDelay(400);
    
    final activities = <TradeActivity>[];
    
    for (int i = 0; i < count; i++) {
      final hoursAgo = _random.nextInt(72) + 1; // 1-72 hours ago
      final timestamp = _now.subtract(Duration(hours: hoursAgo));
      
      activities.add(TradeActivity(
        timestamp: timestamp,
        direction: _random.nextBool() ? 'long' : 'short',
        leverage: _random.nextInt(10) + 1, // 1-10x
        pnl: (_random.nextDouble() - 0.45) * 20, // -9% to +11% (slight positive bias)
        xpGained: _random.nextInt(50) + 10, // 10-60 XP
        asset: _getRandomAsset(),
      ));
    }
    
    // Sort by timestamp (most recent first)
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return activities;
  }

  /// Generate mock streak reminders and notifications
  Future<List<String>> getMockNotifications() async {
    await _simulateNetworkDelay(300);
    
    final notifications = [
      "🔥 Your 5-day streak is heating up! Don't break it now!",
      "⚡ Lightning Week badge unlocked! 7 days strong!",
      "🎯 You're #12 on the leaderboard. One more win to break top 10!",
      "💎 New Epic drip 'Neon Shades' added to your collection!",
      "🚀 Daily XP bonus: +20 XP for consistent trading!",
    ];
    
    return notifications.take(_random.nextInt(3) + 1).toList();
  }

  // Private helper methods

  String _generateWeightedRarity() {
    final rand = _random.nextDouble();
    if (rand < 0.5) return 'common';
    if (rand < 0.75) return 'rare';
    if (rand < 0.92) return 'epic';
    return 'legendary';
  }

  String _getDripNameForRarity(String rarity) {
    final names = {
      'common': ['Basic Cap', 'Street Tee', 'Plain Kicks', 'Simple Chain', 'Urban Mask'],
      'rare': ['Neon Shades', 'Chrome Watch', 'LED Sneakers', 'Graffiti Hoodie', 'Silver Chain'],
      'epic': ['Holographic Jacket', 'Diamond Earrings', 'Cyber Gloves', 'Plasma Visor', 'Lightning Boots'],
      'legendary': ['Golden Crown', 'Mythic Wings', 'Infinity Gauntlet', 'Dragon Aura', 'Cosmic Drip'],
    };
    
    final options = names[rarity] ?? names['common']!;
    return options[_random.nextInt(options.length)];
  }

  String _getDripImageUrl(String rarity, String name) {
    // In a real app, these would be actual image URLs
    final cleanName = name.toLowerCase().replaceAll(' ', '_');
    return 'https://streetcred.assets/drips/${rarity}/${cleanName}.png';
  }

  int _getRarityWeight(String rarity) {
    switch (rarity) {
      case 'legendary': return 4;
      case 'epic': return 3;
      case 'rare': return 2;
      case 'common': return 1;
      default: return 0;
    }
  }

  int _calculateXpToLevelUp(int level) {
    return (100 * math.pow(1.5, level - 1)).round();
  }

  int _generateRealisticTrades(int level) {
    final baseMinTrades = level * 8;
    final baseMaxTrades = level * 25;
    return _random.nextInt(baseMaxTrades - baseMinTrades) + baseMinTrades;
  }

  double _generateRealisticWinRate(int level) {
    final baseWinRate = 0.45 + (level * 0.02); // Higher level = slightly better win rate
    final variance = _random.nextDouble() * 0.2 - 0.1; // ±10% variance
    return (baseWinRate + variance).clamp(_minWinRate, _maxWinRate);
  }

  int _generateRealisticStreak() {
    final weights = [40, 25, 15, 10, 5, 3, 2]; // % chance for each streak length
    final rand = _random.nextInt(100);
    
    int cumulative = 0;
    for (int i = 0; i < weights.length; i++) {
      cumulative += weights[i];
      if (rand < cumulative) {
        return i; // 0-6 day streak
      }
    }
    return _random.nextInt(30) + 7; // 7-36 day streak (rare)
  }

  DateTime? _generateRecentTradeDate(int streak) {
    if (streak == 0) {
      // Last trade was 2-7 days ago
      return _now.subtract(Duration(days: _random.nextInt(5) + 2));
    } else {
      // Last trade was within streak window
      return _now.subtract(Duration(hours: _random.nextInt(20) + 1));
    }
  }

  List<String> _generateUnlockedBadges(int streak, int totalTrades) {
    final badges = <String>[];
    
    if (streak >= 3) badges.add('🔥 Fire Starter');
    if (streak >= 7) badges.add('⚡ Lightning Week');
    if (streak >= 14) badges.add('💎 Diamond Hands');
    if (streak >= 30) badges.add('👑 Streak Master');
    
    if (totalTrades >= 50) badges.add('📈 Trader');
    if (totalTrades >= 100) badges.add('💪 Veteran');
    if (totalTrades >= 250) badges.add('🚀 Master');
    
    return badges;
  }

  String _generateRandomUsername() {
    final prefixes = ['Crypto', 'Bull', 'Bear', 'Moon', 'Diamond', 'Pump', 'HODL', 'Alpha', 'Degen', 'Leverage'];
    final suffixes = ['King', 'Master', 'Hunter', 'Trader', 'Lord', 'Ninja', 'Bot', 'Shark', 'Wolf', 'Legend'];
    
    final prefix = prefixes[_random.nextInt(prefixes.length)];
    final suffix = suffixes[_random.nextInt(suffixes.length)];
    final number = _random.nextInt(999) + 1;
    
    return '$prefix$suffix$number';
  }

  String _generateCompetitiveUsername(int rank) {
    if (rank <= 3) {
      final names = ['DiamondHands', 'BullMaster', 'CryptoLord'];
      return names[rank - 1];
    }
    
    final eliteNames = [
      'MoonShot', 'PumpKing', 'LeverageGod', 'AlphaSeeker', 'BearSlayer',
      'TradingBot', 'CryptoNinja', 'BullRun', 'HODLMaster', 'DeFiLord'
    ];
    
    return eliteNames[_random.nextInt(eliteNames.length)];
  }

  String? _getRandomAvatarUrl() {
    if (_random.nextDouble() < 0.3) return null; // 30% no avatar
    
    final avatarId = _random.nextInt(100) + 1;
    return 'https://api.dicebear.com/7.x/adventurer/png?seed=$avatarId';
  }

  String _getRandomAsset() {
    final assets = ['BTC', 'ETH', 'SOL', 'STRK', 'DOGE', 'MATIC', 'AVAX', 'LINK'];
    return assets[_random.nextInt(assets.length)];
  }
}

/// Trade activity data structure
class TradeActivity {
  final DateTime timestamp;
  final String direction;
  final int leverage;
  final double pnl;
  final int xpGained;
  final String asset;

  const TradeActivity({
    required this.timestamp,
    required this.direction,
    required this.leverage,
    required this.pnl,
    required this.xpGained,
    required this.asset,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}

/// Demo data presets for specific scenarios
class DemoPresets {
  /// High-performing user with impressive stats
  static Future<UserProfile> getSuccessfulTrader() async {
    final loader = MockDataLoader();
    final drips = await loader.getMockDrips(count: 15);
    
    return UserProfile(
      username: 'DemoKing',
      level: 12,
      currentXp: 650,
      xpToLevelUp: 1500,
      totalXp: 18650,
      currentStreak: 14,
      lastTradeDate: DateTime.now().subtract(const Duration(hours: 3)),
      totalTrades: 247,
      winRate: 0.73,
      unlockedBadges: ['🔥 Fire Starter', '⚡ Lightning Week', '💎 Diamond Hands', '📈 Trader', '💪 Veteran'],
      ownedDrips: drips,
    );
  }

  /// New user just starting out
  static Future<UserProfile> getNewTrader() async {
    final loader = MockDataLoader();
    final drips = await loader.getMockDrips(count: 2);
    
    return UserProfile(
      username: 'Rookie',
      level: 2,
      currentXp: 45,
      xpToLevelUp: 150,
      totalXp: 145,
      currentStreak: 1,
      lastTradeDate: DateTime.now().subtract(const Duration(hours: 1)),
      totalTrades: 8,
      winRate: 0.50,
      unlockedBadges: [],
      ownedDrips: drips,
    );
  }

  /// Competitive leaderboard for demo
  static Future<List<LeaderboardEntry>> getCompetitiveLeaderboard() async {
    final loader = MockDataLoader();
    return loader.getMockLeaderboard(count: 25, currentUsername: 'DemoKing');
  }
}

/// Utility for testing and demo scenarios
class MockDataTester {
  static Future<void> printSampleData() async {
    final loader = MockDataLoader();
    
    debugPrint('\n=== SAMPLE MOCK DATA ===');
    
    // User Profile
    final profile = await loader.getMockUserProfile(username: 'TestUser');
    debugPrint('Profile: ${profile.username} - Level ${profile.level}, ${profile.totalTrades} trades');
    
    // Drips
    final drips = await loader.getMockDrips(count: 5);
    debugPrint('Sample Drips: ${drips.map((d) => '${d.name} (${d.rarity})').join(', ')}');
    
    // Leaderboard
    final leaderboard = await loader.getMockLeaderboard(count: 5);
    debugPrint('Top 5 Leaderboard:');
    for (final entry in leaderboard) {
      debugPrint('  #${entry.rank}: ${entry.username} - ${entry.xp} XP');
    }
    
    debugPrint('=== END SAMPLE DATA ===\n');
  }
}