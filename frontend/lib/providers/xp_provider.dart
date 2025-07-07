import 'package:flutter_riverpod/flutter_riverpod.dart';

class XPNotifier extends StateNotifier<int> {
  XPNotifier() : super(0); // Start with 0 XP

  void gainXP(int amount) {
    state = state + amount;
  }

  void resetXP() {
    state = 0;
  }

  int get level => (state / 100).floor() + 1;
  int get xpToNextLevel => 100 - (state % 100);
  double get progressToNextLevel => (state % 100) / 100.0;
}

final xpProvider = StateNotifierProvider<XPNotifier, int>((ref) {
  return XPNotifier();
});