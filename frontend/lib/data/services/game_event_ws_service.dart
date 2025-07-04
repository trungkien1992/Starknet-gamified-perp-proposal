import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../../models/game_event.dart';

class GameEventWebSocketService {
  static final GameEventWebSocketService _instance =
      GameEventWebSocketService._internal();
  factory GameEventWebSocketService() => _instance;
  GameEventWebSocketService._internal();

  final _controller = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get stream => _controller.stream;
  WebSocketChannel? _channel;
  String _url = 'ws://localhost:8080/ws/game-events';

  void connect([String? url, WebSocketChannel? channel]) {
    if (url != null) _url = url;
    _connect(channel);
  }

  void _connect([WebSocketChannel? injectedChannel]) {
    if (injectedChannel != null) {
      _channel = injectedChannel;
    } else {
      _channel = WebSocketChannel.connect(Uri.parse(_url));
    }
    _channel!.stream.listen(
      (data) {
        try {
          final jsonMap = json.decode(data);
          final event = GameEvent.fromJson(jsonMap);
          _controller.add(event);
          print('[WS] Received event: [32m${event.type}[0m');
        } catch (e) {
          print('[WS] Error parsing event: $e');
        }
      },
      onError: (e) {
        print('[WS] Error: $e');
      },
      onDone: () {
        print('[WS] Connection closed. Reconnecting...');
        Future.delayed(
          const Duration(seconds: 2),
          () => _connect(injectedChannel),
        );
      },
    );
  }

  void dispose() {
    _channel?.sink.close(status.goingAway);
    _controller.close();
  }
}
