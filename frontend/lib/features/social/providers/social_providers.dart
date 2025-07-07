import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meme_models.dart';
import '../services/meme_generator_service.dart';
import '../services/social_share_service.dart';

// Service providers
final memeGeneratorServiceProvider = Provider<MemeGeneratorService>((ref) {
  return MemeGeneratorService();
});

final socialShareServiceProvider = Provider<SocialShareService>((ref) {
  return SocialShareService();
});

// State providers
final currentMemeTemplateProvider = StateProvider<MemeTemplate?>((ref) => null);

final recentTradeOutcomesProvider = StateProvider<List<TradeOutcome>>((ref) => []);

// Add a new trade outcome to recent outcomes
final addTradeOutcomeProvider = Provider.family<void, TradeOutcome>((ref, outcome) {
  final current = ref.read(recentTradeOutcomesProvider);
  final updated = [outcome, ...current].take(10).toList(); // Keep last 10
  ref.read(recentTradeOutcomesProvider.notifier).state = updated;
});

// Generate shareable content for a trade outcome
final generateShareableContentProvider = FutureProvider.family<ShareableContent, Map<String, dynamic>>((ref, params) async {
  final memeGenerator = ref.read(memeGeneratorServiceProvider);
  final outcome = params['outcome'] as TradeOutcome;
  final template = params['template'] as MemeTemplate?;
  
  return await memeGenerator.createShareableContent(outcome, template: template);
});

// Social sharing stats
class SocialStats {
  final int totalShares;
  final int weeklyShares;
  final Map<SharePlatform, int> platformShares;
  final List<String> topMemes;

  SocialStats({
    required this.totalShares,
    required this.weeklyShares,
    required this.platformShares,
    required this.topMemes,
  });

  SocialStats copyWith({
    int? totalShares,
    int? weeklyShares,
    Map<SharePlatform, int>? platformShares,
    List<String>? topMemes,
  }) {
    return SocialStats(
      totalShares: totalShares ?? this.totalShares,
      weeklyShares: weeklyShares ?? this.weeklyShares,
      platformShares: platformShares ?? this.platformShares,
      topMemes: topMemes ?? this.topMemes,
    );
  }
}

class SocialStatsNotifier extends StateNotifier<SocialStats> {
  SocialStatsNotifier() : super(SocialStats(
    totalShares: 0,
    weeklyShares: 0,
    platformShares: {},
    topMemes: [],
  ));

  void incrementShare(SharePlatform platform) {
    final updatedPlatformShares = Map<SharePlatform, int>.from(state.platformShares);
    updatedPlatformShares[platform] = (updatedPlatformShares[platform] ?? 0) + 1;

    state = state.copyWith(
      totalShares: state.totalShares + 1,
      weeklyShares: state.weeklyShares + 1,
      platformShares: updatedPlatformShares,
    );
  }

  void addTopMeme(String memeId) {
    final updatedTopMemes = [memeId, ...state.topMemes].take(5).toList();
    state = state.copyWith(topMemes: updatedTopMemes);
  }

  void resetWeeklyStats() {
    state = state.copyWith(weeklyShares: 0);
  }
}

final socialStatsProvider = StateNotifierProvider<SocialStatsNotifier, SocialStats>((ref) {
  return SocialStatsNotifier();
});

// Viral potential calculator
final viralPotentialProvider = Provider.family<double, TradeOutcome>((ref, outcome) {
  double potential = 0.0;

  // Base factors
  if (outcome.pnl.abs() > 1000) potential += 0.3;
  if (outcome.leverage > 10) potential += 0.2;
  if (outcome.consecutiveWins != null && outcome.consecutiveWins! > 5) potential += 0.4;
  if (outcome.streakDays != null && outcome.streakDays! > 7) potential += 0.5;
  if (outcome.territoryName != null) potential += 0.3;

  // Time-based boost (recent trades are more viral)
  final hoursSinceTradeTime = DateTime.now().difference(outcome.timestamp).inHours;
  if (hoursSinceTradeTime < 1) potential += 0.2;
  else if (hoursSinceTradeTime < 6) potential += 0.1;

  // Social stats boost
  final socialStats = ref.watch(socialStatsProvider);
  if (socialStats.weeklyShares > 10) potential += 0.1;

  return potential.clamp(0.0, 1.0);
});

// Auto-suggest share for viral trades
final autoSuggestShareProvider = Provider.family<bool, TradeOutcome>((ref, outcome) {
  final viralPotential = ref.watch(viralPotentialProvider(outcome));
  return viralPotential > 0.7; // Suggest sharing for high viral potential
});

// Weekly challenges for social engagement
class WeeklySocialChallenge {
  final String id;
  final String title;
  final String description;
  final MemeTemplate requiredTemplate;
  final int targetShares;
  final int currentShares;
  final String reward;
  final DateTime deadline;

  WeeklySocialChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredTemplate,
    required this.targetShares,
    required this.currentShares,
    required this.reward,
    required this.deadline,
  });

  bool get isCompleted => currentShares >= targetShares;
  bool get isExpired => DateTime.now().isAfter(deadline);
  double get progress => (currentShares / targetShares).clamp(0.0, 1.0);
}

final weeklySocialChallengeProvider = StateProvider<WeeklySocialChallenge?>((ref) {
  // Generate a weekly challenge
  final now = DateTime.now();
  final endOfWeek = now.add(Duration(days: 7 - now.weekday));
  
  return WeeklySocialChallenge(
    id: 'week_${now.millisecondsSinceEpoch}',
    title: '🔥 VIRAL WEEK',
    description: 'Share 5 big win memes this week',
    requiredTemplate: MemeTemplate.bigWin,
    targetShares: 5,
    currentShares: 0,
    reward: '100 bonus ink + exclusive NFT',
    deadline: endOfWeek,
  );
});

// Meme template suggestions based on recent performance
final suggestedMemeTemplatesProvider = Provider.family<List<MemeTemplate>, TradeOutcome>((ref, outcome) {
  final suggestions = <MemeTemplate>[];
  
  // Primary suggestion
  suggestions.add(outcome.suggestedTemplate);
  
  // Additional suggestions based on context
  if (outcome.isWin && outcome.pnl > 100) {
    suggestions.add(MemeTemplate.diamondHands);
  }
  
  if (outcome.streakDays != null && outcome.streakDays! > 3) {
    suggestions.add(MemeTemplate.streak);
  }
  
  if (outcome.territoryName != null) {
    suggestions.add(MemeTemplate.territoryConquest);
  }
  
  // Remove duplicates while preserving order
  return suggestions.toSet().toList();
});