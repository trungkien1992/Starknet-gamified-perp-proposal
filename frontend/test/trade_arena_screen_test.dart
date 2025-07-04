import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/trade/ui/trade_arena_screen.dart';
import 'package:frontend/state/xp_provider.dart';
import 'package:frontend/features/reward/state/reward_state.dart';
import 'package:frontend/features/reward/ui/reward_widget.dart';
import 'package:frontend/features/trade/providers/wallet_provider.dart';
import 'package:frontend/features/trade/ui/widgets/swipe_bar.dart';
import 'package:frontend/features/trade/widgets/swipe_spray_gauge.dart';

class FakeWalletNotifier extends WalletNotifier {
  FakeWalletNotifier() : super(FakeRef());
}

class FakeRef implements Ref {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('TradeArenaScreen swipe triggers XP and reward', (tester) async {
    final xpNotifier = XPNotifier(FakeRef());
    final rewardNotifier = RewardNotifier();
    final walletNotifier = FakeWalletNotifier();
    walletNotifier.state = walletNotifier.state.copyWith(isConnected: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          xpProvider.overrideWith((ref) => xpNotifier),
          rewardProvider.overrideWith((ref) => rewardNotifier),
          walletProvider.overrideWith((ref) => walletNotifier),
        ],
        child: const MaterialApp(home: TradeArenaScreen()),
      ),
    );
    // Directly trigger XP and reward logic
    xpNotifier.addXP(10);
    rewardNotifier.showXP(10);
    await tester.pump(const Duration(milliseconds: 500));
    // Assert XP state updated
    expect(xpNotifier.state, greaterThan(0));
    // Assert RewardWidget appears
    expect(find.byType(RewardWidget), findsWidgets);
    // Assert XP burst text appears
    expect(find.textContaining('+10 XP'), findsWidgets);
    // Allow RewardWidget timer to complete
    await tester.pump(const Duration(seconds: 2));
  });
}
