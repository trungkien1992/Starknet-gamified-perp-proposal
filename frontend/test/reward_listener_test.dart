import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/reward/ui/reward_listener.dart';

void main() {
  testWidgets('shows modal when reward arrives', (tester) async {
    final controller = StreamController<RewardEvent>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [rewardProvider.overrideWith((ref) => controller.stream)],
        child: const MaterialApp(home: RewardListener()),
      ),
    );

    controller.add(
      const RewardEvent(type: GameEventType.reward, payload: 'hoodie'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('Reward: hoodie!'), findsOneWidget);

    controller.close();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('modal auto closes after 2 s', (tester) async {
    final controller = StreamController<RewardEvent>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [rewardProvider.overrideWith((ref) => controller.stream)],
        child: const MaterialApp(home: RewardListener()),
      ),
    );
    controller.add(
      const RewardEvent(type: GameEventType.reward, payload: 'cap'),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Reward: cap!'), findsNothing);
    controller.close();
  });
}
