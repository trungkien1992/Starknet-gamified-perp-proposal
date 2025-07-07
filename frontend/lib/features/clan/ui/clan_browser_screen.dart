import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/street_cred_theme.dart';
import '../../../app/theme/street_cred_design_system.dart';
import '../../../app/widgets/street_cred_card.dart';
import '../../../app/widgets/street_cred_header.dart';
import '../../../app/widgets/street_cred_button.dart' as scb;
import '../models/clan_models.dart';
import '../providers/clan_providers.dart';
import 'clan_card.dart';
import 'clan_search_delegate.dart';

class ClanBrowserScreen extends ConsumerStatefulWidget {
  const ClanBrowserScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ClanBrowserScreen> createState() => _ClanBrowserScreenState();
}

class _ClanBrowserScreenState extends ConsumerState<ClanBrowserScreen>
    with TickerProviderStateMixin {
  late AnimationController _filterController;
  late AnimationController _listController;
  late Animation<double> _filterAnimation;
  late Animation<double> _listAnimation;

  @override
  void initState() {
    super.initState();
    
    _filterController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _listController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _filterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _filterController, curve: Curves.easeOut),
    );

    _listAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listController, curve: Curves.easeOutBack),
    );

    _listController.forward();
  }

  @override
  void dispose() {
    _filterController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedClansAsync = ref.watch(sortedClansProvider);
    final currentFilter = ref.watch(clanFilterProvider);
    final currentSort = ref.watch(clanSortProvider);
    final viewMode = ref.watch(clanViewModeProvider);
    final userClan = ref.watch(userClanProvider);
    final recommendations = ref.watch(clanRecommendationsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/arena'),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () => _showSearch(context),
            icon: const Icon(Icons.search, color: StreetCredTheme.neonBlue),
          ),
          IconButton(
            onPressed: () => _toggleViewMode(),
            icon: Icon(
              viewMode == 'grid' ? Icons.view_list : Icons.grid_view,
              color: StreetCredTheme.neonGreen,
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: StreetCredDesignSystem.backgroundGradient(StreetCredTheme.neonPink),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              StreetCredHeader(
                title: userClan != null ? 'EXPLORE CLANS' : 'JOIN A CLAN',
                themeColor: StreetCredTheme.neonPink,
                showBrandSymbol: false,
                subtitle: userClan != null 
                    ? 'Discover other crews in Hong Kong'
                    : 'Find your street art trading crew',
              ),

              const SizedBox(height: 16),

              // Filter and sort controls
              _buildFilterControls(currentFilter, currentSort),

              const SizedBox(height: 16),

              // Current clan status (if member)
              if (userClan != null) ...[
                _buildCurrentClanCard(userClan),
                const SizedBox(height: 16),
              ],

              // Recommendations section (if not in clan)
              if (userClan == null) ...[
                _buildRecommendationsSection(recommendations),
                const SizedBox(height: 16),
              ],

              // Main clan list
              Expanded(
                child: _buildClanList(sortedClansAsync, viewMode),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: userClan != null 
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateClanDialog(),
              backgroundColor: StreetCredTheme.neonYellow,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add),
              label: const Text(
                'CREATE CLAN',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildFilterControls(ClanType? currentFilter, String currentSort) {
    return AnimatedBuilder(
      animation: _filterAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Filter dropdown
              Expanded(
                child: GestureDetector(
                  onTap: () => _showFilterMenu(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: StreetCredTheme.neonBlue.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          color: StreetCredTheme.neonBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentFilter != null 
                                ? currentFilter.name.toUpperCase()
                                : 'ALL TYPES',
                            style: StreetCredDesignSystem.bodyStyle().copyWith(
                              color: StreetCredTheme.neonBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: StreetCredTheme.neonBlue,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Sort dropdown
              Expanded(
                child: GestureDetector(
                  onTap: () => _showSortMenu(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: StreetCredTheme.neonGreen.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sort,
                          color: StreetCredTheme.neonGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'SORT: ${currentSort.toUpperCase()}',
                            style: StreetCredDesignSystem.bodyStyle().copyWith(
                              color: StreetCredTheme.neonGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: StreetCredTheme.neonGreen,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentClanCard(Clan clan) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: StreetCredCard(
        themeColor: clan.primaryColor,
        size: CardSize.small,
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [clan.primaryColor, clan.secondaryColor],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  clan.name.substring(0, 2).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR CLAN',
                    style: StreetCredDesignSystem.captionStyle().copyWith(
                      color: clan.primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    clan.name,
                    style: StreetCredDesignSystem.subtitleStyle(Colors.white).copyWith(
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${clan.memberCount}/${clan.maxMembers} members • Rank #${clan.stats.ranking}',
                    style: StreetCredDesignSystem.captionStyle().copyWith(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.arrow_forward_ios,
              color: clan.primaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection(AsyncValue<List<Clan>> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'RECOMMENDED FOR YOU',
            style: StreetCredDesignSystem.subtitleStyle(StreetCredTheme.neonYellow).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          height: 140,
          child: recommendations.when(
            data: (clans) => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: clans.length,
              itemBuilder: (context, index) {
                final clan = clans[index];
                return Container(
                  width: 280,
                  margin: EdgeInsets.only(right: index < clans.length - 1 ? 16 : 0),
                  child: ClanCard(
                    clan: clan,
                    isCompact: true,
                    onTap: () => _showClanDetails(clan),
                  ),
                );
              },
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: StreetCredTheme.neonYellow),
            ),
            error: (_, __) => Container(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Failed to load recommendations',
                style: StreetCredDesignSystem.captionStyle(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClanList(AsyncValue<List<Clan>> clansAsync, String viewMode) {
    return AnimatedBuilder(
      animation: _listAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _listAnimation.value)),
          child: Opacity(
            opacity: _listAnimation.value,
            child: clansAsync.when(
              data: (clans) {
                if (clans.isEmpty) {
                  return _buildEmptyState();
                }

                if (viewMode == 'grid') {
                  return GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: clans.length,
                    itemBuilder: (context, index) {
                      return ClanCard(
                        clan: clans[index],
                        onTap: () => _showClanDetails(clans[index]),
                      );
                    },
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: clans.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.only(bottom: index < clans.length - 1 ? 16 : 0),
                        child: ClanCard(
                          clan: clans[index],
                          isListView: true,
                          onTap: () => _showClanDetails(clans[index]),
                        ),
                      );
                    },
                  );
                }
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: StreetCredTheme.neonPink),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: StreetCredTheme.shortColor,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load clans',
                      style: StreetCredDesignSystem.bodyStyle(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: StreetCredDesignSystem.captionStyle(),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🏢',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            'No Clans Found',
            style: StreetCredDesignSystem.titleStyle(StreetCredTheme.neonPink),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search criteria',
            style: StreetCredDesignSystem.bodyStyle(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          scb.StreetCredButton(
            text: 'CLEAR FILTERS',
            themeColor: StreetCredTheme.neonBlue,
            style: scb.ButtonStyle.secondary,
            onPressed: () => _clearFilters(),
          ),
        ],
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: ClanSearchDelegate(ref),
    );
  }

  void _toggleViewMode() {
    final currentMode = ref.read(clanViewModeProvider);
    ref.read(clanViewModeProvider.notifier).state = 
        currentMode == 'grid' ? 'list' : 'grid';
  }

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: StreetCredTheme.darkGrey,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FILTER BY TYPE',
                    style: StreetCredDesignSystem.subtitleStyle(StreetCredTheme.neonBlue).copyWith(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildFilterOption(null, 'All Types', '🌆'),
                  _buildFilterOption(ClanType.casual, 'Casual', '🎯'),
                  _buildFilterOption(ClanType.competitive, 'Competitive', '⚔️'),
                  _buildFilterOption(ClanType.elite, 'Elite', '👑'),
                  _buildFilterOption(ClanType.exclusive, 'Exclusive', '💎'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(ClanType? type, String label, String emoji) {
    final isSelected = ref.watch(clanFilterProvider) == type;
    
    return GestureDetector(
      onTap: () {
        ref.read(clanFilterProvider.notifier).state = type;
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? StreetCredTheme.neonBlue.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? StreetCredTheme.neonBlue
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: StreetCredDesignSystem.bodyStyle().copyWith(
                  color: isSelected ? StreetCredTheme.neonBlue : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: StreetCredTheme.neonBlue,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showSortMenu() {
    final sortOptions = [
      {'key': 'name', 'label': 'Name', 'icon': Icons.sort_by_alpha},
      {'key': 'members', 'label': 'Members', 'icon': Icons.group},
      {'key': 'ranking', 'label': 'Ranking', 'icon': Icons.emoji_events},
      {'key': 'type', 'label': 'Type', 'icon': Icons.category},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: StreetCredTheme.darkGrey,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SORT BY',
                    style: StreetCredDesignSystem.subtitleStyle(StreetCredTheme.neonGreen).copyWith(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ...sortOptions.map((option) => _buildSortOption(
                    option['key'] as String,
                    option['label'] as String,
                    option['icon'] as IconData,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String key, String label, IconData icon) {
    final isSelected = ref.watch(clanSortProvider) == key;
    
    return GestureDetector(
      onTap: () {
        ref.read(clanSortProvider.notifier).state = key;
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? StreetCredTheme.neonGreen.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? StreetCredTheme.neonGreen
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? StreetCredTheme.neonGreen : Colors.white54,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: StreetCredDesignSystem.bodyStyle().copyWith(
                  color: isSelected ? StreetCredTheme.neonGreen : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: StreetCredTheme.neonGreen,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    ref.read(clanFilterProvider.notifier).state = null;
    ref.read(clanSortProvider.notifier).state = 'name';
  }

  void _showClanDetails(Clan clan) {
    ref.read(selectedClanProvider.notifier).state = clan;
    context.push('/clan/${clan.id}');
  }

  void _showCreateClanDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🏗️ Clan creation coming soon!'),
        backgroundColor: StreetCredTheme.neonYellow,
      ),
    );
  }
}