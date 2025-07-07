import 'package:flutter/foundation.dart';
import '../models/clan_models.dart';

class ClanService {
  static const String _storageKey = 'clan_data';
  
  // Mock data for demo purposes
  final Map<String, Clan> _clans = {};
  final Map<String, List<ClanChallenge>> _challenges = {};
  final Map<String, List<ClanInvitation>> _invitations = {};
  final Map<String, List<ClanActivity>> _activities = {};

  ClanService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Create sample Hong Kong themed clans
    final hongKongLegends = ClanFactory.createSampleClan('Hong Kong Legends', ClanType.exclusive);
    final neonSamurai = ClanFactory.createSampleClan('Neon Samurai', ClanType.elite);
    final streetWarriors = ClanFactory.createSampleClan('Street Warriors', ClanType.competitive);
    final dragonTraders = ClanFactory.createSampleClan('Dragon Traders', ClanType.competitive);
    final rookieStreet = ClanFactory.createSampleClan('Rookie Street', ClanType.casual);
    final centralCrew = ClanFactory.createSampleClan('Central Crew', ClanType.casual);

    // Add sample members
    final sampleMembers = _createSampleMembers();
    
    _clans[hongKongLegends.id] = hongKongLegends.copyWith(members: sampleMembers.take(8).toList());
    _clans[neonSamurai.id] = neonSamurai.copyWith(members: sampleMembers.skip(8).take(15).toList());
    _clans[streetWarriors.id] = streetWarriors.copyWith(members: sampleMembers.skip(23).take(20).toList());
    _clans[dragonTraders.id] = dragonTraders.copyWith(members: sampleMembers.skip(43).take(18).toList());
    _clans[rookieStreet.id] = rookieStreet.copyWith(members: sampleMembers.skip(61).take(25).toList());
    _clans[centralCrew.id] = centralCrew.copyWith(members: sampleMembers.skip(86).take(22).toList());

