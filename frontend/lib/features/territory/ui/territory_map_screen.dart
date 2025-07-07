import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/street_cred_theme.dart';
import '../../../app/theme/street_cred_design_system.dart';
import '../../../app/widgets/street_cred_header.dart';
import '../models/territory_models.dart';
import '../providers/territory_provider.dart';
import 'territory_card.dart';
import 'territory_leaderboard.dart';

class TerritoryMapScreen extends ConsumerStatefulWidget {
  const TerritoryMapScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TerritoryMapScreen> createState() => _TerritoryMapScreenState();
}

class _TerritoryMapScreenState extends ConsumerState<TerritoryMapScreen>
    with TickerProviderStateMixin {
  late AnimationController _mapController;
  late AnimationController _prestigeController;
  late Animation<double> _mapAnimation;
  late Animation<double> _prestigeAnimation;

  @override
  void initState() {
    super.initState();
    
    _mapController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _prestigeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _mapAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mapController, curve: Curves.easeInOut),
    );

    _prestigeAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _prestigeController, curve: Curves.easeInOut),
    );

    _mapController.forward();
    _prestigeController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _prestigeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final territories = ref.watch(territoriesProvider);
    final userPrestige = ref.watch(userPrestigeProvider);
    final conqueredTerritories = ref.watch(conqueredTerritoriesProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/arena'),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              StreetCredTheme.darkAlley,
              StreetCredTheme.darkGrey,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with prestige
              StreetCredHeader(
                title: 'HONG KONG TERRITORIES',
                themeColor: StreetCredTheme.neonPink,
                showBrandSymbol: false,
                actions: [
                  AnimatedBuilder(
                    animation: _prestigeAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _prestigeAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: StreetCredDesignSystem.statusBadgeDecoration(
                            StreetCredTheme.neonYellow,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                color: StreetCredTheme.neonYellow,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$userPrestige',
                                style: StreetCredDesignSystem.bodyStyle().copyWith(
                                  color: StreetCredTheme.neonYellow,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _showLeaderboard(context),
                    icon: const Icon(
                      Icons.leaderboard,
                      color: StreetCredTheme.neonBlue,
                      size: 24,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Conquest summary
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      StreetCredTheme.neonPink.withValues(alpha: 0.2),
                      StreetCredTheme.neonBlue.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: StreetCredTheme.neonPink,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      'Conquered',
                      '${conqueredTerritories.length}',
                      StreetCredTheme.neonGreen,
                    ),
                    _buildStatColumn(
                      'In Progress',
                      '${territories.where((t) => t.status == TerritoryStatus.inProgress).length}',
                      StreetCredTheme.neonYellow,
                    ),
                    _buildStatColumn(
                      'Locked',
                      '${territories.where((t) => t.status == TerritoryStatus.locked).length}',
                      Colors.grey,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Territory grid
              Expanded(
                child: AnimatedBuilder(
                  animation: _mapAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - _mapAnimation.value)),
                      child: Opacity(
                        opacity: _mapAnimation.value,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: territories.length,
                          itemBuilder: (context, index) {
                            final territory = territories[index];
                            return TerritoryCard(
                              territory: territory,
                              onTap: () => _selectTerritory(territory),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: StreetCredDesignSystem.subtitleStyle(color).copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: StreetCredDesignSystem.captionStyle().copyWith(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }

  void _selectTerritory(Territory territory) {
    ref.read(currentTerritoryProvider.notifier).state = territory.id;
    
    // Show selection feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Territory selected: ${territory.name}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: territory.themeColor,
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Return to arena to trade on selected territory
    context.go('/arena');
  }

  void _showLeaderboard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const TerritoryLeaderboard(),
    );
  }
}