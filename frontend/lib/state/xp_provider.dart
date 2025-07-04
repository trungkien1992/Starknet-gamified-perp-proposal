import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/reward/state/reward_state.dart';

const _milestones = <int, String>{
  50: 'Graffiti Hoodie',
  100: 'Spray Can Backpack',
  200: 'Neon Shades',
};

class XPNotifier extends StateNotifier<int> {
  final Ref ref;
  XPNotifier(this.ref) : super(0);
  final Set<String> _unlockedNfts = {};

  void addXP(int amount) {
    final prevXP = state;
    state += amount;
    for (final entry in _milestones.entries) {
      if (prevXP < entry.key &&
          state >= entry.key &&
          !_unlockedNfts.contains(entry.value)) {
        _unlockedNfts.add(entry.value);
        ref.read(rewardProvider.notifier).showNFT(entry.value);
      }
    }
  }

  void resetXP() {
    state = 0;
    _unlockedNfts.clear();
  }

  List<String> get unlockedNfts => _unlockedNfts.toList();
}

final xpProvider = StateNotifierProvider<XPNotifier, int>(
  (ref) => XPNotifier(ref),
);
final unlockedNftsProvider = Provider<List<String>>(
  (ref) => ref.watch(xpProvider.notifier).unlockedNfts,
);
