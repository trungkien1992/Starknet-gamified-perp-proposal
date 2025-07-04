import 'package:flutter_riverpod/flutter_riverpod.dart';

/// StateNotifier for managing ink balance
class InkNotifier extends StateNotifier<int> {
  InkNotifier() : super(100); // Start with 100 ink

  /// Spend ink for trading
  void spendInk(int amount) {
    if (state >= amount) {
      state -= amount;
    } else {
      throw Exception('Insufficient ink');
    }
  }

  /// Add ink (for rewards, etc.)
  void addInk(int amount) {
    state += amount;
  }

  /// Reset ink to default value
  void resetInk() {
    state = 100;
  }
}

/// Provider for ink balance
final inkProvider = StateNotifierProvider<InkNotifier, int>(
  (ref) => InkNotifier(),
);

/// Legacy provider for backward compatibility
final totalInkProvider = inkProvider;
