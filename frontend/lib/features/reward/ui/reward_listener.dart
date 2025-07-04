// The reward listener UI. The old provider is deprecated.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Event type enum
enum GameEventType { xp, streak, reward, unknown }

// Reward event class
class RewardEvent {
  final GameEventType type;
  final String payload;
  const RewardEvent({required this.type, required this.payload});
}

// This provider will be replaced by a GraphQL subscription.
final rewardProvider = StreamProvider.autoDispose<RewardEvent>((ref) {
  return const Stream<RewardEvent>.empty();
});

class RewardListener extends ConsumerStatefulWidget {
  const RewardListener({super.key});

  @override
  ConsumerState<RewardListener> createState() => _RewardListenerState();
}

class _RewardListenerState extends ConsumerState<RewardListener> {
  @override
  Widget build(BuildContext context) {
    // Listen for RewardEvent
    ref.listen<AsyncValue<RewardEvent>>(rewardProvider, (prev, next) {
      next.whenData((event) {
        _dispatchReward(event);
      });
    });
    return const SizedBox.shrink();
  }

  void _dispatchReward(RewardEvent event) {
    switch (event.type) {
      case GameEventType.xp:
        _showBurst('XP +${event.payload}');
        break;
      case GameEventType.streak:
        _showBurst('Streak: ${event.payload}');
        break;
      case GameEventType.reward:
        _showBurst('Reward: ${event.payload}!');
        break;
      default:
        _showBurst('Event: ${event.payload}');
    }
  }

  Future<void> _showBurst(String kind) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BurstModal(kind: kind),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

class _BurstModal extends StatelessWidget {
  const _BurstModal({required this.kind});
  final String kind;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          kind,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
