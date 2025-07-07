import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/street_cred_theme.dart';
import '../../../app/theme/street_cred_design_system.dart';
import '../../../app/widgets/street_cred_card.dart';
import '../../../app/widgets/street_cred_header.dart';
import '../../../app/widgets/street_cred_button.dart' as scb;
import '../models/tutorial_models.dart';
import '../providers/tutorial_providers.dart';
import 'tutorial_step_widget.dart';
import 'reward_showcase_widget.dart';
import 'mock_trading_widget.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _celebrationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _celebrationAnimation;

  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _celebrationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );

    // Load tutorial progress on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tutorialProgressProvider.notifier).loadProgress();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(tutorialProgressProvider);
    final stepConfig = ref.watch(currentStepConfigProvider);
    final stats = ref.watch(tutorialStatsProvider);
    final achievement = ref.watch(achievementProvider);
    final latestReward = ref.watch(latestRewardProvider);

    // Update progress animation when step changes
    ref.listen<TutorialProgress>(tutorialProgressProvider, (previous, next) {
      if (previous?.currentStep != next.currentStep) {
        _progressController.forward();
      }
    });

    // Show celebration when achievement is earned
    ref.listen<String?>(achievementProvider, (previous, next) {
      if (next != null) {
        _celebrationController.forward().then((_) {
          Future.delayed(const Duration(seconds: 2), () {
            _celebrationController.reset();
            ref.read(achievementProvider.notifier).state = null;
          });
        });
      }
    });

    // Auto-redirect to main app when tutorial is completed
    if (progress.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/assets');
      });
    }

    return Scaffold(
      body: Container(
        decoration: StreetCredDesignSystem.backgroundGradient(stepConfig.themeColor),
        child: SafeArea(
          child: Stack(
            children: [
              // Main tutorial content
              Column(
                children: [
                  // Header with progress
                  _buildTutorialHeader(stepConfig, stats),
                  
                  // Main content area
                  Expanded(
                    child: PageView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStepContent(stepConfig, progress),
                      ],
                    ),
                  ),
                  
                  // Bottom action area
                  _buildBottomActions(stepConfig, progress),
                ],
              ),

              // Achievement overlay
              if (achievement != null)
                _buildAchievementOverlay(achievement),

              // Reward showcase overlay
              if (latestReward != null)
                _buildRewardOverlay(latestReward),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialHeader(TutorialStepConfig stepConfig, Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Title and skip button
          Row(
            children: [
              Expanded(
                child: Text(
                  'STREET TRAINING',
                  style: StreetCredDesignSystem.titleStyle(stepConfig.themeColor).copyWith(
                    fontSize: 20,
                    letterSpacing: 2,
                  ),
                ),
              ),
              if (ref.read(tutorialServiceProvider).isOptionalStep(stepConfig.step))
                TextButton(
                  onPressed: () => _skipStep(stepConfig.step),
                  child: Text(
                    'SKIP',
                    style: StreetCredDesignSystem.captionStyle().copyWith(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (stats['progress_percentage'] as double) * _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          stepConfig.themeColor,
                          stepConfig.themeColor.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // Progress text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${stats['steps_completed'] + 1} of ${stats['total_steps']}',
                style: StreetCredDesignSystem.captionStyle().copyWith(fontSize: 11),
              ),
              Text(
                '${((stats['progress_percentage'] as double) * 100).toInt()}% Complete',
                style: StreetCredDesignSystem.captionStyle().copyWith(
                  fontSize: 11,
                  color: stepConfig.themeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(TutorialStepConfig stepConfig, TutorialProgress progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Step widget
          Expanded(
            child: TutorialStepWidget(
              stepConfig: stepConfig,
              onStepCompleted: () => _completeCurrentStep(),
              onInteraction: (interaction) => _recordInteraction(interaction),
            ),
          ),

          // Mock trading widget for trading steps
          if (stepConfig.step == TutorialStep.mockTrade)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: MockTradingWidget(
                asset: stepConfig.mockTradeAsset!,
                onTradeExecuted: (trade) => _onMockTradeExecuted(trade),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(TutorialStepConfig stepConfig, TutorialProgress progress) {
    final canAdvance = ref.watch(canAdvanceStepProvider(ref.watch(tutorialContextProvider)));

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Estimated time
          if (!stepConfig.requiresInteraction) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.schedule, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Estimated time: ${ref.read(tutorialServiceProvider).getEstimatedStepTime(stepConfig.step).inSeconds}s',
                  style: StreetCredDesignSystem.captionStyle().copyWith(fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Action buttons
          Row(
            children: [
              if (stepConfig.step != TutorialStep.welcome) ...[
                Expanded(
                  child: scb.StreetCredButton(
                    text: 'BACK',
                    themeColor: Colors.grey,
                    style: scb.ButtonStyle.secondary,
                    onPressed: () => _goToPreviousStep(),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: stepConfig.step == TutorialStep.welcome ? 1 : 2,
                child: scb.StreetCredButton(
                  text: _getActionButtonText(stepConfig),
                  themeColor: stepConfig.themeColor,
                  style: scb.ButtonStyle.primary,
                  isLoading: stepConfig.requiresInteraction && !canAdvance,
                  onPressed: canAdvance ? () => _completeCurrentStep() : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementOverlay(String achievement) {
    return AnimatedBuilder(
      animation: _celebrationAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _celebrationAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  StreetCredTheme.neonYellow.withValues(alpha: 0.9),
                  StreetCredTheme.neonGreen.withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: StreetCredTheme.neonYellow.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'ACHIEVEMENT UNLOCKED!',
                  style: StreetCredDesignSystem.titleStyle(Colors.white).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  achievement,
                  style: StreetCredDesignSystem.bodyStyle().copyWith(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewardOverlay(TutorialReward reward) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: Center(
          child: RewardShowcaseWidget(
            reward: reward,
            onDismiss: () {
              ref.read(latestRewardProvider.notifier).state = null;
            },
          ),
        ),
      ),
    );
  }

  String _getActionButtonText(TutorialStepConfig stepConfig) {
    switch (stepConfig.step) {
      case TutorialStep.welcome:
        return 'START TRAINING';
      case TutorialStep.graduated:
        return 'ENTER THE ARENA';
      default:
        return stepConfig.requiresInteraction ? 'WAITING...' : 'CONTINUE';
    }
  }

  void _completeCurrentStep() async {
    final currentStep = ref.read(tutorialProgressProvider).currentStep;
    final context = ref.read(tutorialContextProvider);
    
    await ref.read(tutorialProgressProvider.notifier).completeStep(currentStep, context: context);
    
    // Show achievement
    final achievementMessage = ref.read(tutorialServiceProvider).getAchievementMessage(currentStep);
    ref.read(achievementProvider.notifier).state = achievementMessage;
    
    // Show rewards if any
    final stepConfig = ref.read(tutorialServiceProvider).getStepConfig(currentStep);
    if (stepConfig.rewards.isNotEmpty) {
      ref.read(latestRewardProvider.notifier).state = stepConfig.rewards.first;
    }
  }

  void _goToPreviousStep() {
    // Implementation for going back (simplified for demo)
    context.pop();
  }

  void _skipStep(TutorialStep step) {
    ref.read(tutorialProgressProvider.notifier).skipStep(step);
  }

  void _recordInteraction(String interaction) {
    ref.read(tutorialInteractionProvider.notifier).markInteraction(interaction);
  }

  void _onMockTradeExecuted(MockTrade trade) {
    ref.read(tutorialProgressProvider.notifier).addMockTrade(trade);
    _recordInteraction('executed_mock_trade');
  }
}