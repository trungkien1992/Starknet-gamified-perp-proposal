import 'package:flutter_riverpod/flutter_riverpod.dart';

class TradeTrackerState {
  final DateTime? lastTradeAt;
  const TradeTrackerState({this.lastTradeAt});

  TradeTrackerState copyWith({DateTime? lastTradeAt}) =>
      TradeTrackerState(lastTradeAt: lastTradeAt ?? this.lastTradeAt);
}

class TradeTrackerNotifier extends StateNotifier<TradeTrackerState> {
  TradeTrackerNotifier() : super(const TradeTrackerState());

  void recordTrade() {
    state = state.copyWith(lastTradeAt: DateTime.now());
  }
}

final tradeTrackerProvider =
    StateNotifierProvider<TradeTrackerNotifier, TradeTrackerState>(
      (ref) => TradeTrackerNotifier(),
    );
