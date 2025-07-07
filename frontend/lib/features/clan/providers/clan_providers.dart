import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/clan_models.dart';
import '../services/clan_service.dart';

// Service provider
final clanServiceProvider = Provider<ClanService>((ref) {
  return ClanService();
});

// Current user's clan membership
final userClanProvider = StateProvider<Clan?>((ref) => null);

// Current user data (mock)
final currentUserProvider = StateProvider<ClanMember?>((ref) {
  return ClanMember(
    id: 'current_user',
    username: 'StreetArtist',
    walletAddress: '0x1234567890abcdef1234567890abcdef12345678',
    role: ClanRole.member,
    joinDate: DateTime.now().subtract(const Duration(days: 15)),
    contributionPoints: 750,
    totalTrades: 125,
    winRate: 0.68,
    territoriesControlled: 3,
    nftCount: 12,
    lastActive: DateTime.now(),
    isOnline: true,
  );
});

// Available clans list
final availableClansProvider = FutureProvider.family<List<Clan>, ClanType?>((ref, filterType) async {
  final clanService = ref.read(clanServiceProvider);
  return await clanService.getAvailableClans(filterType: filterType);
});

// Clan search
class ClanSearchNotifier extends StateNotifier<AsyncValue<List<Clan>>> {
  final ClanService _clanService;

  ClanSearchNotifier(this._clanService) : super(const AsyncValue.data([]));

  Future<void> searchClans(String query) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final results = await _clanService.searchClans(query);
      state = AsyncValue.data(results);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearSearch() {
    state = const AsyncValue.data([]);
  }
}

final clanSearchProvider = StateNotifierProvider<ClanSearchNotifier, AsyncValue<List<Clan>>>((ref) {
  final clanService = ref.read(clanServiceProvider);
  return ClanSearchNotifier(clanService);
});

// Clan details
final clanDetailsProvider = FutureProvider.family<Clan?, String>((ref, clanId) async {
  final clanService = ref.read(clanServiceProvider);
  return await clanService.getClanById(clanId);
});

// Active challenges
final activeChallengesProvider = FutureProvider<List<ClanChallenge>>((ref) async {
  final clanService = ref.read(clanServiceProvider);
  return await clanService.getActiveChallenges();
});

// Clan specific challenges
final clanChallengesProvider = FutureProvider.family<List<ClanChallenge>, String>((ref, clanId) async {
  final clanService = ref.read(clanServiceProvider);
  return await clanService.getClanChallenges(clanId);
});

// User invitations
final userInvitationsProvider = FutureProvider.family<List<ClanInvitation>, String>((ref, userId) async {
  final clanService = ref.read(clanServiceProvider);
  return await clanService.getUserInvitations(userId);
});

// Clan leaderboard
final clanLeaderboardProvider = FutureProvider<ClanLeaderboard>((ref) async {
  final clanService = ref.read(clanServiceProvider);
  return await clanService.getClanLeaderboard();
});

// Clan activities
final clanActivitiesProvider = FutureProvider.family<List<ClanActivity>, String>((ref, clanId) async {
  final clanService = ref.read(clanServiceProvider);
  return await clanService.getClanActivities(clanId);
});

// Clan analytics
final clanAnalyticsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, clanId) async {
  final clanService = ref.read(clanServiceProvider);
  return await clanService.getClanAnalytics(clanId);
});

// Clan management state
class ClanManagementNotifier extends StateNotifier<AsyncValue<bool>> {
  final ClanService _clanService;
  final StateNotifierProviderRef _ref;

  ClanManagementNotifier(this._clanService, this._ref) : super(const AsyncValue.data(false));

