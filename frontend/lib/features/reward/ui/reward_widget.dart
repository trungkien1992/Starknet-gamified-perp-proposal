import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/reward_state.dart';

class RewardWidget extends ConsumerStatefulWidget {
  const RewardWidget({super.key});
  @override
  ConsumerState<RewardWidget> createState() => _RewardWidgetState();
}

class _RewardWidgetState extends ConsumerState<RewardWidget> {
  @override
  Widget build(BuildContext context) {
    final reward = ref.watch(rewardProvider);
    if (!reward.show) return const SizedBox.shrink();
    Future.delayed(
      const Duration(seconds: 2),
      () => ref.read(rewardProvider.notifier).hide(),
    );
    return Center(
      child: AnimatedOpacity(
        opacity: reward.show ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: Card(
          color: Colors.black.withValues(alpha: 0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reward.xpGained > 0)
                  Text(
                    '+${reward.xpGained} XP!',
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (reward.nftName != null)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.purple,
                        size: 48,
                      ),
                      Text(
                        'Unlocked: ${reward.nftName!}',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                const Text('🎉', style: TextStyle(fontSize: 40)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
