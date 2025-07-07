import 'package:flutter_riverpod/flutter_riverpod.dart';

class InkNotifier extends StateNotifier<int> {
  InkNotifier() : super(100); // Start with 100 ink

  void spendInk(int amount) {
    if (state >= amount) {
      state = state - amount;
    }
  }

  void refillInk() {
    state = 100; // Reset to full
  }

  void gainInk(int amount) {
    state = (state + amount).clamp(0, 100);
  }
}

final inkProvider = StateNotifierProvider<InkNotifier, int>((ref) {
  return InkNotifier();
});