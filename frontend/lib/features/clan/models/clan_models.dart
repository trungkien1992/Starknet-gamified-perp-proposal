import 'package:flutter/material.dart';

enum ClanRole {
  member,
  officer,
  leader,
}

enum ClanType {
  casual,    // Open to all, low requirements
  competitive, // Moderate requirements, focused on performance
  elite,     // High requirements, top performers only
  exclusive, // Invite-only, legendary status
}

enum ChallengeType {
  tradingVolume,     // Total trading volume over period
  winRate,          // Percentage of profitable trades
  territoryControl, // Number of territories controlled
  artCollection,    // Number of rare NFTs collected
  streakMaintained, // Longest winning streak
  profitPercentage, // Highest profit percentage
}

enum ChallengeStatus {
  active,
  completed,
  expired,
  cancelled,
}

class ClanMember {
  final String id;
  final String username;
  final String walletAddress;
  final ClanRole role;
  final DateTime joinDate;
  final int contributionPoints;
  final int totalTrades;
  final double winRate;
  final int territoriesControlled;
  final int nftCount;
  final DateTime lastActive;
  final bool isOnline;

  ClanMember({
    required this.id,
    required this.username,
    required this.walletAddress,
    required this.role,
    required this.joinDate,
    required this.contributionPoints,
    required this.totalTrades,
    required this.winRate,
    required this.territoriesControlled,
    required this.nftCount,
    required this.lastActive,
    required this.isOnline,
  });

  bool get canInviteMembers => role == ClanRole.leader || role == ClanRole.officer;
  bool get canStartChallenges => role == ClanRole.leader || role == ClanRole.officer;
  bool get canManageClan => role == ClanRole.leader;

  String get roleDisplayName {
    switch (role) {
      case ClanRole.member:
        return 'Member';
      case ClanRole.officer:
        return 'Officer';
      case ClanRole.leader:
        return 'Leader';
    }
  }

  Color get roleColor {
    switch (role) {
      case ClanRole.member:
        return const Color(0xFF888888);
      case ClanRole.officer:
        return const Color(0xFF00FFFF);
      case ClanRole.leader:
        return const Color(0xFFFFD700);
    }
  }

