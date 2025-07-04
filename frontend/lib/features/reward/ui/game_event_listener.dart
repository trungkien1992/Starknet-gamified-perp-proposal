import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/game_event.dart';
import '../../../data/services/game_event_ws_service.dart';
import '../state/reward_state.dart';
import 'reward_widget.dart';
import '../../streak/ui/streak_popup.dart';
import '../../streak/ui/badge_earned_widget.dart';
import '../../drip/ui/drip_reward_modal.dart';
import '../../drip/state/drip_provider.dart';
import '../../../models/drip_nft.dart';

class GameEventListener extends ConsumerStatefulWidget {
  const GameEventListener({super.key, this.eventStream});
  final Stream<GameEvent>? eventStream;
  @override
  ConsumerState<GameEventListener> createState() => _GameEventListenerState();
}

class _GameEventListenerState extends ConsumerState<GameEventListener>
    with TickerProviderStateMixin {
  OverlayEntry? _badgeOverlay;
  OverlayEntry? _dripModal;
  OverlayEntry? _streakLossOverlay;
  late final Stream<GameEvent> _eventStream;
  late AnimationController _shakeController;
  late AnimationController _celebrationController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _celebrationAnimation;
  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
    _celebrationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.easeOut),
    );

    // Use injected stream for tests, otherwise use the real backend
    _eventStream = widget.eventStream ?? GameEventWebSocketService().stream;
    if (widget.eventStream == null) {
      GameEventWebSocketService().connect('ws://localhost:8080/ws/game-events');
    }
    _eventStream.listen((event) async {
      if (event.type == 'xp.earned') {
        if (event.payload is Map && event.payload['amount'] != null) {
          ref
              .read(rewardProvider.notifier)
              .showXP(event.payload['amount'] as int);
          _triggerScreenShake(); // Add impact for XP gains
        }
      } else if (event.type == 'streak.milestone') {
        if (event.payload is Map &&
            event.payload['streak'] != null &&
            event.payload['badge'] != null) {
          _showBadge(
            context,
            event.payload['streak'] as int,
            event.payload['badge'] as String,
          );
          _triggerCelebration(); // Major celebration for milestones
        }
      } else if (event.type == 'streak.reset') {
        if (event.payload is Map && event.payload['lost_streak'] != null) {
          final lostStreak = event.payload['lost_streak'] as int;
          final reason = event.payload['reason'] as String? ?? 'timeout';
          _showStreakLoss(context, lostStreak, reason);
          _triggerLossEffect(); // Visual feedback for streak loss
        }
      } else if (event.type == 'badge.minted' || event.type == 'drip.minted') {
        final nfts = ref.read(dripProvider).nfts;
        if (nfts.isEmpty) return;
        final nft = nfts.firstWhere(
          (n) =>
              n.name == event.payload['badge'] ||
              n.id == event.payload['badge'],
          orElse: () => nfts.first,
        );
        if (nft != null) {
          _showDripModal(context, nft);
          _triggerRareItemEffect(); // Special effect for NFT drops
        }
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _celebrationController.dispose();
    _badgeOverlay?.remove();
    _dripModal?.remove();
    _streakLossOverlay?.remove();
    super.dispose();
  }

  // Animation trigger methods
  void _triggerScreenShake() {
    _shakeController.forward().then((_) => _shakeController.reverse());
  }

  void _triggerCelebration() {
    _celebrationController.forward().then(
      (_) => _celebrationController.reset(),
    );
  }

  void _triggerLossEffect() {
    // Use red flash/shake for streak loss
    _shakeController.forward().then((_) => _shakeController.reverse());
  }

  void _triggerRareItemEffect() {
    // Golden celebration for rare items
    _celebrationController.forward().then(
      (_) => _celebrationController.reset(),
    );
  }

  void _showBadge(
    BuildContext context,
    int streak,
    String badge, {
    String? message,
  }) {
    _badgeOverlay?.remove();
    _badgeOverlay = OverlayEntry(
      builder: (_) =>
          BadgeEarnedWidget(badge: badge, streak: streak, message: message),
    );
    Overlay.of(context, rootOverlay: true)?.insert(_badgeOverlay!);
    Future.delayed(const Duration(seconds: 2), () => _badgeOverlay?.remove());
  }

  void _showDripModal(BuildContext context, DripNFT nft) {
    _dripModal?.remove();
    _dripModal = OverlayEntry(
      builder: (_) =>
          DripRewardModal(nft: nft, onClose: () => _dripModal?.remove()),
    );
    Overlay.of(context, rootOverlay: true)?.insert(_dripModal!);
  }

  void _showStreakLoss(BuildContext context, int lostStreak, String reason) {
    _streakLossOverlay?.remove();
    _streakLossOverlay = OverlayEntry(
      builder: (_) => _StreakLossWidget(
        lostStreak: lostStreak,
        reason: reason,
        onClose: () => _streakLossOverlay?.remove(),
      ),
    );
    Overlay.of(context, rootOverlay: true)?.insert(_streakLossOverlay!);
    Future.delayed(
      const Duration(seconds: 3),
      () => _streakLossOverlay?.remove(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_shakeAnimation, _celebrationAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            (_shakeAnimation.value * 10 * (1 - _shakeAnimation.value)) *
                (1 - 2 * (_shakeAnimation.value % 0.5)),
            0,
          ),
          child: Container(
            decoration: _celebrationAnimation.value > 0.1
                ? BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.yellow.withValues(
                          alpha: _celebrationAnimation.value * 0.3,
                        ),
                        blurRadius: 20 * _celebrationAnimation.value,
                        spreadRadius: 5 * _celebrationAnimation.value,
                      ),
                    ],
                  )
                : null,
            child: Column(
              children: [
                const RewardWidget(),
                // Dev/test button to emit mock events
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        ref.read(rewardProvider.notifier).showXP(25);
                        _triggerScreenShake();
                      },
                      child: const Text('Emit XP'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _showBadge(context, 5, 'Test Badge');
                        _triggerCelebration();
                      },
                      child: const Text('Emit Streak'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _showStreakLoss(context, 7, 'inactivity_timeout');
                        _triggerLossEffect();
                      },
                      child: const Text('Emit Loss'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// New widget for streak loss feedback
class _StreakLossWidget extends StatefulWidget {
  final int lostStreak;
  final String reason;
  final VoidCallback onClose;

  const _StreakLossWidget({
    required this.lostStreak,
    required this.reason,
    required this.onClose,
  });

  @override
  State<_StreakLossWidget> createState() => _StreakLossWidgetState();
}

class _StreakLossWidgetState extends State<_StreakLossWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.all(40),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade900, Colors.red.shade700],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('💔', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        const Text(
                          'STREAK LOST',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lost ${widget.lostStreak} day streak',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.reason == 'inactivity_timeout'
                              ? 'Due to inactivity'
                              : 'Reason: ${widget.reason}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Trade daily to keep your streak alive!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
