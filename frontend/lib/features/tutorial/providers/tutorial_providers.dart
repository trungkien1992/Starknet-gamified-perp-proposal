import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tutorial_models.dart';
import '../services/tutorial_service.dart';

// Service provider
final tutorialServiceProvider = Provider<TutorialService>((ref) {
  return TutorialService();
});

// Tutorial progress state
class TutorialProgressNotifier extends StateNotifier<TutorialProgress> {
  final TutorialService _service;

  TutorialProgressNotifier(this._service) : super(TutorialProgress.initial());

  Future<void> loadProgress() async {
    final progress = await _service.loadProgress();
    state = progress;
  }

  Future<void> completeStep(TutorialStep step, {Map<String, dynamic>? context}) async {
    if (!_service.canAdvanceStep(step, context: context)) {
      return;
    }

    final currentStepConfig = _service.getStepConfig(step);
    final updatedCompletedSteps = [...state.completedSteps, step];
    final updatedRewards = [...state.earnedRewards, ...currentStepConfig.rewards];
    final nextStep = _service.getNextStep(step);

    state = state.copyWith(
      currentStep: nextStep,
      completedSteps: updatedCompletedSteps,
      earnedRewards: updatedRewards,
      completionTime: nextStep == TutorialStep.graduated ? DateTime.now() : null,
    );

    await _service.saveProgress(state);
  }

  Future<void> addMockTrade(MockTrade trade) async {
    final updatedMockTrades = [...state.mockTrades, trade];
    state = state.copyWith(mockTrades: updatedMockTrades);
    await _service.saveProgress(state);
  }

  void skipStep(TutorialStep step) {
    if (_service.isOptionalStep(step)) {
      final nextStep = _service.getNextStep(step);
      final updatedCompletedSteps = [...state.completedSteps, step];
      
      state = state.copyWith(
        currentStep: nextStep,
        completedSteps: updatedCompletedSteps,
      );
    }
  }

  void resetTutorial() {
    state = TutorialProgress.initial();
  }
}

final tutorialProgressProvider = StateNotifierProvider<TutorialProgressNotifier, TutorialProgress>((ref) {
  final service = ref.read(tutorialServiceProvider);
  return TutorialProgressNotifier(service);
});

// Current step configuration
final currentStepConfigProvider = Provider<TutorialStepConfig>((ref) {
  final progress = ref.watch(tutorialProgressProvider);
  final service = ref.read(tutorialServiceProvider);
  return service.getStepConfig(progress.currentStep);
});

// Should show tutorial check
final shouldShowTutorialProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(tutorialServiceProvider);
  return await service.shouldShowTutorial();
});

// Mock trading state
final isMockTradingModeProvider = StateProvider<bool>((ref) {
  final progress = ref.watch(tutorialProgressProvider);
  return !progress.isCompleted;
});

// Mock prices
final mockPriceProvider = Provider.family<double, String>((ref, asset) {
  final service = ref.read(tutorialServiceProvider);
  return service.getMockPrice(asset);
});

// Step completion validation
final canAdvanceStepProvider = Provider.family<bool, Map<String, dynamic>>((ref, context) {
  final progress = ref.watch(tutorialProgressProvider);
  final service = ref.read(tutorialServiceProvider);
  return service.canAdvanceStep(progress.currentStep, context: context);
});

// Tutorial analytics
class TutorialAnalytics {
  final Duration totalTime;
  final Map<TutorialStep, Duration> stepTimes;
  final int mockTradesExecuted;
  final double mockWinRate;
  final List<TutorialReward> rewardsEarned;

  TutorialAnalytics({
    required this.totalTime,
    required this.stepTimes,
    required this.mockTradesExecuted,
    required this.mockWinRate,
    required this.rewardsEarned,
  });
}

final tutorialAnalyticsProvider = Provider<TutorialAnalytics>((ref) {
  final progress = ref.watch(tutorialProgressProvider);
  final service = ref.read(tutorialServiceProvider);
  
  final totalTime = progress.completionTime?.difference(progress.startTime) ?? 
                   DateTime.now().difference(progress.startTime);
  
  // Mock step times for demo
  final stepTimes = <TutorialStep, Duration>{};
  for (final step in progress.completedSteps) {
    stepTimes[step] = service.getEstimatedStepTime(step);
  }

  return TutorialAnalytics(
    totalTime: totalTime,
    stepTimes: stepTimes,
    mockTradesExecuted: progress.totalMockTrades,
    mockWinRate: progress.winRate,
    rewardsEarned: progress.earnedRewards,
  );
});

