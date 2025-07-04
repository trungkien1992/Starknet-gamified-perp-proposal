import 'dart:async';

class GameEvent {
  final String type;
  final String playerId;
  final DateTime timestamp;
  final dynamic payload;

  GameEvent({
    required this.type,
    required this.playerId,
    required this.timestamp,
    this.payload,
  });

  factory GameEvent.fromJson(Map<String, dynamic> json) {
    return GameEvent(
      type: json['type'] as String,
      playerId: json['player_id'] as String,
      timestamp: DateTime.parse(
        json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      ),
      payload: json['payload'],
    );
  }
}