  Future<void> joinClan(String clanId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      final success = await _clanService.joinClan(clanId, user);
      if (success) {
        // Update user's clan
        final clan = await _clanService.getClanById(clanId);
        _ref.read(userClanProvider.notifier).state = clan;
        
        // Refresh available clans
        _ref.invalidate(availableClansProvider);
      }
      state = AsyncValue.data(success);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> leaveClan(String clanId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      final success = await _clanService.leaveClan(clanId, user.id);
      if (success) {
        _ref.read(userClanProvider.notifier).state = null;
        _ref.invalidate(availableClansProvider);
      }
      state = AsyncValue.data(success);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> promoteMember(String clanId, String userId, ClanRole newRole) async {
    state = const AsyncValue.loading();
    try {
      final success = await _clanService.promoteMember(clanId, userId, newRole);
      if (success) {
        _ref.invalidate(clanDetailsProvider(clanId));
        _ref.invalidate(clanActivitiesProvider(clanId));
      }
      state = AsyncValue.data(success);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> sendInvitation(ClanInvitation invitation) async {
    state = const AsyncValue.loading();
    try {
      final success = await _clanService.sendInvitation(invitation);
      if (success) {
        _ref.invalidate(clanActivitiesProvider(invitation.clanId));
      }
      state = AsyncValue.data(success);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> acceptInvitation(String invitationId, String userId) async {
    state = const AsyncValue.loading();
    try {
      final success = await _clanService.acceptInvitation(invitationId, userId);
      if (success) {
        _ref.invalidate(userInvitationsProvider(userId));
        _ref.invalidate(availableClansProvider);
      }
      state = AsyncValue.data(success);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final clanManagementProvider = StateNotifierProvider<ClanManagementNotifier, AsyncValue<bool>>((ref) {
  final clanService = ref.read(clanServiceProvider);
  return ClanManagementNotifier(clanService, ref);
});

// Challenge management state
class ChallengeManagementNotifier extends StateNotifier<AsyncValue<bool>> {
  final ClanService _clanService;
  final StateNotifierProviderRef _ref;

  ChallengeManagementNotifier(this._clanService, this._ref) : super(const AsyncValue.data(false));

  Future<void> createChallenge(ClanChallenge challenge) async {
    state = const AsyncValue.loading();
    try {
      final success = await _clanService.createChallenge(challenge);
      if (success) {
        _ref.invalidate(activeChallengesProvider);
        _ref.invalidate(clanChallengesProvider(challenge.challengingClan.id));
        if (challenge.defendingClan != null) {
          _ref.invalidate(clanChallengesProvider(challenge.defendingClan!.id));
        }
      }
      state = AsyncValue.data(success);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> acceptChallenge(String challengeId, String clanId) async {
    state = const AsyncValue.loading();
    try {
      final success = await _clanService.acceptChallenge(challengeId, clanId);
      if (success) {
        _ref.invalidate(activeChallengesProvider);
        _ref.invalidate(clanChallengesProvider(clanId));
      }
      state = AsyncValue.data(success);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> declineChallenge(String challengeId, String clanId) async {
    state = const AsyncValue.loading();
    try {
      final success = await _clanService.declineChallenge(challengeId, clanId);
      if (success) {
        _ref.invalidate(activeChallengesProvider);
        _ref.invalidate(clanChallengesProvider(clanId));
      }
      state = AsyncValue.data(success);
    } catch (error, stackTrace) {
    state = AsyncValue.error(error, stackTrace);
    }
  }
}

final challengeManagementProvider = StateNotifierProvider<ChallengeManagementNotifier, AsyncValue<bool>>((ref) {
  final clanService = ref.read(clanServiceProvider);
  return ChallengeManagementNotifier(clanService, ref);
});

// Filter and sorting options
final clanFilterProvider = StateProvider<ClanType?>((ref) => null);

final clanSortProvider = StateProvider<String>((ref) => 'name'); // name, members, ranking, type

// UI state providers
final selectedClanProvider = StateProvider<Clan?>((ref) => null);

final showJoinedClansOnlyProvider = StateProvider<bool>((ref) => false);

final clanViewModeProvider = StateProvider<String>((ref) => 'grid'); // grid, list

// Computed providers
final filteredClansProvider = Provider<AsyncValue<List<Clan>>>((ref) {
  final filterType = ref.watch(clanFilterProvider);
  return ref.watch(availableClansProvider(filterType));
});

final sortedClansProvider = Provider<AsyncValue<List<Clan>>>((ref) {
  final clansAsync = ref.watch(filteredClansProvider);
  final sortBy = ref.watch(clanSortProvider);

  return clansAsync.when(
    data: (clans) {
      final sortedClans = [...clans];
      switch (sortBy) {
        case 'name':
          sortedClans.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'members':
          sortedClans.sort((a, b) => b.memberCount.compareTo(a.memberCount));
          break;
        case 'ranking':
          sortedClans.sort((a, b) => a.stats.ranking.compareTo(b.stats.ranking));
          break;
        case 'type':
          sortedClans.sort((a, b) => a.type.index.compareTo(b.type.index));
          break;
      }
      return AsyncValue.data(sortedClans);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Clan statistics providers
final userClanStatsProvider = Provider<Map<String, dynamic>?>((ref) {
  final userClan = ref.watch(userClanProvider);
  final currentUser = ref.watch(currentUserProvider);
  
  if (userClan == null || currentUser == null) return null;

  final userMember = userClan.members.where((m) => m.id == currentUser.id).firstOrNull;
  if (userMember == null) return null;

  return {
    'memberRank': userClan.members.indexed
        .toList()
        ..sort((a, b) => b.$2.contributionPoints.compareTo(a.$2.contributionPoints)),
    'contributionRank': userClan.members
        .where((m) => m.contributionPoints > userMember.contributionPoints)
        .length + 1,
    'clanRanking': userClan.stats.ranking,
    'memberSince': userMember.joinDate,
    'totalContribution': userMember.contributionPoints,
  };
});

final clanRecommendationsProvider = Provider<AsyncValue<List<Clan>>>((ref) {
  final user = ref.watch(currentUserProvider);
  final allClansAsync = ref.watch(availableClansProvider(null));

  if (user == null) return const AsyncValue.data([]);

  return allClansAsync.when(
    data: (clans) {
      // Filter clans user can join and rank by compatibility
      final recommendedClans = clans
          .where((clan) => clan.canUserJoin(user))
          .toList();

      // Sort by compatibility score (simplified)
      recommendedClans.sort((a, b) {
        final scoreA = _calculateCompatibilityScore(user, a);
        final scoreB = _calculateCompatibilityScore(user, b);
        return scoreB.compareTo(scoreA);
      });

      return AsyncValue.data(recommendedClans.take(5).toList());
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

double _calculateCompatibilityScore(ClanMember user, Clan clan) {
  double score = 0.0;

  // Win rate compatibility
  final winRateDiff = (user.winRate - clan.averageWinRate).abs();
  score += (1.0 - winRateDiff) * 30;

  // Activity level (based on trades)
  if (user.totalTrades >= 100) score += 20;
  else if (user.totalTrades >= 50) score += 10;

  // Territory engagement
  if (user.territoriesControlled > 0) score += 15;

  // NFT collection
  if (user.nftCount > 5) score += 10;

  // Clan size preference (not too full, not too empty)
  final fillRatio = clan.memberCount / clan.maxMembers;
  if (fillRatio > 0.3 && fillRatio < 0.8) score += 15;

  // Type compatibility
  switch (clan.type) {
    case ClanType.casual:
      if (user.totalTrades < 100) score += 10;
      break;
    case ClanType.competitive:
      if (user.winRate > 0.5 && user.totalTrades > 50) score += 15;
      break;
    case ClanType.elite:
      if (user.winRate > 0.6 && user.totalTrades > 150) score += 20;
      break;
    case ClanType.exclusive:
      score -= 50; // Penalize since it's invite-only
      break;
  }

  return score.clamp(0.0, 100.0);
}

// Challenge-related computed providers
final upcomingChallengesProvider = Provider<AsyncValue<List<ClanChallenge>>>((ref) {
  final challengesAsync = ref.watch(activeChallengesProvider);
  
  return challengesAsync.when(
    data: (challenges) {
      final upcoming = challenges.where((c) => 
          c.startTime.isAfter(DateTime.now())).toList();
      upcoming.sort((a, b) => a.startTime.compareTo(b.startTime));
      return AsyncValue.data(upcoming);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final ongoingChallengesProvider = Provider<AsyncValue<List<ClanChallenge>>>((ref) {
  final challengesAsync = ref.watch(activeChallengesProvider);
  
  return challengesAsync.when(
    data: (challenges) {
      final ongoing = challenges.where((c) => c.isActive).toList();
      ongoing.sort((a, b) => a.endTime.compareTo(b.endTime)); // Sort by ending soonest first
      return AsyncValue.data(ongoing);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Notification providers
final clanNotificationsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final userClan = ref.watch(userClanProvider);
  final invitationsAsync = ref.watch(userInvitationsProvider(
    ref.watch(currentUserProvider)?.id ?? ''
  ));
  final challengesAsync = ref.watch(activeChallengesProvider);

  final notifications = <Map<String, dynamic>>[];

  // Invitation notifications
  invitationsAsync.whenData((invitations) {
    for (final invitation in invitations.where((inv) => inv.isValid)) {
      notifications.add({
        'type': 'invitation',
        'title': 'Clan Invitation',
        'message': 'You\'ve been invited to join ${invitation.clanName}',
        'timestamp': invitation.sentDate,
        'data': invitation,
      });
    }
  });

  // Challenge notifications
  if (userClan != null) {
    challengesAsync.whenData((challenges) {
      for (final challenge in challenges) {
        if (challenge.challengingClan.id == userClan.id || 
            challenge.defendingClan?.id == userClan.id) {
          if (challenge.isActive && challenge.timeRemaining.inHours < 24) {
            notifications.add({
              'type': 'challenge_ending',
              'title': 'Challenge Ending Soon',
              'message': '${challenge.name} ends in ${challenge.timeRemaining.inHours}h',
              'timestamp': challenge.endTime.subtract(challenge.timeRemaining),
              'data': challenge,
            });
          }
        }
      }
    });
  }

  // Sort by timestamp (newest first)
  notifications.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

  return notifications;
});