// Reward showcase
final latestRewardProvider = StateProvider<TutorialReward?>((ref) => null);

// Tutorial step messages
final stepMessagesProvider = Provider.family<List<String>, TutorialStep>((ref, step) {
  final service = ref.read(tutorialServiceProvider);
  return service.getEncouragingMessages(step);
});

final stepTipsProvider = Provider.family<List<String>, TutorialStep>((ref, step) {
  final service = ref.read(tutorialServiceProvider);
  return service.getTips(step);
});

// Achievement display
final achievementProvider = StateProvider<String?>((ref) => null);

// Tutorial interaction tracking
class TutorialInteractionNotifier extends StateNotifier<Map<String, bool>> {
  TutorialInteractionNotifier() : super({});

  void markInteraction(String interaction) {
    state = {...state, interaction: true};
  }

  void resetInteractions() {
    state = {};
  }

  bool hasInteraction(String interaction) {
    return state[interaction] ?? false;
  }
}

final tutorialInteractionProvider = StateNotifierProvider<TutorialInteractionNotifier, Map<String, bool>>((ref) {
  return TutorialInteractionNotifier();
});

// Context helpers for step validation
final tutorialContextProvider = Provider<Map<String, dynamic>>((ref) {
  final interactions = ref.watch(tutorialInteractionProvider);
  
  return {
    'isWalletConnected': interactions['wallet_connected'] ?? false,
    'hasPerformedSwipe': interactions['performed_swipe'] ?? false,
    'hasAdjustedLeverage': interactions['adjusted_leverage'] ?? false,
    'hasSelectedTerritory': interactions['selected_territory'] ?? false,
    'hasExecutedMockTrade': interactions['executed_mock_trade'] ?? false,
    'hasInteractedWithWeather': interactions['interacted_weather'] ?? false,
    'hasSharedMeme': interactions['shared_meme'] ?? false,
    'hasCollectedReward': interactions['collected_reward'] ?? false,
  };
});

// Tutorial completion stats
final tutorialStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final progress = ref.watch(tutorialProgressProvider);
  final analytics = ref.watch(tutorialAnalyticsProvider);
  
  return {
    'progress_percentage': progress.progressPercentage,
    'steps_completed': progress.completedSteps.length,
    'total_steps': TutorialStep.values.length,
    'mock_trades': progress.totalMockTrades,
    'win_rate': progress.winRate,
    'rewards_earned': progress.earnedRewards.length,
    'time_spent': analytics.totalTime.inMinutes,
    'is_completed': progress.isCompleted,
  };
});

// NFT rarity distribution for tutorial rewards
final nftRarityDistributionProvider = Provider<Map<StarterNFTRarity, int>>((ref) {
  final progress = ref.watch(tutorialProgressProvider);
  final nftRewards = progress.earnedRewards.where((r) => r.type == TutorialRewardType.nft);
  
  final distribution = <StarterNFTRarity, int>{};
  for (final reward in nftRewards) {
    if (reward.rarity != null) {
      distribution[reward.rarity!] = (distribution[reward.rarity!] ?? 0) + 1;
    }
  }
  
  return distribution;
});

// Tutorial guidance system
final shouldShowHintProvider = Provider.family<bool, TutorialStep>((ref, step) {
  final progress = ref.watch(tutorialProgressProvider);
  final interactions = ref.watch(tutorialInteractionProvider);
  
  // Show hints if user is stuck on a step for too long
  // This is a simplified version - in production you'd track actual time
  switch (step) {
    case TutorialStep.firstSwipe:
      return !(interactions['performed_swipe'] ?? false);
    case TutorialStep.leverageControl:
      return !(interactions['adjusted_leverage'] ?? false);
    case TutorialStep.territorySelect:
      return !(interactions['selected_territory'] ?? false);
    default:
      return false;
  }
});

// Mock market data for tutorial
final mockMarketDataProvider = Provider.family<Map<String, dynamic>, String>((ref, asset) {
  final service = ref.read(tutorialServiceProvider);
  final basePrice = service.getMockPrice(asset);
  
  // Generate realistic but fake market data for tutorial
  final random = DateTime.now().millisecondsSinceEpoch % 1000;
  final change = (random % 200 - 100) / 100; // -1% to +1%
  
  return {
    'price': basePrice.toStringAsFixed(2),
    'change': change.toStringAsFixed(2),
    'isPositive': change >= 0,
    'volume': '${(random % 1000 + 500)}M',
    'high24h': (basePrice * 1.03).toStringAsFixed(2),
    'low24h': (basePrice * 0.97).toStringAsFixed(2),
  };
});