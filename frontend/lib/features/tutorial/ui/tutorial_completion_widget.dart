import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/street_cred_theme.dart';
import '../../../app/theme/street_cred_design_system.dart';
import '../../../app/widgets/street_cred_card.dart';
import '../../../app/widgets/street_cred_button.dart' as scb;
import '../models/tutorial_models.dart';
import '../providers/tutorial_providers.dart';

class TutorialCompletionWidget extends ConsumerStatefulWidget {
  const TutorialCompletionWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<TutorialCompletionWidget> createState() => _TutorialCompletionWidgetState();
}

class _TutorialCompletionWidgetState extends ConsumerState<TutorialCompletionWidget>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _statsController;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _statsAnimation;

  @override
  void initState() {
    super.initState();
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _celebrationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );

    _statsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.easeOutBack),
    );

    _celebrationController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _statsController.forward();
    });
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(tutorialProgressProvider);
    final analytics = ref.watch(tutorialAnalyticsProvider);
    final stats = ref.watch(tutorialStatsProvider);
    final nftDistribution = ref.watch(nftRarityDistributionProvider);

    return Container(
      decoration: StreetCredDesignSystem.backgroundGradient(StreetCredTheme.neonYellow),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Celebration header
              _buildCelebrationHeader(),
              
              const SizedBox(height: 32),
              
              // Stats display
              Expanded(
                child: _buildStatsDisplay(analytics, stats, nftDistribution),
              ),
              
              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCelebrationHeader() {
    return AnimatedBuilder(
      animation: _celebrationAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _celebrationAnimation.value,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Glow effect
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          StreetCredTheme.neonYellow.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  
                  // Trophy
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          StreetCredTheme.neonYellow,
                          StreetCredTheme.neonGreen,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'STREET CERTIFIED!',
                style: StreetCredDesignSystem.titleStyle(StreetCredTheme.neonYellow).copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'You\'ve mastered the streets of Hong Kong',
                style: StreetCredDesignSystem.bodyStyle().copyWith(
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsDisplay(TutorialAnalytics analytics, Map<String, dynamic> stats, Map<StarterNFTRarity, int> nftDistribution) {
    return AnimatedBuilder(
      animation: _statsAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _statsAnimation.value)),
          child: Opacity(
            opacity: _statsAnimation.value,
            child: Column(
              children: [
                // Main stats
                StreetCredCard(
                  themeColor: StreetCredTheme.neonGreen,
                  size: CardSize.large,
                  child: Column(
                    children: [
                      Text(
                        'TRAINING COMPLETE',
                        style: StreetCredDesignSystem.subtitleStyle(StreetCredTheme.neonGreen).copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            '${stats['time_spent']}',
                            'Minutes',
                            StreetCredTheme.neonBlue,
                            Icons.schedule,
                          ),
                          _buildStatItem(
                            '${stats['mock_trades']}',
                            'Trades',
                            StreetCredTheme.neonPink,
                            Icons.trending_up,
                          ),
                          _buildStatItem(
                            '${(stats['win_rate'] * 100).toInt()}%',
                            'Win Rate',
                            StreetCredTheme.neonYellow,
                            Icons.emoji_events,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Rewards earned
                StreetCredCard(
                  themeColor: StreetCredTheme.neonPink,
                  size: CardSize.medium,
                  child: Column(
                    children: [
                      Text(
                        'REWARDS EARNED',
                        style: StreetCredDesignSystem.subtitleStyle(StreetCredTheme.neonPink).copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildRewardItem('🎨', '${stats['rewards_earned']}', 'Items'),
                          _buildRewardItem('💎', '${nftDistribution[StarterNFTRarity.rare] ?? 0}', 'Rare NFTs'),
                          _buildRewardItem('🏆', '${nftDistribution[StarterNFTRarity.legendary] ?? 0}', 'Legendary'),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Achievement showcase
                StreetCredCard(
                  themeColor: StreetCredTheme.neonBlue,
                  size: CardSize.small,
                  child: Column(
                    children: [
                      Text(
                        'ACHIEVEMENT UNLOCKED',
                        style: StreetCredDesignSystem.subtitleStyle(StreetCredTheme.neonBlue).copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              StreetCredTheme.neonYellow.withValues(alpha: 0.3),
                              StreetCredTheme.neonGreen.withValues(alpha: 0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: StreetCredTheme.neonYellow),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🎯', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              'Street Rookie',
                              style: StreetCredDesignSystem.bodyStyle().copyWith(
                                color: StreetCredTheme.neonYellow,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String value, String label, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: StreetCredDesignSystem.titleStyle(color).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: StreetCredDesignSystem.captionStyle().copyWith(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildRewardItem(String emoji, String count, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          count,
          style: StreetCredDesignSystem.bodyStyle().copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: StreetCredDesignSystem.captionStyle().copyWith(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary action - Enter Arena
        scb.StreetCredButton(
          text: 'ENTER THE ARENA',
          themeColor: StreetCredTheme.neonGreen,
          style: scb.ButtonStyle.primary,
          width: double.infinity,
          height: 56,
          leadingIcon: Icons.sports_martial_arts,
          onPressed: () {
            context.go('/assets');
          },
        ),
        
        const SizedBox(height: 12),
        
        // Secondary actions
        Row(
          children: [
            Expanded(
              child: scb.StreetCredButton(
                text: 'VIEW REWARDS',
                themeColor: StreetCredTheme.neonPink,
                style: scb.ButtonStyle.secondary,
                height: 44,
                leadingIcon: Icons.card_giftcard,
                onPressed: () {
                  _showRewardsModal();
                },
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: scb.StreetCredButton(
                text: 'SHARE',
                themeColor: StreetCredTheme.neonBlue,
                style: scb.ButtonStyle.secondary,
                height: 44,
                leadingIcon: Icons.share,
                onPressed: () {
                  _shareCompletion();
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Community links
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            children: [
              Text(
                'Join the StreetCred Community',
                style: StreetCredDesignSystem.subtitleStyle(Colors.white).copyWith(
                  fontSize: 14,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSocialButton('Discord', Icons.chat, () {}),
                  _buildSocialButton('Twitter', Icons.alternate_email, () {}),
                  _buildSocialButton('Telegram', Icons.send, () {}),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: StreetCredDesignSystem.captionStyle().copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _showRewardsModal() {
    final progress = ref.read(tutorialProgressProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: StreetCredTheme.darkGrey,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'YOUR REWARDS',
                style: StreetCredDesignSystem.subtitleStyle(StreetCredTheme.neonPink).copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Rewards list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: progress.earnedRewards.length,
                itemBuilder: (context, index) {
                  final reward = progress.earnedRewards[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          reward.color.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: reward.color.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Text(reward.emoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reward.name,
                                style: StreetCredDesignSystem.bodyStyle().copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                reward.description,
                                style: StreetCredDesignSystem.captionStyle().copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (reward.rarity != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: reward.color.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              reward.rarity!.name.toUpperCase(),
                              style: StreetCredDesignSystem.captionStyle().copyWith(
                                color: reward.color,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareCompletion() {
    // Generate completion share content
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Tutorial completion shared!'),
        backgroundColor: StreetCredTheme.neonGreen,
      ),
    );
  }
}