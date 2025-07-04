import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../models/drip_nft.dart';

part 'drip_provider.freezed.dart';

/// Immutable drip state using freezed for better performance
@freezed
class DripState with _$DripState {
  const factory DripState({
    @Default([]) List<DripNFT> nfts,
    @Default(null) String? equippedId,
    @Default(false) bool loading,
    @Default(null) String? lastEquippedId,
    @Default(null) DateTime? lastEquipTime,
    @Default({}) Map<String, bool> newNftFlags,
  }) = _DripState;
}

/// Enhanced drip notifier with better state management
class DripNotifier extends StateNotifier<DripState> {
  DripNotifier(this._ref) : super(_getInitialState());

  final Ref _ref;

  static DripState _getInitialState() {
    final initialNfts = [
      DripNFT(
        id: '1',
        name: 'Diamond Spray',
        rarity: DripRarity.legendary,
        imageUrl: 'https://via.placeholder.com/80x80?text=Diamond',
      ),
      DripNFT(
        id: '2',
        name: 'XP Flame Hoodie',
        rarity: DripRarity.epic,
        imageUrl: 'https://via.placeholder.com/80x80?text=Flame',
      ),
      DripNFT(
        id: '3',
        name: 'Starter Cap',
        rarity: DripRarity.common,
        imageUrl: 'https://via.placeholder.com/80x80?text=Cap',
      ),
    ];

    return DripState(nfts: initialNfts, equippedId: '1');
  }

  /// Equip an NFT by ID
  void equip(String id) {
    if (!state.nfts.any((nft) => nft.id == id)) {
      throw ArgumentError('NFT with ID $id not found');
    }

    state = state.copyWith(
      equippedId: id,
      lastEquippedId: state.equippedId,
      lastEquipTime: DateTime.now(),
    );
  }

  /// Add a new NFT to the inventory
  void addNFT(DripNFT nft) {
    final updatedNfts = [...state.nfts, nft];
    final updatedFlags = {...state.newNftFlags, nft.id: true};

    state = state.copyWith(nfts: updatedNfts, newNftFlags: updatedFlags);
  }

  /// Mark an NFT as seen (remove "new" flag)
  void markNFTAsSeen(String nftId) {
    final updatedFlags = {...state.newNftFlags};
    updatedFlags.remove(nftId);

    state = state.copyWith(newNftFlags: updatedFlags);
  }

  /// Check if an NFT is new/unseen
  bool isNFTNew(String nftId) {
    return state.newNftFlags[nftId] ?? false;
  }

  /// Get equipped NFT
  DripNFT? get equippedNFT {
    if (state.equippedId == null) return null;
    return state.nfts.firstWhere(
      (nft) => nft.id == state.equippedId,
      orElse: () => throw StateError('Equipped NFT not found'),
    );
  }

  /// Get NFTs by rarity
  List<DripNFT> getNFTsByRarity(DripRarity rarity) {
    return state.nfts.where((nft) => nft.rarity == rarity).toList();
  }

  /// Get new NFTs count
  int get newNFTsCount => state.newNftFlags.length;

  /// Set loading state
  void setLoading(bool loading) {
    state = state.copyWith(loading: loading);
  }
}

/// Primary provider for drip state
final dripProvider = StateNotifierProvider<DripNotifier, DripState>((ref) {
  return DripNotifier(ref);
});

/// Provider for equipped NFT
final equippedNFTProvider = Provider<DripNFT?>((ref) {
  final dripState = ref.watch(dripProvider);
  if (dripState.equippedId == null) return null;

  try {
    return dripState.nfts.firstWhere((nft) => nft.id == dripState.equippedId);
  } catch (e) {
    return null;
  }
});

/// Provider for NFTs by rarity (parameterized)
final nftsByRarityProvider = Provider.family<List<DripNFT>, DripRarity>((
  ref,
  rarity,
) {
  return ref.watch(dripProvider.notifier).getNFTsByRarity(rarity);
});

/// Provider for new NFTs count
final newNFTsCountProvider = Provider<int>((ref) {
  return ref.watch(dripProvider.notifier).newNFTsCount;
});

/// Provider for checking if specific NFT is new
final isNFTNewProvider = Provider.family<bool, String>((ref, nftId) {
  return ref.watch(dripProvider.notifier).isNFTNew(nftId);
});

/// Provider for drip loading state
final dripLoadingProvider = Provider<bool>((ref) {
  return ref.watch(dripProvider.select((state) => state.loading));
});
