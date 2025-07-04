import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/state/xp_provider.dart';
import 'package:frontend/features/reward/state/reward_state.dart';

void main() {
  test('XPNotifier increments and resets XP', () {
    final container = ProviderContainer();
    final notifier = container.read(xpProvider.notifier);
    expect(container.read(xpProvider), 0);
    notifier.addXP(10);
    expect(container.read(xpProvider), 10);
    notifier.addXP(5);
    expect(container.read(xpProvider), 15);
    notifier.resetXP();
    expect(container.read(xpProvider), 0);
  });

  test('RewardNotifier shows and hides XP reward', () {
    final container = ProviderContainer();
    final notifier = container.read(rewardProvider.notifier);
    expect(container.read(rewardProvider).show, false);
    notifier.showXP(10);
    final state = container.read(rewardProvider);
    expect(state.show, true);
    expect(state.xpGained, 10);
    notifier.hide();
    expect(container.read(rewardProvider).show, false);
  });

  test('XP milestones unlock NFTs and trigger reward', () {
    final container = ProviderContainer();
    final xp = container.read(xpProvider.notifier);
    final reward = container.read(rewardProvider.notifier);
    expect(xp.unlockedNfts, isEmpty);
    xp.addXP(30);
    expect(xp.unlockedNfts, isEmpty);
    xp.addXP(20); // Crosses 50
    expect(xp.unlockedNfts, contains('Graffiti Hoodie'));
    xp.addXP(50); // Crosses 100
    expect(xp.unlockedNfts, contains('Spray Can Backpack'));
    xp.addXP(100); // Crosses 200
    expect(xp.unlockedNfts, contains('Neon Shades'));
    // Provider test
    final nfts = container.read(unlockedNftsProvider);
    expect(
      nfts,
      containsAll(['Graffiti Hoodie', 'Spray Can Backpack', 'Neon Shades']),
    );
  });
}
