import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/game_event_provider.dart';

const _milestones = <int, String>{3: 'Bronze', 7: 'Silver', 14: 'Gold'};

class StreakNotifier extends StateNotifier<int> {
  StreakNotifier() : super(0);
  final Set<int> _hitMilestones = {};

  void checkIn() {
    state++;
    if (_milestones.containsKey(state) && !_hitMilestones.contains(state)) {
      _hitMilestones.add(state);
      final badge = _milestones[state]!;
      gameEventSink.add(
        GameEvent(
          type: GameEventType.streakUpdated,
          payload: {'streak': state, 'badge': badge},
        ),
      );
    }
  }

  void reset() {
    state = 0;
    _hitMilestones.clear();
  }

  String? get currentBadge {
    for (final entry in _milestones.entries.toList().reversed) {
      if (state >= entry.key) return entry.value;
    }
    return null;
  }
}

final streakProvider = StateNotifierProvider<StreakNotifier, int>(
  (ref) => StreakNotifier(),
);
final currentBadgeProvider = Provider<String?>(
  (ref) => ref.watch(streakProvider.notifier).currentBadge,
);
