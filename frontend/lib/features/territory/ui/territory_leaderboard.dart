import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/street_cred_theme.dart';
import '../../../app/theme/street_cred_design_system.dart';
import '../providers/territory_provider.dart';

class TerritoryLeaderboard extends ConsumerWidget {
  const TerritoryLeaderboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankings = ref.watch(territoryLeaderboardProvider);

    return Container(
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
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: StreetCredTheme.neonYellow,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'TERRITORY MASTERS',
                  style: StreetCredDesignSystem.subtitleStyle(
                    StreetCredTheme.neonYellow,
                  ).copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Live Rankings',
                  style: StreetCredDesignSystem.captionStyle().copyWith(
                    color: StreetCredTheme.neonGreen,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Top 3 podium
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2nd place
                if (rankings.length > 1)
                  _buildPodiumPlace(rankings[1], 2, 80),
                
                // 1st place
                if (rankings.isNotEmpty)
                  _buildPodiumPlace(rankings[0], 1, 100),
                
                // 3rd place  
                if (rankings.length > 2)
                  _buildPodiumPlace(rankings[2], 3, 60),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Rankings list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: rankings.length,
              itemBuilder: (context, index) {
                final ranking = rankings[index];
                final isCurrentUser = ranking.userId == 'current';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCurrentUser 
                        ? StreetCredTheme.neonBlue.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrentUser 
                          ? StreetCredTheme.neonBlue
                          : Colors.transparent,
                      width: isCurrentUser ? 2 : 0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Rank
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getRankColor(index + 1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // User info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  ranking.username,
                                  style: StreetCredDesignSystem.bodyStyle().copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentUser 
                                        ? StreetCredTheme.neonBlue
                                        : Colors.white,
                                  ),
                                ),
                                if (isCurrentUser) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: StreetCredTheme.neonBlue,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'YOU',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${ranking.territoriesOwned} territories owned',
                              style: StreetCredDesignSystem.captionStyle().copyWith(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Prestige score
                      Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                color: StreetCredTheme.neonYellow,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${ranking.prestige}',
                                style: StreetCredDesignSystem.bodyStyle().copyWith(
                                  color: StreetCredTheme.neonYellow,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'PRESTIGE',
                            style: StreetCredDesignSystem.captionStyle().copyWith(
                              fontSize: 8,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(TerritoryRanking ranking, int place, double height) {
    final colors = {
      1: StreetCredTheme.neonYellow,
      2: Colors.grey[400]!,
      3: const Color(0xFFCD7F32), // Bronze
    };

    final icons = {
      1: Icons.emoji_events,
      2: Icons.military_tech,
      3: Icons.workspace_premium,
    };

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors[place],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors[place]!.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              icons[place],
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(height: 8),

          // Username
          Text(
            ranking.username,
            style: StreetCredDesignSystem.captionStyle().copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: colors[place],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Prestige
          Text(
            '${ranking.prestige}',
            style: StreetCredDesignSystem.captionStyle().copyWith(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          // Podium
          Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors[place]!.withValues(alpha: 0.8),
                  colors[place]!.withValues(alpha: 0.4),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border.all(
                color: colors[place]!,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '$place',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank <= 3) return StreetCredTheme.neonYellow.withValues(alpha: 0.8);
    if (rank <= 10) return StreetCredTheme.neonBlue.withValues(alpha: 0.8);
    return Colors.grey.withValues(alpha: 0.8);
  }
}