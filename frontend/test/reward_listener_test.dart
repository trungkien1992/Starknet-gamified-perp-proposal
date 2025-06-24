import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../lib/main.dart';

void main() {
  testWidgets('shows modal when reward arrives', (tester) async {
    final controller = StreamController<String>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rewardProvider.overrideWith((ref) => controller.stream),
        ],
        child: const MaterialApp(home: RewardListener()),
      ),
    );

    controller.add('hoodie');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('Reward unlocked: hoodie'), findsOneWidget);

    controller.close();
  });

  testWidgets('modal auto closes after 2 s', (tester) async {
    final controller = StreamController<String>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rewardProvider.overrideWith((ref) => controller.stream),
        ],
        child: const MaterialApp(home: RewardListener()),
      ),
    );
    controller.add('cap');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Reward unlocked: cap'), findsNothing);
    controller.close();
  });
}
