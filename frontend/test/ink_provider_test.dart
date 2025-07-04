import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lib/main.dart';
import 'package:frontend/features/trade/state/ink_providers.dart';

void main() {
  test('inkProvider accumulates positive deltas', () async {
    final container = ProviderContainer(
      overrides: [inkProvider.overrideWith((ref) => InkNotifier()..state = 12)],
    );
    expect(container.read(totalInkProvider), 12);
  });

  test('XPNotifier accumulates XP and resets', () {
    final container = ProviderContainer();
    final notifier = container.read(xpProvider.notifier);
    expect(container.read(xpProvider), 0);
    notifier.addXP(15);
    expect(container.read(xpProvider), 15);
    notifier.addXP(5);
    expect(container.read(xpProvider), 20);
    notifier.resetXP();
    expect(container.read(xpProvider), 0);
  });
}
