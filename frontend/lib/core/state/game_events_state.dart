import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../models/game_event.dart';
import '../../data/services/game_event_ws_service.dart';

part 'game_events_state.freezed.dart';

/// Immutable state class for game events management
@freezed
class GameEventsState with _$GameEventsState {
  const factory GameEventsState({
    @Default([]) List<GameEvent> recentEvents,
    @Default(false) bool isConnected,
    @Default(null) String? lastError,
    @Default(null) DateTime? lastEventTime,
    @Default(0) int totalEventsReceived,
  }) = _GameEventsState;
}

/// Notifier for managing game events state
class GameEventsNotifier extends StateNotifier<GameEventsState> {
  GameEventsNotifier(this._ref) : super(const GameEventsState()) {
    _initializeEventStream();
  }

  final Ref _ref;
  static const int _maxRecentEvents = 50;

  void _initializeEventStream() {
    final webSocketService = GameEventWebSocketService();

    webSocketService.stream.listen(
      (event) {
        _addEvent(event);
        state = state.copyWith(
          isConnected: true,
          lastError: null,
          lastEventTime: DateTime.now(),
          totalEventsReceived: state.totalEventsReceived + 1,
        );
      },
      onError: (error) {
        state = state.copyWith(isConnected: false, lastError: error.toString());
      },
    );
  }

  void _addEvent(GameEvent event) {
    final updatedEvents = [...state.recentEvents, event];

    // Keep only the most recent events to prevent memory issues
    if (updatedEvents.length > _maxRecentEvents) {
      updatedEvents.removeRange(0, updatedEvents.length - _maxRecentEvents);
    }

    state = state.copyWith(recentEvents: updatedEvents);
  }

  /// Get events of a specific type
  List<GameEvent> getEventsByType(String eventType) {
    return state.recentEvents
        .where((event) => event.type == eventType)
        .toList();
  }

  /// Get events for a specific player
  List<GameEvent> getEventsForPlayer(String playerId) {
    return state.recentEvents
        .where((event) => event.playerId == playerId)
        .toList();
  }

  /// Clear all recent events
  void clearEvents() {
    state = state.copyWith(recentEvents: []);
  }

  /// Manually add an event (for testing)
  void addTestEvent(GameEvent event) {
    _addEvent(event);
  }
}

/// Primary provider for game events state
final gameEventsProvider =
    StateNotifierProvider<GameEventsNotifier, GameEventsState>((ref) {
      return GameEventsNotifier(ref);
    });

/// StreamProvider for real-time game events
/// Uses the WebSocket service directly for optimal performance
final gameEventStreamProvider = StreamProvider<GameEvent>((ref) {
  final webSocketService = GameEventWebSocketService();
  webSocketService.connect();

  ref.onDispose(() {
    webSocketService.dispose();
  });

  return webSocketService.stream;
});

/// Provider for connection status
final gameEventsConnectionProvider = Provider<bool>((ref) {
  return ref.watch(gameEventsProvider.select((state) => state.isConnected));
});

/// Provider for recent events count
final recentEventsCountProvider = Provider<int>((ref) {
  return ref.watch(
    gameEventsProvider.select((state) => state.recentEvents.length),
  );
});

/// Provider for last event time
final lastEventTimeProvider = Provider<DateTime?>((ref) {
  return ref.watch(gameEventsProvider.select((state) => state.lastEventTime));
});

/// Provider for events of specific type (parameterized)
final eventsByTypeProvider = Provider.family<List<GameEvent>, String>((
  ref,
  eventType,
) {
  return ref.watch(gameEventsProvider.notifier).getEventsByType(eventType);
});

/// Provider for events by player (parameterized)
final eventsByPlayerProvider = Provider.family<List<GameEvent>, String>((
  ref,
  playerId,
) {
  return ref.watch(gameEventsProvider.notifier).getEventsForPlayer(playerId);
});
