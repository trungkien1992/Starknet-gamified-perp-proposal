import 'dart:convert';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:stream_channel/stream_channel.dart';
import '../lib/data/services/game_event_ws_service.dart';
import '../lib/models/game_event.dart';

// Minimal mock WebSocketSink for testing
class MockWebSocketSink implements WebSocketSink {
  final _controller = StreamController<String>();
  @override
  void add(message) {
    _controller.add(message);
  }

  @override
  Future<void> addStream(Stream stream) => Future.value();
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future close([int? closeCode, String? closeReason]) async {
    await _controller.close();
  }

  @override
  Future get done => _controller.done;
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockWebSocketChannel implements WebSocketChannel {
  final _controller = StreamController<String>();
  final _sink = MockWebSocketSink();
  @override
  Stream get stream => _controller.stream;
  @override
  WebSocketSink get sink => _sink;
  // Required properties and methods for WebSocketChannel
  @override
  int? get closeCode => null;
  @override
  String? get closeReason => null;
  @override
  String? get protocol => null;
  @override
  Future<void> get ready => Future.value();

  // StreamChannel<dynamic> interface methods for compatibility
  @override
  StreamChannel<S> cast<S>() => throw UnimplementedError();
  @override
  StreamChannel<dynamic> changeSink(
    StreamSink<dynamic> Function(StreamSink<dynamic>) change,
  ) => throw UnimplementedError();
  @override
  StreamChannel<dynamic> changeStream(
    Stream<dynamic> Function(Stream<dynamic>) change,
  ) => throw UnimplementedError();
  @override
  void pipe(StreamChannel<dynamic> other) => throw UnimplementedError();
  @override
  StreamChannel<S> transform<S>(
    StreamChannelTransformer<S, dynamic> transformer,
  ) => throw UnimplementedError();
  @override
  StreamChannel<dynamic> transformStream(
    StreamTransformer<dynamic, dynamic> transformer,
  ) => throw UnimplementedError();
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('GameEventWebSocketService parses incoming GameEvent', () async {
    final mockChannel = MockWebSocketChannel();
    final service = GameEventWebSocketService();
    service.connect(null, mockChannel);
    final eventJson = jsonEncode({
      'type': 'xp.earned',
      'player_id': '0xabc',
      'timestamp': DateTime.now().toIso8601String(),
      'payload': {'amount': 42},
    });
    // Simulate receiving a message
    Future.delayed(Duration.zero, () => mockChannel._controller.add(eventJson));
    final event = await service.stream.first;
    expect(event.type, 'xp.earned');
    expect(event.playerId, '0xabc');
    expect(event.payload['amount'], 42);
    service.dispose();
  });
}
