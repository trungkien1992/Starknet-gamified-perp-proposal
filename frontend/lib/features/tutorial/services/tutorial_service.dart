import 'package:flutter/material.dart';
import '../models/tutorial_models.dart';
import '../../social/models/meme_models.dart';

class TutorialService {
  static const String _storageKey = 'tutorial_progress';

  // Mock market data for tutorial
  static const Map<String, double> _mockPrices = {
    'BTC-USDT': 65432.10,
    'HSI-HKD': 18456.78,
    'TCEHY-HKD': 312.45,
  };

  // Tutorial-specific achievements
  static const Map<TutorialStep, String> _stepAchievements = {
    TutorialStep.firstSwipe: 'First swipe mastered! 🎯',
    TutorialStep.mockTrade: 'Trade executed perfectly! 💪',
    TutorialStep.territorySelect: 'Territory claimed! 🗺️',
    TutorialStep.shareFirst: 'Meme master unlocked! 🎨',
    TutorialStep.collectReward: 'Rewards collected! 🎁',
  };

  Future<bool> shouldShowTutorial() async {
    // Check if user has completed tutorial
    // For demo purposes, return true for new users
    return true;
  }

  Future<TutorialProgress> loadProgress() async {
    // In production, load from secure storage
    // For demo, start fresh
    return TutorialProgress.initial();
  }

  Future<void> saveProgress(TutorialProgress progress) async {
    // In production, save to secure storage
    // For demo, just log
    debugPrint('Tutorial progress saved: ${progress.currentStep}');
  }

  TutorialStepConfig getStepConfig(TutorialStep step) {
    return TutorialStepConfig.forStep(step);
  }

  TutorialStep getNextStep(TutorialStep currentStep) {
    final steps = TutorialStep.values;
    final currentIndex = steps.indexOf(currentStep);
    
    if (currentIndex < steps.length - 1) {
      return steps[currentIndex + 1];
    }
    
    return TutorialStep.graduated;
  }

  bool canAdvanceStep(TutorialStep step, {Map<String, dynamic>? context}) {
    switch (step) {
      case TutorialStep.welcome:
        return true; // Always can advance from welcome

      case TutorialStep.walletConnect:
        return context?['isWalletConnected'] == true;

      case TutorialStep.firstSwipe:
        return context?['hasPerformedSwipe'] == true;

      case TutorialStep.leverageControl:
        return context?['hasAdjustedLeverage'] == true;

      case TutorialStep.territorySelect:
        return context?['hasSelectedTerritory'] == true;

      case TutorialStep.mockTrade:
        return context?['hasExecutedMockTrade'] == true;

      case TutorialStep.weatherSystem:
        return context?['hasInteractedWithWeather'] == true;

      case TutorialStep.shareFirst:
        return context?['hasSharedMeme'] == true;

      case TutorialStep.collectReward:
        return context?['hasCollectedReward'] == true;

      case TutorialStep.graduated:
        return true;
    }
  }

  MockTrade executeMockTrade({
    required String asset,
    required String direction,
    required double leverage,
  }) {
    return MockTrade.generateDemo(asset, direction, leverage);
  }

  double getMockPrice(String asset) {
    return _mockPrices[asset] ?? 50000.0;
  }

  List<String> getEncouragingMessages(TutorialStep step) {
    switch (step) {
      case TutorialStep.welcome:
        return [
          'Welcome to the streets of Hong Kong! 🏙️',
          'Ready to become a trading legend?',
          'Your street art journey begins now!',
        ];

      case TutorialStep.walletConnect:
        return [
          'Connect safely with Web3Auth 🔐',
          'Your wallet is your identity',
          'Secure connection established!',
        ];

      case TutorialStep.firstSwipe:
        return [
          'Feel the spray can in your hands 🎨',
          'Up for LONG, down for SHORT',
          'Perfect! You\'re a natural!',
        ];

      case TutorialStep.leverageControl:
        return [
          'More leverage = bigger impact 💥',
          'But also more risk...',
          'Find your sweet spot!',
        ];

      case TutorialStep.territorySelect:
        return [
          'Choose your battleground 🗺️',
          'Each district has its own vibe',
          'Central, Tsim Sha Tsui, Wan Chai...',
        ];

      case TutorialStep.mockTrade:
        return [
          'This is it! Your first tag! 🎯',
          'Practice makes perfect',
          'No real money at risk here',
        ];

      case TutorialStep.weatherSystem:
        return [
          'Rain boosts your trading power! 🌧️',
          'Weather affects the streets',
          'Check the forecast!',
        ];

      case TutorialStep.shareFirst:
        return [
          'Share your art with the world! 📱',
          'Every trade tells a story',
          'Make it viral!',
        ];

      case TutorialStep.collectReward:
        return [
          'Time to claim your rewards! 🎁',
          'You\'ve earned these NFTs',
          'Rare starter collection awaits!',
        ];

      case TutorialStep.graduated:
        return [
          'Welcome to the StreetCred community! 🎉',
          'You\'re ready for real trading',
          'The streets await your art!',
        ];
    }
  }

