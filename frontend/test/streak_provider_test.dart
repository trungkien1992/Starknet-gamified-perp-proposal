import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/streak/state/streak_provider.dart';

void main() {
  test('StreakProvider increments and resets', () {
    final container = ProviderContainer();
    final streak = container.read(streakProvider.notifier);
    expect(container.read(streakProvider), 0);
    streak.checkIn();
    expect(container.read(streakProvider), 1);
    streak.checkIn();
    streak.checkIn();
    expect(container.read(streakProvider), 3);
    streak.reset();
    expect(container.read(streakProvider), 0);
  });

  test('StreakProvider returns correct badge tier', () {
    final container = ProviderContainer();
    final streak = container.read(streakProvider.notifier);
    expect(streak.currentBadge, null);
    streak.checkIn();
    streak.checkIn();
    streak.checkIn(); // 3
    expect(streak.currentBadge, 'Bronze');
    for (int i = 0; i < 4; i++) {
      streak.checkIn();
    }
    expect(streak.currentBadge, 'Silver');
    for (int i = 0; i < 7; i++) {
      streak.checkIn();
    }
    expect(streak.currentBadge, 'Gold');
  });
}
