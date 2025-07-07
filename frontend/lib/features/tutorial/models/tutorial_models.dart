import 'package:flutter/material.dart';

enum TutorialStep {
  welcome,
  walletConnect,
  firstSwipe,
  leverageControl,
  territorySelect,
  mockTrade,
  weatherSystem,
  shareFirst,
  collectReward,
  graduated,
}

enum TutorialRewardType {
  ink,
  xp,
  nft,
  territory,
  badge,
}

enum StarterNFTRarity {
  common,
  rare,
  epic,
  legendary,
}

class TutorialReward {
  final TutorialRewardType type;
  final String id;
  final String name;
  final String description;
  final int amount;
  final Color color;
  final String emoji;
  final StarterNFTRarity? rarity;

  TutorialReward({
    required this.type,
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.color,
    required this.emoji,
    this.rarity,
  });

  static List<TutorialReward> get starterRewards => [
    TutorialReward(
      type: TutorialRewardType.ink,
      id: 'starter_ink',
      name: 'Starter Ink',
      description: 'Enough ink for your first street art',
      amount: 100,
      color: const Color(0xFFFFD700),
      emoji: '🎨',
    ),
    TutorialReward(
      type: TutorialRewardType.nft,
      id: 'spray_can_common',
      name: 'Rookie Spray Can',
      description: 'Your first tool of the trade',
      amount: 1,
      color: const Color(0xFF888888),
      emoji: '🎪',
      rarity: StarterNFTRarity.common,
    ),
    TutorialReward(
      type: TutorialRewardType.nft,
      id: 'hk_skyline_rare',
      name: 'HK Skyline Badge',
      description: 'Rare Hong Kong skyline commemorative',
      amount: 1,
      color: const Color(0xFF00FFFF),
      emoji: '🏙️',
      rarity: StarterNFTRarity.rare,
    ),
    TutorialReward(
      type: TutorialRewardType.badge,
      id: 'street_rookie',
      name: 'Street Rookie',
      description: 'Completed the street initiation',
      amount: 1,
      color: const Color(0xFF00FF41),
      emoji: '🎯',
    ),
  ];

  static TutorialReward getRandomStarterNFT() {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    
    if (random < 5) {
      // 5% legendary
      return TutorialReward(
        type: TutorialRewardType.nft,
        id: 'golden_dragon_legendary',
        name: 'Golden Dragon',
        description: 'Legendary Hong Kong spirit guardian',
        amount: 1,
        color: const Color(0xFFFFD700),
        emoji: '🐉',
        rarity: StarterNFTRarity.legendary,
      );
    } else if (random < 20) {
      // 15% epic
      return TutorialReward(
        type: TutorialRewardType.nft,
        id: 'neon_temple_epic',
        name: 'Neon Temple',
        description: 'Epic cyberpunk temple artwork',
        amount: 1,
        color: const Color(0xFF8A2BE2),
        emoji: '🏯',
        rarity: StarterNFTRarity.epic,
      );
    } else if (random < 50) {
      // 30% rare
      return starterRewards[2]; // HK Skyline
    } else {
      // 50% common
      return starterRewards[1]; // Spray Can
    }
  }
}

class TutorialStepConfig {
  final TutorialStep step;
  final String title;
  final String description;
  final String instruction;
  final IconData icon;
  final Color themeColor;
  final List<TutorialReward> rewards;
  final bool requiresInteraction;
  final String? mockTradeAsset;
  final bool isCompleted;

  TutorialStepConfig({
    required this.step,
    required this.title,
    required this.description,
    required this.instruction,
    required this.icon,
    required this.themeColor,
    required this.rewards,
    required this.requiresInteraction,
    this.mockTradeAsset,
    this.isCompleted = false,
  });