    // Create sample challenges
    _initializeSampleChallenges();
  }

  List<ClanMember> _createSampleMembers() {
    final members = <ClanMember>[];
    final usernames = [
      'NeonNinja', 'DragonKing', 'StreetArt', 'HongKongBull', 'CyberSamurai',
      'RainTrader', 'NightWolf', 'LightningFast', 'GoldenDragon', 'ShadowMaster',
      'TowerTop', 'ElectricBlue', 'CrimsonEdge', 'SilverFox', 'DiamondHands',
      'BullMarket', 'BearSlayer', 'MarketMaker', 'TrendFollower', 'ScalpMaster',
      'SwingKing', 'DayTrader', 'HodlLord', 'PumpChaser', 'DipBuyer',
      'ChartMaster', 'TechAnalyst', 'FundaTrader', 'RiskTaker', 'SafePlayer',
      'MoonShot', 'ToTheMars', 'RocketMan', 'SatoshiFan', 'BlockChainer',
      'CryptoKing', 'DeFiLord', 'NFTCollector', 'TokenMaster', 'CoindDaddy',
      'WhaleHunter', 'SharkAttack', 'FishSwim', 'OctopusArms', 'SquidGame',
      'PandaExpress', 'TigerClaws', 'LionHeart', 'EagleEye', 'HawkVision',
      'WolfPack', 'BearClaw', 'BullRun', 'RabbitSpeed', 'TurtlePace',
      'CheetahFast', 'ElephantStrong', 'AntWork', 'BeeHive', 'SpiderWeb',
      'ButterFly', 'DragonFly', 'FireFly', 'LightBug', 'GlowWorm',
      'StarLight', 'MoonBeam', 'SunRay', 'CloudNine', 'RainDrop',
      'SnowFlake', 'IceCube', 'FireBall', 'ThunderBolt', 'LightningStrike',
      'EarthQuake', 'TidalWave', 'WindStorm', 'SandStorm', 'BlizzardForce',
      'VolcanicEruption', 'MeteorShower', 'CometTail', 'BlackHole', 'WhiteDwarf',
      'NeutronStar', 'Supernova', 'BigBang', 'DarkMatter', 'AntiMatter',
      'QuantumLeap', 'TimeWarp', 'SpaceTime', 'WormHole', 'Teleport',
      'PhaseShift', 'Dimension', 'Multiverse', 'Infinity', 'Beyond',
      'Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon',
      'Zeta', 'Eta', 'Theta', 'Iota', 'Kappa',
      'Lambda', 'Mu', 'Nu', 'Xi', 'Omicron',
      'Pi', 'Rho', 'Sigma', 'Tau', 'Upsilon',
      'Phi', 'Chi', 'Psi', 'Omega', 'Final'
    ];

    for (int i = 0; i < usernames.length; i++) {
      final role = i == 0 ? ClanRole.leader : 
                   i < 3 ? ClanRole.officer : 
                   ClanRole.member;
      
      members.add(ClanMember(
        id: 'member_$i',
        username: usernames[i],
        walletAddress: '0x${i.toRadixString(16).padLeft(40, '0')}',
        role: role,
        joinDate: DateTime.now().subtract(Duration(days: 30 - i)),
        contributionPoints: 500 + (i * 50),
        totalTrades: 50 + (i * 10),
        winRate: 0.4 + (i * 0.01),
        territoriesControlled: i % 5,
        nftCount: i % 8,
        lastActive: DateTime.now().subtract(Duration(hours: i % 24)),
        isOnline: i % 3 == 0,
      ));
    }

    return members;
  }

  void _initializeSampleChallenges() {
    final clans = _clans.values.toList();
    if (clans.length < 2) return;

    final challenge1 = ClanChallenge(
      id: 'challenge_1',
      name: 'Central District Domination',
      description: 'Control the most territories in Central for 48 hours',
      type: ChallengeType.territoryControl,
      challengingClan: clans[0],
      defendingClan: clans[1],
      startTime: DateTime.now().add(const Duration(hours: 1)),
      endTime: DateTime.now().add(const Duration(hours: 49)),
      duration: const Duration(hours: 48),
      rules: {
        'minTerritories': 5,
        'district': 'central',
        'timeLimit': 48,
      },
      rewards: {
        'winnerPoints': 1000,
        'winnerNFT': 'legendary_central_badge',
        'participationPoints': 200,
      },
      status: ChallengeStatus.active,
      progress: {
        clans[0].id: {'territories': 3, 'lastUpdate': DateTime.now()},
        clans[1].id: {'territories': 2, 'lastUpdate': DateTime.now()},
      },
      winnerId: null,
    );

    final challenge2 = ClanChallenge(
      id: 'challenge_2',
      name: 'Trading Volume Showdown',
      description: 'Highest collective trading volume wins',
      type: ChallengeType.tradingVolume,
      challengingClan: clans[2],
      defendingClan: clans[3],
      startTime: DateTime.now().subtract(const Duration(hours: 12)),
      endTime: DateTime.now().add(const Duration(hours: 12)),
      duration: const Duration(hours: 24),
      rules: {
        'minVolume': 100000,
        'timeLimit': 24,
      },
      rewards: {
        'winnerPoints': 800,
        'winnerNFT': 'rare_volume_badge',
        'participationPoints': 150,
      },
      status: ChallengeStatus.active,
      progress: {
        clans[2].id: {'volume': 75000, 'lastUpdate': DateTime.now()},
        clans[3].id: {'volume': 82000, 'lastUpdate': DateTime.now()},
      },
      winnerId: null,
    );

    _challenges['active'] = [challenge1, challenge2];
  }

  // Public API methods
  Future<List<Clan>> getAvailableClans({ClanType? filterType}) async {
    final clans = _clans.values.toList();
    if (filterType != null) {
      return clans.where((clan) => clan.type == filterType).toList();
    }
    return clans;
  }

  Future<Clan?> getClanById(String clanId) async {
    return _clans[clanId];
  }

  Future<List<Clan>> searchClans(String query) async {
    final lowercaseQuery = query.toLowerCase();
    return _clans.values.where((clan) =>
        clan.name.toLowerCase().contains(lowercaseQuery) ||
        clan.description.toLowerCase().contains(lowercaseQuery) ||
        clan.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery))
    ).toList();
  }

  Future<bool> joinClan(String clanId, ClanMember user) async {
    final clan = _clans[clanId];
    if (clan == null) return false;
    
    if (!clan.canUserJoin(user)) return false;

    final updatedMembers = [...clan.members, user.copyWith(role: ClanRole.member)];
    _clans[clanId] = Clan(
      id: clan.id,
      name: clan.name,
      description: clan.description,
      bannerImageUrl: clan.bannerImageUrl,
      primaryColor: clan.primaryColor,
      secondaryColor: clan.secondaryColor,
      type: clan.type,
      members: updatedMembers,
      createdDate: clan.createdDate,
      maxMembers: clan.maxMembers,
      requirements: clan.requirements,
      tags: clan.tags,
      stats: clan.stats,
      isRecruiting: clan.isRecruiting,
    );

    // Add activity
    _addActivity(clanId, ClanActivity(
      id: 'activity_${DateTime.now().millisecondsSinceEpoch}',
      clanId: clanId,
      type: 'member_joined',
      description: '${user.username} joined the clan',
      userId: user.id,
      username: user.username,
      timestamp: DateTime.now(),
      metadata: {},
    ));

    return true;
  }

  Future<bool> leaveClan(String clanId, String userId) async {
    final clan = _clans[clanId];
    if (clan == null) return false;

    final member = clan.members.where((m) => m.id == userId).firstOrNull;
    if (member == null) return false;

    final updatedMembers = clan.members.where((m) => m.id != userId).toList();
    _clans[clanId] = Clan(
      id: clan.id,
      name: clan.name,
      description: clan.description,
      bannerImageUrl: clan.bannerImageUrl,
      primaryColor: clan.primaryColor,
      secondaryColor: clan.secondaryColor,
      type: clan.type,
      members: updatedMembers,
      createdDate: clan.createdDate,
      maxMembers: clan.maxMembers,
      requirements: clan.requirements,
      tags: clan.tags,
      stats: clan.stats,
      isRecruiting: clan.isRecruiting,
    );

    // Add activity
    _addActivity(clanId, ClanActivity(
      id: 'activity_${DateTime.now().millisecondsSinceEpoch}',
      clanId: clanId,
      type: 'member_left',
      description: '${member.username} left the clan',
      userId: member.id,
      username: member.username,
      timestamp: DateTime.now(),
      metadata: {},
    ));

    return true;
  }

  Future<bool> promoteMember(String clanId, String userId, ClanRole newRole) async {
    final clan = _clans[clanId];
    if (clan == null) return false;

    final memberIndex = clan.members.indexWhere((m) => m.id == userId);
    if (memberIndex == -1) return false;

    final member = clan.members[memberIndex];
    final updatedMember = member.copyWith(role: newRole);
    final updatedMembers = [...clan.members];
    updatedMembers[memberIndex] = updatedMember;

    _clans[clanId] = Clan(
      id: clan.id,
      name: clan.name,
      description: clan.description,
      bannerImageUrl: clan.bannerImageUrl,
      primaryColor: clan.primaryColor,
      secondaryColor: clan.secondaryColor,
      type: clan.type,
      members: updatedMembers,
      createdDate: clan.createdDate,
      maxMembers: clan.maxMembers,
      requirements: clan.requirements,
      tags: clan.tags,
      stats: clan.stats,
      isRecruiting: clan.isRecruiting,
    );

    // Add activity
    _addActivity(clanId, ClanActivity(
      id: 'activity_${DateTime.now().millisecondsSinceEpoch}',
      clanId: clanId,
      type: 'member_promoted',
      description: '${member.username} promoted to ${newRole.name}',
      userId: member.id,
      username: member.username,
      timestamp: DateTime.now(),
      metadata: {'newRole': newRole.name},
    ));

    return true;
  }

  Future<List<ClanChallenge>> getActiveChallenges() async {
    return _challenges['active'] ?? [];
  }

  Future<List<ClanChallenge>> getClanChallenges(String clanId) async {
    final allChallenges = <ClanChallenge>[];
    _challenges.values.forEach((challengeList) {
      allChallenges.addAll(challengeList.where((c) => 
          c.challengingClan.id == clanId || 
          c.defendingClan?.id == clanId));
    });
    return allChallenges;
  }

  Future<bool> createChallenge(ClanChallenge challenge) async {
    if (!_challenges.containsKey('active')) {
      _challenges['active'] = [];
    }
    
    _challenges['active']!.add(challenge);

    // Add activity for both clans
    _addActivity(challenge.challengingClan.id, ClanActivity(
      id: 'activity_${DateTime.now().millisecondsSinceEpoch}',
      clanId: challenge.challengingClan.id,
      type: 'challenge_created',
      description: 'Created challenge: ${challenge.name}',
      userId: 'system',
      username: 'System',
      timestamp: DateTime.now(),
      metadata: {'challengeId': challenge.id, 'challengeType': challenge.type.name},
    ));

    if (challenge.defendingClan != null) {
      _addActivity(challenge.defendingClan!.id, ClanActivity(
        id: 'activity_${DateTime.now().millisecondsSinceEpoch + 1}',
        clanId: challenge.defendingClan!.id,
        type: 'challenge_received',
        description: 'Received challenge: ${challenge.name}',
        userId: 'system',
        username: 'System',
        timestamp: DateTime.now(),
        metadata: {'challengeId': challenge.id, 'fromClan': challenge.challengingClan.name},
      ));
    }

    return true;
  }

  Future<bool> acceptChallenge(String challengeId, String clanId) async {
    // Implementation would update challenge status
    debugPrint('Challenge $challengeId accepted by clan $clanId');
    return true;
  }

  Future<bool> declineChallenge(String challengeId, String clanId) async {
    // Implementation would update challenge status
    debugPrint('Challenge $challengeId declined by clan $clanId');
    return true;
  }

  Future<List<ClanInvitation>> getUserInvitations(String userId) async {
    return _invitations[userId] ?? [];
  }

  Future<bool> sendInvitation(ClanInvitation invitation) async {
    if (!_invitations.containsKey(invitation.invitedUserId)) {
      _invitations[invitation.invitedUserId] = [];
    }
    
    _invitations[invitation.invitedUserId]!.add(invitation);

    // Add activity
    _addActivity(invitation.clanId, ClanActivity(
      id: 'activity_${DateTime.now().millisecondsSinceEpoch}',
      clanId: invitation.clanId,
      type: 'invitation_sent',
      description: 'Invited ${invitation.invitedUsername} to join',
      userId: invitation.invitingUserId,
      username: invitation.invitingUsername,
      timestamp: DateTime.now(),
      metadata: {'invitedUser': invitation.invitedUsername},
    ));

    return true;
  }

  Future<bool> acceptInvitation(String invitationId, String userId) async {
    // Find and process invitation
    for (final userInvitations in _invitations.values) {
      final invitation = userInvitations.where((inv) => inv.id == invitationId).firstOrNull;
      if (invitation != null) {
        // Remove invitation and join clan
        userInvitations.remove(invitation);
        return true;
      }
    }
    return false;
  }

  Future<ClanLeaderboard> getClanLeaderboard() async {
    final entries = <ClanLeaderboardEntry>[];
    final clanList = _clans.values.toList();
    
    // Sort by points (mock calculation)
    clanList.sort((a, b) => b.stats.weeklyPoints.compareTo(a.stats.weeklyPoints));
    
    for (int i = 0; i < clanList.length; i++) {
      entries.add(ClanLeaderboardEntry(
        rank: i + 1,
        clan: clanList[i],
        points: clanList[i].stats.weeklyPoints,
        change: i % 3 == 0 ? 2 : (i % 3 == 1 ? -1 : 0),
        metrics: {
          'avgWinRate': clanList[i].averageWinRate,
          'totalTrades': clanList[i].stats.totalTrades,
          'territories': clanList[i].totalTerritories,
        },
      ));
    }

    return ClanLeaderboard(
      entries: entries,
      lastUpdated: DateTime.now(),
      season: 'Hong Kong Street Season 1',
    );
  }

  Future<List<ClanActivity>> getClanActivities(String clanId, {int limit = 20}) async {
    final activities = _activities[clanId] ?? [];
    return activities.take(limit).toList();
  }

  Future<Map<String, dynamic>> getClanAnalytics(String clanId) async {
    final clan = _clans[clanId];
    if (clan == null) return {};

    return {
      'memberGrowth': _calculateMemberGrowth(clan),
      'activityTrend': _calculateActivityTrend(clanId),
      'performanceMetrics': _calculatePerformanceMetrics(clan),
      'challengeHistory': _getChallengeHistory(clanId),
      'topPerformers': _getTopPerformers(clan),
    };
  }

  // Private helper methods
  void _addActivity(String clanId, ClanActivity activity) {
    if (!_activities.containsKey(clanId)) {
      _activities[clanId] = [];
    }
    
    _activities[clanId]!.insert(0, activity); // Insert at beginning for chronological order
    
    // Keep only last 100 activities
    if (_activities[clanId]!.length > 100) {
      _activities[clanId] = _activities[clanId]!.take(100).toList();
    }
  }

  Map<String, dynamic> _calculateMemberGrowth(Clan clan) {
    // Mock calculation for member growth
    return {
      'currentMembers': clan.memberCount,
      'weeklyGrowth': 3,
      'monthlyGrowth': 12,
      'growthRate': 0.15,
    };
  }

  Map<String, dynamic> _calculateActivityTrend(String clanId) {
    final activities = _activities[clanId] ?? [];
    return {
      'dailyActivities': activities.where((a) => 
          DateTime.now().difference(a.timestamp).inDays == 0).length,
      'weeklyActivities': activities.where((a) => 
          DateTime.now().difference(a.timestamp).inDays <= 7).length,
      'trendDirection': 'up',
    };
  }

  Map<String, dynamic> _calculatePerformanceMetrics(Clan clan) {
    return {
      'averageWinRate': clan.averageWinRate,
      'totalVolume': clan.stats.totalVolume,
      'rankingChange': 2,
      'challengeWinRate': clan.stats.challengeWinRate,
    };
  }

  List<Map<String, dynamic>> _getChallengeHistory(String clanId) {
    // Mock challenge history
    return [
      {'name': 'Volume Challenge', 'result': 'won', 'date': DateTime.now().subtract(const Duration(days: 5))},
      {'name': 'Territory Battle', 'result': 'lost', 'date': DateTime.now().subtract(const Duration(days: 12))},
      {'name': 'Art Collection', 'result': 'won', 'date': DateTime.now().subtract(const Duration(days: 18))},
    ];
  }

  List<Map<String, dynamic>> _getTopPerformers(Clan clan) {
    final sortedMembers = [...clan.members];
    sortedMembers.sort((a, b) => b.contributionPoints.compareTo(a.contributionPoints));
    
    return sortedMembers.take(5).map((member) => {
      'username': member.username,
      'contributionPoints': member.contributionPoints,
      'winRate': member.winRate,
      'territories': member.territoriesControlled,
    }).toList();
  }
}

// Extension for easier Clan copying
extension ClanCopyWith on Clan {
  Clan copyWith({
    String? name,
    String? description,
    List<ClanMember>? members,
    bool? isRecruiting,
    ClanStats? stats,
  }) {
    return Clan(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      bannerImageUrl: bannerImageUrl,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      type: type,
      members: members ?? this.members,
      createdDate: createdDate,
      maxMembers: maxMembers,
      requirements: requirements,
      tags: tags,
      stats: stats ?? this.stats,
      isRecruiting: isRecruiting ?? this.isRecruiting,
    );
  }
}