  String getAchievementMessage(TutorialStep step) {
    return _stepAchievements[step] ?? 'Step completed! 🎯';
  }

  TradeOutcome convertMockTradeToOutcome(MockTrade mockTrade) {
    return TradeOutcome(
      direction: mockTrade.direction,
      leverage: mockTrade.leverage,
      pnl: mockTrade.pnl,
      asset: mockTrade.asset,
      timestamp: mockTrade.timestamp,
      territoryName: null, // Tutorial trades don't count for territory
      isWin: mockTrade.isWin,
      streakDays: null,
      consecutiveWins: null,
    );
  }

  List<String> getTips(TutorialStep step) {
    switch (step) {
      case TutorialStep.welcome:
        return [
          'This tutorial is completely safe',
          'No real money will be used',
          'Take your time to learn',
        ];

      case TutorialStep.walletConnect:
        return [
          'We use Web3Auth for security',
          'Your wallet stays in your control',
          'Social login is supported',
        ];

      case TutorialStep.firstSwipe:
        return [
          'Swipe speed affects spray intensity',
          'LONG = betting price goes up',
          'SHORT = betting price goes down',
        ];

      case TutorialStep.leverageControl:
        return [
          'Higher leverage = higher risk/reward',
          'Start with low leverage (2x-5x)',
          'You can adjust anytime',
        ];

      case TutorialStep.territorySelect:
        return [
          'Territories unlock progressively',
          'Complete art by trading',
          'Earn prestige points',
        ];

      case TutorialStep.mockTrade:
        return [
          'This is a simulated trade',
          'Prices are realistic but fake',
          'Perfect practice environment',
        ];

      case TutorialStep.weatherSystem:
        return [
          'Rain = 25% ink efficiency bonus',
          'Storm = 50% volatility multiplier',
          'Clear = normal conditions',
        ];

      case TutorialStep.shareFirst:
        return [
          'Memes auto-generate from trades',
          'Share to any social platform',
          'Build your street reputation',
        ];

      case TutorialStep.collectReward:
        return [
          'NFTs are randomly generated',
          '5% chance for legendary rewards',
          'These are real collectibles',
        ];

      case TutorialStep.graduated:
        return [
          'You can now trade with real funds',
          'Join the community Discord',
          'Follow us for updates',
        ];
    }
  }

  Duration getEstimatedStepTime(TutorialStep step) {
    switch (step) {
      case TutorialStep.welcome:
        return const Duration(seconds: 15);
      case TutorialStep.walletConnect:
        return const Duration(seconds: 30);
      case TutorialStep.firstSwipe:
        return const Duration(seconds: 20);
      case TutorialStep.leverageControl:
        return const Duration(seconds: 15);
      case TutorialStep.territorySelect:
        return const Duration(seconds: 25);
      case TutorialStep.mockTrade:
        return const Duration(seconds: 30);
      case TutorialStep.weatherSystem:
        return const Duration(seconds: 20);
      case TutorialStep.shareFirst:
        return const Duration(seconds: 25);
      case TutorialStep.collectReward:
        return const Duration(seconds: 20);
      case TutorialStep.graduated:
        return const Duration(seconds: 10);
    }
  }

  Duration getTotalEstimatedTime() {
    return TutorialStep.values
        .map((step) => getEstimatedStepTime(step))
        .reduce((a, b) => a + b);
  }

  bool isOptionalStep(TutorialStep step) {
    // Some steps can be skipped
    switch (step) {
      case TutorialStep.shareFirst:
      case TutorialStep.weatherSystem:
        return true;
      default:
        return false;
    }
  }

  Map<String, dynamic> getStepAnalytics(TutorialStep step, Duration timeSpent) {
    return {
      'step': step.toString(),
      'timeSpent': timeSpent.inSeconds,
      'timestamp': DateTime.now().toIso8601String(),
      'completed': true,
    };
  }
}