  ClanMember copyWith({
    ClanRole? role,
    int? contributionPoints,
    int? totalTrades,
    double? winRate,
    int? territoriesControlled,
    int? nftCount,
    DateTime? lastActive,
    bool? isOnline,
  }) {
    return ClanMember(
      id: id,
      username: username,
      walletAddress: walletAddress,
      role: role ?? this.role,
      joinDate: joinDate,
      contributionPoints: contributionPoints ?? this.contributionPoints,
      totalTrades: totalTrades ?? this.totalTrades,
      winRate: winRate ?? this.winRate,
      territoriesControlled: territoriesControlled ?? this.territoriesControlled,
      nftCount: nftCount ?? this.nftCount,
      lastActive: lastActive ?? this.lastActive,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class Clan {
  final String id;
  final String name;
  final String description;
  final String bannerImageUrl;
  final Color primaryColor;
  final Color secondaryColor;
  final ClanType type;
  final List<ClanMember> members;
  final DateTime createdDate;
  final int maxMembers;
  final Map<String, dynamic> requirements;
  final List<String> tags;
  final ClanStats stats;
  final bool isRecruiting;

  Clan({
    required this.id,
    required this.name,
    required this.description,
    required this.bannerImageUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.type,
    required this.members,
    required this.createdDate,
    required this.maxMembers,
    required this.requirements,
    required this.tags,
    required this.stats,
    required this.isRecruiting,
  });

  ClanMember? get leader => members.where((m) => m.role == ClanRole.leader).firstOrNull;
  List<ClanMember> get officers => members.where((m) => m.role == ClanRole.officer).toList();
  List<ClanMember> get regularMembers => members.where((m) => m.role == ClanRole.member).toList();
  
  int get memberCount => members.length;
  bool get isFull => memberCount >= maxMembers;
  int get onlineMembers => members.where((m) => m.isOnline).length;
  
  double get averageWinRate => members.isEmpty ? 0.0 : 
      members.map((m) => m.winRate).reduce((a, b) => a + b) / members.length;
  
  int get totalTerritories => members.map((m) => m.territoriesControlled).fold(0, (a, b) => a + b);
  int get totalNfts => members.map((m) => m.nftCount).fold(0, (a, b) => a + b);

  String get typeDisplayName {
    switch (type) {
      case ClanType.casual:
        return 'Casual';
      case ClanType.competitive:
        return 'Competitive';
      case ClanType.elite:
        return 'Elite';
      case ClanType.exclusive:
        return 'Exclusive';
    }
  }

  bool canUserJoin(ClanMember user) {
    if (isFull) return false;
    if (!isRecruiting) return false;
    
    switch (type) {
      case ClanType.casual:
        return true;
      case ClanType.competitive:
        return user.totalTrades >= (requirements['minTrades'] ?? 50) &&
               user.winRate >= (requirements['minWinRate'] ?? 0.4);
      case ClanType.elite:
        return user.totalTrades >= (requirements['minTrades'] ?? 200) &&
               user.winRate >= (requirements['minWinRate'] ?? 0.6) &&
               user.territoriesControlled >= (requirements['minTerritories'] ?? 3);
      case ClanType.exclusive:
        return false; // Invite only
    }
  }
}

class ClanStats {
  final int totalTrades;
  final double totalVolume;
  final double averageWinRate;
  final int territoriesControlled;
  final int totalNfts;
  final int challengesWon;
  final int challengesLost;
  final int ranking;
  final int weeklyPoints;
  final Map<String, dynamic> achievements;

  ClanStats({
    required this.totalTrades,
    required this.totalVolume,
    required this.averageWinRate,
    required this.territoriesControlled,
    required this.totalNfts,
    required this.challengesWon,
    required this.challengesLost,
    required this.ranking,
    required this.weeklyPoints,
    required this.achievements,
  });

  double get challengeWinRate => 
      (challengesWon + challengesLost) == 0 ? 0.0 : challengesWon / (challengesWon + challengesLost);
}

class ClanChallenge {
  final String id;
  final String name;
  final String description;
  final ChallengeType type;
  final Clan challengingClan;
  final Clan? defendingClan;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final Map<String, dynamic> rules;
  final Map<String, dynamic> rewards;
  final ChallengeStatus status;
  final Map<String, dynamic> progress;
  final String? winnerId;

  ClanChallenge({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.challengingClan,
    this.defendingClan,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.rules,
    required this.rewards,
    required this.status,
    required this.progress,
    this.winnerId,
  });

  bool get isActive => status == ChallengeStatus.active && 
                      DateTime.now().isAfter(startTime) && 
                      DateTime.now().isBefore(endTime);
  
  bool get isCompleted => status == ChallengeStatus.completed;
  bool get hasWinner => winnerId != null;
  
  Duration get timeRemaining => isActive ? endTime.difference(DateTime.now()) : Duration.zero;
  double get progressPercentage => isActive ? 
      DateTime.now().difference(startTime).inSeconds / duration.inSeconds : 
      (isCompleted ? 1.0 : 0.0);

  String get typeDisplayName {
    switch (type) {
      case ChallengeType.tradingVolume:
        return 'Trading Volume';
      case ChallengeType.winRate:
        return 'Win Rate Challenge';
      case ChallengeType.territoryControl:
        return 'Territory Control';
      case ChallengeType.artCollection:
        return 'Art Collection';
      case ChallengeType.streakMaintained:
        return 'Streak Maintained';
      case ChallengeType.profitPercentage:
        return 'Profit Percentage';
    }
  }

  String get typeEmoji {
    switch (type) {
      case ChallengeType.tradingVolume:
        return '📈';
      case ChallengeType.winRate:
        return '🎯';
      case ChallengeType.territoryControl:
        return '🗺️';
      case ChallengeType.artCollection:
        return '🎨';
      case ChallengeType.streakMaintained:
        return '🔥';
      case ChallengeType.profitPercentage:
        return '💰';
    }
  }
}

class ClanInvitation {
  final String id;
  final String clanId;
  final String clanName;
  final String invitedUserId;
  final String invitedUsername;
  final String invitingUserId;
  final String invitingUsername;
  final DateTime sentDate;
  final DateTime? expiryDate;
  final String? message;
  final bool isAccepted;
  final bool isExpired;

  ClanInvitation({
    required this.id,
    required this.clanId,
    required this.clanName,
    required this.invitedUserId,
    required this.invitedUsername,
    required this.invitingUserId,
    required this.invitingUsername,
    required this.sentDate,
    this.expiryDate,
    this.message,
    required this.isAccepted,
    required this.isExpired,
  });

  bool get isValid => !isExpired && !isAccepted && 
                     (expiryDate == null || DateTime.now().isBefore(expiryDate!));
}

class ClanLeaderboard {
  final List<ClanLeaderboardEntry> entries;
  final DateTime lastUpdated;
  final String season;

  ClanLeaderboard({
    required this.entries,
    required this.lastUpdated,
    required this.season,
  });
}

class ClanLeaderboardEntry {
  final int rank;
  final Clan clan;
  final int points;
  final int change; // Position change from last week
  final Map<String, dynamic> metrics;

  ClanLeaderboardEntry({
    required this.rank,
    required this.clan,
    required this.points,
    required this.change,
    required this.metrics,
  });

  bool get isRising => change > 0;
  bool get isFalling => change < 0;
  String get changeDisplay => change > 0 ? '+$change' : change.toString();
}

class ClanActivity {
  final String id;
  final String clanId;
  final String type;
  final String description;
  final String userId;
  final String username;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  ClanActivity({
    required this.id,
    required this.clanId,
    required this.type,
    required this.description,
    required this.userId,
    required this.username,
    required this.timestamp,
    required this.metadata,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// Factory methods for creating sample data
class ClanFactory {
  static Clan createSampleClan(String name, ClanType type) {
    final color = _getClanColor(type);
    return Clan(
      id: 'clan_${name.toLowerCase().replaceAll(' ', '_')}',
      name: name,
      description: _getClanDescription(type),
      bannerImageUrl: 'assets/clan_banners/${name.toLowerCase()}.jpg',
      primaryColor: color,
      secondaryColor: color.withValues(alpha: 0.7),
      type: type,
      members: [],
      createdDate: DateTime.now().subtract(Duration(days: 30)),
      maxMembers: _getMaxMembers(type),
      requirements: _getClanRequirements(type),
      tags: _getClanTags(type),
      stats: ClanStats(
        totalTrades: 1250,
        totalVolume: 50000.0,
        averageWinRate: 0.65,
        territoriesControlled: 8,
        totalNfts: 45,
        challengesWon: 12,
        challengesLost: 3,
        ranking: 15,
        weeklyPoints: 2450,
        achievements: {},
      ),
      isRecruiting: true,
    );
  }

  static Color _getClanColor(ClanType type) {
    switch (type) {
      case ClanType.casual:
        return const Color(0xFF00FF41);
      case ClanType.competitive:
        return const Color(0xFF00FFFF);
      case ClanType.elite:
        return const Color(0xFFFF0080);
      case ClanType.exclusive:
        return const Color(0xFFFFD700);
    }
  }

  static String _getClanDescription(ClanType type) {
    switch (type) {
      case ClanType.casual:
        return 'Laid-back traders learning the Hong Kong streets together';
      case ClanType.competitive:
        return 'Serious traders pushing each other to new heights';
      case ClanType.elite:
        return 'Top-tier traders dominating the neon-lit markets';
      case ClanType.exclusive:
        return 'Legendary status required - invitation only';
    }
  }

  static int _getMaxMembers(ClanType type) {
    switch (type) {
      case ClanType.casual:
        return 50;
      case ClanType.competitive:
        return 30;
      case ClanType.elite:
        return 20;
      case ClanType.exclusive:
        return 10;
    }
  }

  static Map<String, dynamic> _getClanRequirements(ClanType type) {
    switch (type) {
      case ClanType.casual:
        return {};
      case ClanType.competitive:
        return {'minTrades': 50, 'minWinRate': 0.4};
      case ClanType.elite:
        return {'minTrades': 200, 'minWinRate': 0.6, 'minTerritories': 3};
      case ClanType.exclusive:
        return {'inviteOnly': true};
    }
  }

  static List<String> _getClanTags(ClanType type) {
    switch (type) {
      case ClanType.casual:
        return ['Beginner-Friendly', 'Learning', 'Social'];
      case ClanType.competitive:
        return ['Active', 'Performance', 'Growth'];
      case ClanType.elite:
        return ['Expert', 'High-Stakes', 'Exclusive'];
      case ClanType.exclusive:
        return ['Legendary', 'Elite', 'Invitation-Only'];
    }
  }
}