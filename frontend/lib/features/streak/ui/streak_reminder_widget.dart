import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../trade/state/trade_tracker_provider.dart';

class StreakReminderWidget extends ConsumerStatefulWidget {
  const StreakReminderWidget({super.key});
  @override
  ConsumerState<StreakReminderWidget> createState() =>
      _StreakReminderWidgetState();
}

class _StreakReminderWidgetState extends ConsumerState<StreakReminderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 1.0,
      upperBound: 1.08,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lastTradeAt = ref.watch(tradeTrackerProvider).lastTradeAt;
    final now = DateTime.now();
    final showPrompt =
        lastTradeAt == null || now.difference(lastTradeAt).inHours >= 24;
    if (!showPrompt) return const SizedBox.shrink();
    final timeLeft = lastTradeAt == null
        ? Duration.zero
        : Duration(hours: 24) - now.difference(lastTradeAt);
    final percent = timeLeft.inSeconds.clamp(0, 86400) / 86400;
    return Center(
      child: ScaleTransition(
        scale: _pulseController,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.yellow[100],
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.yellow.withValues(alpha: 0.5),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '⚡ Your streak is about to reset!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: percent,
                  minHeight: 8,
                  backgroundColor: Colors.yellow[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
                const SizedBox(height: 8),
                Text(
                  timeLeft.isNegative
                      ? 'Streak will reset soon!'
                      : '${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m left',
                  style: const TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
