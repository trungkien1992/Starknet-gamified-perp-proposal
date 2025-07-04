import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/reward/ui/game_event_listener.dart';
import 'package:frontend/models/game_event.dart';
import 'package:frontend/features/drip/state/drip_provider.dart';
import 'package:frontend/models/drip_nft.dart';

class _FakeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();
  // Add this property to satisfy NetworkImage
  bool autoUncompress = false;
  // Implement all other methods as no-op or throw UnimplementedError
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();
  // Implement all other methods as no-op or throw UnimplementedError
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _transparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final controller = StreamController<List<int>>();
    controller.add(_transparentImage);
    controller.close();
    return controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  // Implement all other methods as no-op or throw UnimplementedError
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _transparentImage = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

void main() {
  setUpAll(() {
    HttpOverrides.global = _FakeHttpOverrides();
  });
  testWidgets('GameEventListener reacts to XP, streak, and badge events', (
    tester,
  ) async {
    final controller = StreamController<GameEvent>();
    final testNFTs = [
      DripNFT(
        id: 'legendary_drip',
        name: 'Legendary Drip',
        rarity: DripRarity.legendary,
        imageUrl: 'https://example.com/legendary.png',
      ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dripProvider.overrideWith(
            (ref) => DripNotifier()..state = DripState(nfts: testNFTs),
          ),
        ],
        child: MaterialApp(
          home: GameEventListener(eventStream: controller.stream),
        ),
      ),
    );
    // Emit XP event
    controller.add(
      GameEvent(
        type: 'xp.earned',
        playerId: 'test',
        timestamp: DateTime.now(),
        payload: {'amount': 10},
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('+10 XP!'), findsOneWidget);
    // Emit badge event
    controller.add(
      GameEvent(
        type: 'badge.minted',
        playerId: 'test',
        timestamp: DateTime.now(),
        payload: {'badge': 'Legendary Drip'},
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Legendary Drip'), findsOneWidget);
    expect(find.text('You unlocked a new Drip!'), findsOneWidget);
    // Emit streak event (shows dialog)
    controller.add(
      GameEvent(
        type: 'streak.milestone',
        playerId: 'test',
        timestamp: DateTime.now(),
        payload: {'streak': 3, 'badge': 'Streak Master'},
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('3-Day Streak!'), findsOneWidget);
    expect(find.text('Streak Master Badge'), findsOneWidget);
    controller.close();
    await tester.pump(const Duration(seconds: 3));
  });
}
