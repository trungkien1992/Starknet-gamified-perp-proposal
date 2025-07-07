import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/street_cred_theme.dart';
import '../../../app/theme/street_cred_design_system.dart';
import '../../../app/widgets/street_cred_card.dart';
import '../../../app/widgets/street_cred_button.dart' as scb;
import '../models/tutorial_models.dart';
import '../providers/tutorial_providers.dart';
import '../../trade/widgets/swipe_spray_gauge.dart';

class TutorialStepWidget extends ConsumerStatefulWidget {
  final TutorialStepConfig stepConfig;
  final VoidCallback onStepCompleted;
  final Function(String) onInteraction;

  const TutorialStepWidget({
    Key? key,
    required this.stepConfig,
    required this.onStepCompleted,
    required this.onInteraction,
  }) : super(key: key);

  @override
  ConsumerState<TutorialStepWidget> createState() => _TutorialStepWidgetState();
}

class _TutorialStepWidgetState extends ConsumerState<TutorialStepWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _instructionController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _instructionAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _instructionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _instructionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _instructionController, curve: Curves.easeOut),
    );

    _pulseController.repeat(reverse: true);
    _instructionController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(stepMessagesProvider(widget.stepConfig.step));
    final tips = ref.watch(stepTipsProvider(widget.stepConfig.step));
    final shouldShowHint = ref.watch(shouldShowHintProvider(widget.stepConfig.step));

    return AnimatedBuilder(
      animation: _instructionAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _instructionAnimation.value)),
          child: Opacity(
            opacity: _instructionAnimation.value,
            child: Column(
              children: [
                // Step icon and title
                _buildStepHeader(),
                
                const SizedBox(height: 24),
                
                // Main interactive area
                Expanded(
                  child: _buildInteractiveArea(),
                ),
                
                const SizedBox(height: 20),
                
                // Messages and tips
                _buildMessagesArea(messages, tips),
                
                // Hint overlay
                if (shouldShowHint)
                  _buildHintOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepHeader() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.stepConfig.requiresInteraction ? _pulseAnimation.value : 1.0,
          child: StreetCredCard(
            themeColor: widget.stepConfig.themeColor,
            size: CardSize.medium,
            enablePressEffect: false,
            child: Column(
              children: [
                Icon(
                  widget.stepConfig.icon,
                  color: widget.stepConfig.themeColor,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.stepConfig.title,
                  style: StreetCredDesignSystem.titleStyle(widget.stepConfig.themeColor).copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.stepConfig.description,
                  style: StreetCredDesignSystem.bodyStyle().copyWith(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInteractiveArea() {
    switch (widget.stepConfig.step) {
      case TutorialStep.welcome:
        return _buildWelcomeArea();
      
      case TutorialStep.walletConnect:
        return _buildWalletConnectArea();
      
      case TutorialStep.firstSwipe:
        return _buildSwipeArea();
      
      case TutorialStep.leverageControl:
        return _buildLeverageArea();
      
      case TutorialStep.territorySelect:
        return _buildTerritoryArea();
      
      case TutorialStep.weatherSystem:
        return _buildWeatherArea();
      
      case TutorialStep.shareFirst:
        return _buildShareArea();
      
      case TutorialStep.collectReward:
        return _buildRewardArea();
      
      default:
        return _buildDefaultArea();
    }
  }

  Widget _buildWelcomeArea() {
    return StreetCredCard(
      themeColor: widget.stepConfig.themeColor,
      size: CardSize.large,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🏙️',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            'Hong Kong Streets',
            style: StreetCredDesignSystem.subtitleStyle(widget.stepConfig.themeColor).copyWith(
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Where DeFi meets Street Art',
            style: StreetCredDesignSystem.bodyStyle().copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletConnectArea() {
    return StreetCredCard(
      themeColor: widget.stepConfig.themeColor,
      size: CardSize.large,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: Colors.white,
            size: 80,
          ),
          const SizedBox(height: 20),
          scb.StreetCredButton(
            text: 'CONNECT WALLET',
            themeColor: widget.stepConfig.themeColor,
            style: scb.ButtonStyle.primary,
            width: 200,
            onPressed: () {
              widget.onInteraction('wallet_connected');
              Future.delayed(const Duration(seconds: 1), () {
                widget.onStepCompleted();
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            '(Demo - Safe Connection)',
            style: StreetCredDesignSystem.captionStyle().copyWith(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeArea() {
    return Container(
      height: 300,
      child: SwipeSprayGauge(
        isEnabled: true,
        isDemoMode: true,
        onTrade: (direction, leverage) {
          widget.onInteraction('performed_swipe');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Perfect swipe! Direction: $direction'),
              backgroundColor: widget.stepConfig.themeColor,
              duration: const Duration(seconds: 2),
            ),
          );
          Future.delayed(const Duration(seconds: 1), () {
            widget.onStepCompleted();
          });
        },
      ),
    );
  }

  Widget _buildLeverageArea() {
    double leverage = 2.0;
    
    return StatefulBuilder(
      builder: (context, setState) {
        return StreetCredCard(
          themeColor: widget.stepConfig.themeColor,
          size: CardSize.large,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'LEVERAGE',
                style: StreetCredDesignSystem.subtitleStyle(widget.stepConfig.themeColor),
              ),
              const SizedBox(height: 20),
              Text(
                '${leverage.toStringAsFixed(1)}x',
                style: StreetCredDesignSystem.titleStyle(Colors.white).copyWith(
                  fontSize: 36,
                ),
              ),
              const SizedBox(height: 20),
              Slider(
                value: leverage,
                min: 1.0,
                max: 20.0,
                divisions: 19,
                activeColor: widget.stepConfig.themeColor,
                inactiveColor: Colors.white24,
                onChanged: (value) {
                  setState(() {
                    leverage = value;
                  });
                  if (!(ref.read(tutorialInteractionProvider)['adjusted_leverage'] ?? false)) {
                    widget.onInteraction('adjusted_leverage');
                    Future.delayed(const Duration(seconds: 1), () {
                      widget.onStepCompleted();
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Drag to adjust trading power',
                style: StreetCredDesignSystem.captionStyle().copyWith(fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTerritoryArea() {
    final territories = ['Central 中環', 'Tsim Sha Tsui 尖沙咀', 'Wan Chai 灣仔', 'Causeway Bay 銅鑼灣'];
    
    return StreetCredCard(
      themeColor: widget.stepConfig.themeColor,
      size: CardSize.large,
      child: Column(
        children: [
          Text(
            'SELECT TERRITORY',
            style: StreetCredDesignSystem.subtitleStyle(widget.stepConfig.themeColor),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: territories.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    widget.onInteraction('selected_territory');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Territory selected: ${territories[index]}'),
                        backgroundColor: widget.stepConfig.themeColor,
                      ),
                    );
                    Future.delayed(const Duration(seconds: 1), () {
                      widget.onStepCompleted();
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.stepConfig.themeColor.withValues(alpha: 0.6),
                          widget.stepConfig.themeColor.withValues(alpha: 0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.stepConfig.themeColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        territories[index],
                        style: StreetCredDesignSystem.captionStyle().copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherArea() {
    final weatherStates = [
      {'emoji': '☀️', 'name': 'Clear', 'effect': 'Normal conditions'},
      {'emoji': '🌧️', 'name': 'Rain', 'effect': '+25% Ink efficiency'},
      {'emoji': '⛈️', 'name': 'Storm', 'effect': '+50% Volatility'},
    ];

    return StreetCredCard(
      themeColor: widget.stepConfig.themeColor,
      size: CardSize.large,
      child: Column(
        children: [
          Text(
            'WEATHER SYSTEM',
            style: StreetCredDesignSystem.subtitleStyle(widget.stepConfig.themeColor),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: weatherStates.length,
              itemBuilder: (context, index) {
                final weather = weatherStates[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: GestureDetector(
                    onTap: () {
                      widget.onInteraction('interacted_weather');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Weather effect: ${weather['effect']}'),
                          backgroundColor: widget.stepConfig.themeColor,
                        ),
                      );
                      Future.delayed(const Duration(seconds: 1), () {
                        widget.onStepCompleted();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.stepConfig.themeColor.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            weather['emoji']!,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  weather['name']!,
                                  style: StreetCredDesignSystem.bodyStyle().copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  weather['effect']!,
                                  style: StreetCredDesignSystem.captionStyle().copyWith(
                                    color: widget.stepConfig.themeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareArea() {
    return StreetCredCard(
      themeColor: widget.stepConfig.themeColor,
      size: CardSize.large,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '📱',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 20),
          Text(
            'Share Your Art',
            style: StreetCredDesignSystem.subtitleStyle(widget.stepConfig.themeColor),
          ),
          const SizedBox(height: 16),
          scb.StreetCredButton(
            text: 'CREATE MEME',
            themeColor: widget.stepConfig.themeColor,
            style: scb.ButtonStyle.primary,
            width: 180,
            onPressed: () {
              widget.onInteraction('shared_meme');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Meme created! Ready to share!'),
                  backgroundColor: widget.stepConfig.themeColor,
                ),
              );
              Future.delayed(const Duration(seconds: 1), () {
                widget.onStepCompleted();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRewardArea() {
    return StreetCredCard(
      themeColor: widget.stepConfig.themeColor,
      size: CardSize.large,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🎁',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 20),
          Text(
            'Claim Rewards',
            style: StreetCredDesignSystem.subtitleStyle(widget.stepConfig.themeColor),
          ),
          const SizedBox(height: 16),
          scb.StreetCredButton(
            text: 'COLLECT',
            themeColor: widget.stepConfig.themeColor,
            style: scb.ButtonStyle.primary,
            width: 160,
            onPressed: () {
              widget.onInteraction('collected_reward');
              widget.onStepCompleted();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultArea() {
    return StreetCredCard(
      themeColor: widget.stepConfig.themeColor,
      size: CardSize.large,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.stepConfig.icon,
            color: widget.stepConfig.themeColor,
            size: 64,
          ),
          const SizedBox(height: 20),
          Text(
            widget.stepConfig.instruction,
            style: StreetCredDesignSystem.bodyStyle(),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesArea(List<String> messages, List<String> tips) {
    return Column(
      children: [
        // Encouraging message
        if (messages.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.stepConfig.themeColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              messages.first,
              style: StreetCredDesignSystem.bodyStyle().copyWith(
                color: widget.stepConfig.themeColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // Tips
        if (tips.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white54,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tips.first,
                    style: StreetCredDesignSystem.captionStyle().copyWith(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHintOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: StreetCredTheme.neonYellow.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: StreetCredTheme.neonYellow.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.help_outline,
              color: Colors.black,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.stepConfig.instruction,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}