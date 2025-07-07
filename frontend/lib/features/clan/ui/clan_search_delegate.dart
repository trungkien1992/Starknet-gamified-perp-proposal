import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/street_cred_theme.dart';
import '../../../app/theme/street_cred_design_system.dart';
import '../models/clan_models.dart';
import '../providers/clan_providers.dart';
import 'clan_card.dart';

class ClanSearchDelegate extends SearchDelegate<Clan?> {
  final WidgetRef ref;

  ClanSearchDelegate(this.ref);

  @override
  String get searchFieldLabel => 'Search clans...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: StreetCredTheme.darkGrey,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          onPressed: () {
            query = '';
            ref.read(clanSearchProvider.notifier).clearSearch();
          },
          icon: const Icon(Icons.clear, color: StreetCredTheme.neonBlue),
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back, color: Colors.white),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return _buildEmptyState('Enter a clan name to search');
    }

    // Trigger search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clanSearchProvider.notifier).searchClans(query);
    });

    return Container(
      decoration: StreetCredDesignSystem.backgroundGradient(StreetCredTheme.neonPink),
      child: Consumer(
        builder: (context, ref, child) {
          final searchResults = ref.watch(clanSearchProvider);
          
          return searchResults.when(
            data: (clans) {
              if (clans.isEmpty) {
                return _buildEmptyState('No clans found for "$query"');
              }
              
              return _buildSearchResults(clans);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: StreetCredTheme.neonPink),
            ),
            error: (error, _) => _buildErrorState(error.toString()),
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Container(
        decoration: StreetCredDesignSystem.backgroundGradient(StreetCredTheme.neonPink),
        child: Consumer(
          builder: (context, ref, child) {
            // Show recent/popular clans as suggestions
            final allClansAsync = ref.watch(availableClansProvider(null));
            
            return allClansAsync.when(
              data: (clans) => _buildSuggestions(clans),
              loading: () => const Center(
                child: CircularProgressIndicator(color: StreetCredTheme.neonPink),
              ),
              error: (error, _) => _buildErrorState(error.toString()),
            );
          },
        ),
      );
    }

    // Show filtered suggestions as user types
    return Consumer(
      builder: (context, ref, child) {
        final allClansAsync = ref.watch(availableClansProvider(null));
        
        return Container(
          decoration: StreetCredDesignSystem.backgroundGradient(StreetCredTheme.neonPink),
          child: allClansAsync.when(
            data: (clans) {
              final suggestions = clans
                  .where((clan) => 
                      clan.name.toLowerCase().contains(query.toLowerCase()) ||
                      clan.description.toLowerCase().contains(query.toLowerCase()) ||
                      clan.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
                  .take(5)
                  .toList();
              
              if (suggestions.isEmpty) {
                return _buildEmptyState('No suggestions for "$query"');
              }
              
              return _buildSuggestionsList(suggestions);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: StreetCredTheme.neonPink),
            ),
            error: (error, _) => _buildErrorState(error.toString()),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(List<Clan> clans) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Search Results (${clans.length})',
              style: StreetCredDesignSystem.subtitleStyle(StreetCredTheme.neonPink).copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final clan = clans[index];
                return Container(
                  margin: EdgeInsets.only(bottom: index < clans.length - 1 ? 16 : 0),
                  child: ClanCard(
                    clan: clan,
                    isListView: true,
                    onTap: () => close(context, clan),
                  ),
                );
              },
              childCount: clans.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions(List<Clan> clans) {
    // Show top clans by ranking as suggestions
    final topClans = [...clans]
      ..sort((a, b) => a.stats.ranking.compareTo(b.stats.ranking))
      ..take(8);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Popular Clans',
                  style: StreetCredDesignSystem.subtitleStyle(StreetCredTheme.neonBlue).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Discover the top-ranked clans in Hong Kong',
                  style: StreetCredDesignSystem.captionStyle().copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final clan = topClans.elementAt(index);
                return ClanCard(
                  clan: clan,
                  onTap: () {
                    query = clan.name;
                    showResults(context);
                  },
                );
              },
              childCount: topClans.length,
            ),
          ),
        ),
        
        const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
      ],
    );
  }

  Widget _buildSuggestionsList(List<Clan> suggestions) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Suggestions',
              style: StreetCredDesignSystem.subtitleStyle(StreetCredTheme.neonGreen).copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final clan = suggestions[index];
                return Container(
                  margin: EdgeInsets.only(bottom: index < suggestions.length - 1 ? 12 : 0),
                  child: _buildSuggestionItem(clan),
                );
              },
              childCount: suggestions.length,
            ),
          ),
        ),
        
        // Quick search filters
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Type',
                  style: StreetCredDesignSystem.subtitleStyle(StreetCredTheme.neonYellow).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: ClanType.values.map((type) => _buildFilterChip(type)).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionItem(Clan clan) {
    return GestureDetector(
      onTap: () {
        query = clan.name;
        showResults(context);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: clan.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [clan.primaryColor, clan.secondaryColor],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  clan.name.substring(0, 2).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clan.name,
                    style: StreetCredDesignSystem.bodyStyle().copyWith(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${clan.memberCount} members • ${clan.typeDisplayName}',
                    style: StreetCredDesignSystem.captionStyle().copyWith(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.search,
              color: clan.primaryColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(ClanType type) {
    return GestureDetector(
      onTap: () {
        query = type.name;
        showResults(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: StreetCredTheme.neonYellow.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          type.name.toUpperCase(),
          style: StreetCredDesignSystem.captionStyle().copyWith(
            color: StreetCredTheme.neonYellow,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Container(
        decoration: StreetCredDesignSystem.backgroundGradient(StreetCredTheme.neonPink),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🔍',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              'No Results',
              style: StreetCredDesignSystem.titleStyle(StreetCredTheme.neonPink),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: StreetCredDesignSystem.bodyStyle(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        decoration: StreetCredDesignSystem.backgroundGradient(StreetCredTheme.neonPink),
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
              'Search Error',
              style: StreetCredDesignSystem.titleStyle(StreetCredTheme.shortColor),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: StreetCredDesignSystem.bodyStyle(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}