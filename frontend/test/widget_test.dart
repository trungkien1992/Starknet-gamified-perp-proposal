// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/app/main.dart';
import 'package:frontend/features/trade/ui/trade_arena_screen.dart';
import 'package:frontend/features/trade/state/ink_providers.dart';
import 'package:frontend/app/routing/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/trade/providers/wallet_provider.dart';

class TestWalletNotifier extends WalletNotifier {
  TestWalletNotifier() : super(_DummyRef());
}

class _DummyRef implements Ref {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('TradeArenaScreen displays XP and Ink', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp(home: TradeArenaScreen())),
    );
    expect(find.textContaining('XP'), findsOneWidget);
    expect(find.byIcon(Icons.brush), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('XP increments when XPNotifier is updated', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: TradeArenaScreen()),
      ),
    );
    expect(find.text('0 XP'), findsOneWidget);
    container.read(xpProvider.notifier).addXP(10);
    await tester.pump();
    expect(find.text('10 XP'), findsOneWidget);
  });

  testWidgets('GoRouter navigation and login redirect', (
    WidgetTester tester,
  ) async {
    // Start with not logged in
    final walletNotifier = TestWalletNotifier();
    final container = ProviderContainer(
      overrides: [walletProvider.overrideWith((ref) => walletNotifier)],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );

    // Try to go to /drip (should redirect to /)
    appRouter.go('/drip');
    await tester.pumpAndSettle();
    expect(find.text('Tutorial Screen'), findsOneWidget);

    // Now simulate login
    walletNotifier.state = walletNotifier.state.copyWith(isConnected: true);
    appRouter.go('/drip');
    await tester.pumpAndSettle();
    expect(find.text('Drip Screen'), findsOneWidget);

    // Navigate to /streaks
    appRouter.go('/streaks');
    await tester.pumpAndSettle();
    expect(find.text('Streak Screen'), findsOneWidget);
  });
}
