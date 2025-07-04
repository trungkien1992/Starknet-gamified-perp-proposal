import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'reward_state.freezed.dart';

/// Immutable reward state using freezed for better performance and safety
@freezed
class RewardState with _$RewardState {
  const factory RewardState({
    @Default(0) int xpGained,
    @Default(null) String? nftName,
    @Default(false) bool show,
    @Default(null) DateTime? showTimestamp,
    @Default(RewardType.none) RewardType type,
  }) = _RewardState;
}

/// Enum for different reward types
enum RewardType { none, xp, nft, both }

/// Enhanced reward notifier with better state management
class RewardNotifier extends StateNotifier<RewardState> {
  RewardNotifier(this._ref) : super(const RewardState());

  final Ref _ref;

  /// Show XP reward with auto-hide timer
  void showXP(int xp) {
    state = RewardState(
      xpGained: xp,
      show: true,
      showTimestamp: DateTime.now(),
      type: RewardType.xp,
    );

    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) hide();
    });
  }

  /// Show NFT reward with auto-hide timer
  void showNFT(String nft) {
    state = RewardState(
      nftName: nft,
      show: true,
      showTimestamp: DateTime.now(),
      type: RewardType.nft,
    );

    // Auto-hide after 4 seconds (longer for NFTs)
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) hide();
    });
  }

  /// Show combined XP and NFT reward
  void showCombined(int xp, String nft) {
    state = RewardState(
      xpGained: xp,
      nftName: nft,
      show: true,
      showTimestamp: DateTime.now(),
      type: RewardType.both,
    );

    // Auto-hide after 5 seconds (longest for combined)
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) hide();
    });
  }

  /// Manually hide the reward display
  void hide() {
    if (mounted) {
      state = const RewardState();
    }
  }

  /// Check if reward is currently visible
  bool get isVisible => state.show;

  /// Get time since reward was shown
  Duration? get timeSinceShown {
    if (state.showTimestamp == null) return null;
    return DateTime.now().difference(state.showTimestamp!);
  }
}

/// Primary provider for reward state
final rewardProvider = StateNotifierProvider<RewardNotifier, RewardState>((
  ref,
) {
  return RewardNotifier(ref);
});

/// Provider for checking if any reward is currently visible
final isRewardVisibleProvider = Provider<bool>((ref) {
  return ref.watch(rewardProvider.select((state) => state.show));
});

/// Provider for current reward type
final currentRewardTypeProvider = Provider<RewardType>((ref) {
  return ref.watch(rewardProvider.select((state) => state.type));
});

/// Provider for XP amount (when visible)
final currentXPRewardProvider = Provider<int?>((ref) {
  final state = ref.watch(rewardProvider);
  return state.show &&
          (state.type == RewardType.xp || state.type == RewardType.both)
      ? state.xpGained
      : null;
});

/// Provider for NFT name (when visible)
final currentNFTRewardProvider = Provider<String?>((ref) {
  final state = ref.watch(rewardProvider);
  return state.show &&
          (state.type == RewardType.nft || state.type == RewardType.both)
      ? state.nftName
      : null;
});
