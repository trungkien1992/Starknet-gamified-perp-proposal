import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

enum GameEventType {
  xpEarned,
  streakUpdated,
  badgeMinted,
  tileCaptured,
  tradeLoss,
}

class GameEvent {
  final GameEventType type;
  final dynamic payload;
  final DateTime timestamp;
  GameEvent({required this.type, this.payload, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

final _gameEventController = StreamController<GameEvent>.broadcast();
final gameEventSink = _gameEventController.sink;
final gameEventStreamProvider = StreamProvider<GameEvent>((ref) {
  return _gameEventController.stream;
});
