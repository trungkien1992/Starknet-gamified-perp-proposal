import 'package:flutter/material.dart';
import '../../../app/theme/street_cred_theme.dart';
import '../../../app/theme/street_cred_design_system.dart';
import '../../../app/widgets/street_cred_card.dart';
import '../models/clan_models.dart';

class ClanCard extends StatelessWidget {
  final Clan clan;
  final bool isCompact;
  final bool isListView;
  final VoidCallback? onTap;

  const ClanCard({
    Key? key,
    required this.clan,
    this.isCompact = false,
    this.isListView = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isListView) {
      return _buildListViewCard();
    } else if (isCompact) {
      return _buildCompactCard();
    } else {
      return _buildGridCard();
    }
  }

  Widget _buildGridCard() {
    return GestureDetector(
      onTap: onTap,
      child: StreetCredCard(
        themeColor: clan.primaryColor,
        size: CardSize.small,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with clan type badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTypeBadge(),
                _buildMemberCounter(),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Clan icon
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [clan.primaryColor, clan.secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    clan.name.substring(0, 2).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Clan name
            Text(
              clan.name,
              style: StreetCredDesignSystem.subtitleStyle(Colors.white).copyWith(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 4),
            
            // Ranking
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events,
                  color: clan.primaryColor,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'Rank #${clan.stats.ranking}',
                  style: StreetCredDesignSystem.captionStyle().copyWith(
                    color: clan.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            // Stats
            _buildStatsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: clan.primaryColor.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Clan icon
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
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          clan.name,
                          style: StreetCredDesignSystem.subtitleStyle(Colors.white).copyWith(
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildTypeIcon(),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    '${clan.memberCount}/${clan.maxMembers} members • Rank #${clan.stats.ranking}',
                    style: StreetCredDesignSystem.captionStyle().copyWith(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Mini stats
                  Row(
                    children: [
                      _buildMiniStat(Icons.trending_up, '${(clan.averageWinRate * 100).toInt()}%'),
                      const SizedBox(width: 16),
                      _buildMiniStat(Icons.people, '${clan.onlineMembers}'),
                      const SizedBox(width: 16),
                      _buildMiniStat(Icons.map, '${clan.totalTerritories}'),
                    ],
                  ),
                ],
              ),
            ),
            
            // Arrow
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

  Widget _buildListViewCard() {
    return GestureDetector(
      onTap: onTap,
      child: StreetCredCard(
        themeColor: clan.primaryColor,
        size: CardSize.small,
        child: Row(
          children: [
            // Clan icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [clan.primaryColor, clan.secondaryColor],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  clan.name.substring(0, 2).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          clan.name,
                          style: StreetCredDesignSystem.subtitleStyle(Colors.white).copyWith(
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildTypeIcon(),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    clan.description,
                    style: StreetCredDesignSystem.captionStyle().copyWith(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Stats row
                  Row(
                    children: [
                      _buildStatItem(Icons.people, '${clan.memberCount}/${clan.maxMembers}'),
                      const SizedBox(width: 12),
                      _buildStatItem(Icons.emoji_events, '#${clan.stats.ranking}'),
                      const SizedBox(width: 12),
                      _buildStatItem(Icons.trending_up, '${(clan.averageWinRate * 100).toInt()}%'),
                      const Spacer(),
                      if (clan.onlineMembers > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: StreetCredTheme.neonGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${clan.onlineMembers} online',
                            style: StreetCredDesignSystem.captionStyle().copyWith(
                              color: StreetCredTheme.neonGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Arrow
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

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: clan.primaryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: clan.primaryColor.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        clan.typeDisplayName.toUpperCase(),
        style: StreetCredDesignSystem.captionStyle().copyWith(
          color: clan.primaryColor,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    IconData icon;
    switch (clan.type) {
      case ClanType.casual:
        icon = Icons.sports_esports;
        break;
      case ClanType.competitive:
        icon = Icons.military_tech;
        break;
      case ClanType.elite:
        icon = Icons.workspace_premium;
        break;
      case ClanType.exclusive:
        icon = Icons.diamond;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: clan.primaryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        icon,
        color: clan.primaryColor,
        size: 16,
      ),
    );
  }

  Widget _buildMemberCounter() {
    return Row(
      children: [
        Icon(
          Icons.people,
          color: Colors.white70,
          size: 12,
        ),
        const SizedBox(width: 4),
        Text(
          '${clan.memberCount}/${clan.maxMembers}',
          style: StreetCredDesignSystem.captionStyle().copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatColumn(Icons.trending_up, '${(clan.averageWinRate * 100).toInt()}%'),
        _buildStatColumn(Icons.map, '${clan.totalTerritories}'),
        _buildStatColumn(Icons.people, '${clan.onlineMembers}'),
      ],
    );
  }

  Widget _buildStatColumn(IconData icon, String value) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 12,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: StreetCredDesignSystem.captionStyle().copyWith(
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 12,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: StreetCredDesignSystem.captionStyle().copyWith(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: clan.primaryColor,
          size: 12,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: StreetCredDesignSystem.captionStyle().copyWith(
            color: clan.primaryColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}