  TutorialStepConfig copyWith({bool? isCompleted}) {
    return TutorialStepConfig(
      step: step,
      title: title,
      description: description,
      instruction: instruction,
      icon: icon,
      themeColor: themeColor,
      rewards: rewards,
      requiresInteraction: requiresInteraction,
      mockTradeAsset: mockTradeAsset,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  static TutorialStepConfig forStep(TutorialStep step) {
    switch (step) {
      case TutorialStep.welcome:
        return TutorialStepConfig(
          step: step,
          title: 'WELCOME TO THE STREETS',
          description: 'Ready to tag your first trade and earn street cred?',
          instruction: 'Tap continue to start your journey',
          icon: Icons.waving_hand,
          themeColor: const Color(0xFF00FFFF),
          rewards: [],
          requiresInteraction: false,
        );

      case TutorialStep.walletConnect:
        return TutorialStepConfig(
          step: step,
          title: 'CONNECT YOUR WALLET',
          description: 'Link your digital wallet to start trading',
          instruction: 'Tap the wallet button to connect',
          icon: Icons.account_balance_wallet,
          themeColor: const Color(0xFF00FF41),
          rewards: [TutorialReward.starterRewards[0]], // Starter ink
          requiresInteraction: true,
        );

      case TutorialStep.firstSwipe:
        return TutorialStepConfig(
          step: step,
          title: 'LEARN THE SWIPE',
          description: 'Swipe to spray your first trade',
          instruction: 'Swipe up for LONG, down for SHORT',
          icon: Icons.swipe,
          themeColor: const Color(0xFFFF0080),
          rewards: [],
          requiresInteraction: true,
        );

      case TutorialStep.leverageControl:
        return TutorialStepConfig(
          step: step,
          title: 'CONTROL YOUR POWER',
          description: 'Adjust leverage to control trade intensity',
          instruction: 'Drag the leverage slider',
          icon: Icons.tune,
          themeColor: const Color(0xFFFFD700),
          rewards: [],
          requiresInteraction: true,
        );

      case TutorialStep.territorySelect:
        return TutorialStepConfig(
          step: step,
          title: 'CLAIM YOUR TERRITORY',
          description: 'Choose a Hong Kong district to conquer',
          instruction: 'Tap the territory button and select a district',
          icon: Icons.location_on,
          themeColor: const Color(0xFF8A2BE2),
          rewards: [],
          requiresInteraction: true,
        );

      case TutorialStep.mockTrade:
        return TutorialStepConfig(
          step: step,
          title: 'EXECUTE YOUR TRADE',
          description: 'Make your first practice trade',
          instruction: 'Swipe to execute a safe practice trade',
          icon: Icons.trending_up,
          themeColor: const Color(0xFF00FF41),
          rewards: [TutorialReward.starterRewards[1]], // Spray can NFT
          requiresInteraction: true,
          mockTradeAsset: 'BTC-USDT',
        );

      case TutorialStep.weatherSystem:
        return TutorialStepConfig(
          step: step,
          title: 'FEEL THE WEATHER',
          description: 'Weather affects your trading power',
          instruction: 'Tap the weather indicator to see effects',
          icon: Icons.wb_cloudy,
          themeColor: const Color(0xFF00FFFF),
          rewards: [],
          requiresInteraction: true,
        );

      case TutorialStep.shareFirst:
        return TutorialStepConfig(
          step: step,
          title: 'SHARE YOUR ART',
          description: 'Create and share your first meme',
          instruction: 'Use the share button to create a meme',
          icon: Icons.share,
          themeColor: const Color(0xFFFF4500),
          rewards: [],
          requiresInteraction: true,
        );

      case TutorialStep.collectReward:
        return TutorialStepConfig(
          step: step,
          title: 'COLLECT YOUR REWARD',
          description: 'Claim your graduation rewards',
          instruction: 'Tap to collect your starter NFT',
          icon: Icons.card_giftcard,
          themeColor: const Color(0xFFFFD700),
          rewards: [
            TutorialReward.getRandomStarterNFT(),
            TutorialReward.starterRewards[3], // Badge
          ],
          requiresInteraction: true,
        );

      case TutorialStep.graduated:
        return TutorialStepConfig(
          step: step,
          title: 'STREET CERTIFIED',
          description: 'You\'re now ready for real trading',
          instruction: 'Welcome to the StreetCred community',
          icon: Icons.emoji_events,
          themeColor: const Color(0xFFFFD700),
          rewards: [],
          requiresInteraction: false,
        );
    }
  }
}

class MockTrade {
  final String asset;
  final String direction;
  final double leverage;
  final double entryPrice;
  final double exitPrice;
  final double pnl;
  final DateTime timestamp;
  final bool isDemo;

  MockTrade({
    required this.asset,
    required this.direction,
    required this.leverage,
    required this.entryPrice,
    required this.exitPrice,
    required this.pnl,
    required this.timestamp,
    this.isDemo = true,
  });

  bool get isWin => pnl > 0;
  double get pnlPercentage => ((exitPrice - entryPrice) / entryPrice) * 100 * leverage;

  static MockTrade generateDemo(String asset, String direction, double leverage) {
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    final entryPrice = 50000.0 + (random * 10); // Mock BTC price
    
    // Generate a positive outcome for tutorial (75% win rate)
    final isWin = (random % 100) < 75;
    final priceMove = isWin ? (random % 200 + 50) : -(random % 100 + 20);
    
    final exitPrice = entryPrice + priceMove;
    final pnl = ((exitPrice - entryPrice) / entryPrice) * 100 * leverage;

    return MockTrade(
      asset: asset,
      direction: direction,
      leverage: leverage,
      entryPrice: entryPrice,
      exitPrice: exitPrice,
      pnl: pnl,
      timestamp: DateTime.now(),
    );
  }
}

class TutorialProgress {
  final TutorialStep currentStep;
  final List<TutorialStep> completedSteps;
  final List<TutorialReward> earnedRewards;
  final List<MockTrade> mockTrades;
  final DateTime startTime;
  final DateTime? completionTime;

  TutorialProgress({
    required this.currentStep,
    required this.completedSteps,
    required this.earnedRewards,
    required this.mockTrades,
    required this.startTime,
    this.completionTime,
  });

  bool get isCompleted => currentStep == TutorialStep.graduated;
  double get progressPercentage => completedSteps.length / TutorialStep.values.length;
  
  int get totalMockTrades => mockTrades.length;
  int get winningTrades => mockTrades.where((trade) => trade.isWin).length;
  double get winRate => totalMockTrades > 0 ? winningTrades / totalMockTrades : 0.0;

  TutorialProgress copyWith({
    TutorialStep? currentStep,
    List<TutorialStep>? completedSteps,
    List<TutorialReward>? earnedRewards,
    List<MockTrade>? mockTrades,
    DateTime? completionTime,
  }) {
    return TutorialProgress(
      currentStep: currentStep ?? this.currentStep,
      completedSteps: completedSteps ?? this.completedSteps,
      earnedRewards: earnedRewards ?? this.earnedRewards,
      mockTrades: mockTrades ?? this.mockTrades,
      startTime: startTime,
      completionTime: completionTime ?? this.completionTime,
    );
  }

  static TutorialProgress initial() {
    return TutorialProgress(
      currentStep: TutorialStep.welcome,
      completedSteps: [],
      earnedRewards: [],
      mockTrades: [],
      startTime: DateTime.now(),
    );
  }
}