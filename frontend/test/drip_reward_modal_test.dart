import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/drip/ui/drip_reward_modal.dart';
import 'package:frontend/models/drip_nft.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/reward/ui/game_event_listener.dart';
import 'package:frontend/models/game_event.dart';
import 'package:frontend/features/drip/state/drip_provider.dart';

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient();
  }
}

class _FakeHttpClient implements HttpClient {
  bool _autoUncompress = true;
  @override
  bool get autoUncompress => _autoUncompress;
  @override
  set autoUncompress(bool value) => _autoUncompress = value;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();
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
    HttpOverrides.global = TestHttpOverrides();
  });

  testWidgets('DripRewardModal animates and shows NFT info', (tester) async {
    final nft = DripNFT(
      id: '1',
      name: 'Gold Tag Jacket',
      rarity: DripRarity.legendary,
      imageUrl: 'https://via.placeholder.com/100x100?text=Gold+Tag',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => DripRewardModal(nft: nft),
              );
            },
            child: const Text('Show Modal'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Show Modal'));
    await tester.pumpAndSettle();
    expect(find.text('Gold Tag Jacket'), findsOneWidget);
    expect(find.text('LEGENDARY'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    // Animation in
    await tester.pump(const Duration(milliseconds: 600));
    // Auto-dismiss after 3s
    await tester.pump(const Duration(seconds: 3));
    // Wait for fade out (300ms)
    await tester.pump(const Duration(milliseconds: 300));
    // Wait for any remaining microtasks (pop)
    await tester.pumpAndSettle();
    expect(find.byType(DripRewardModal), findsNothing);
  });

  testWidgets('DripRewardModal appears and animates on drip.minted event', (
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
    // Emit drip.minted event
    controller.add(
      GameEvent(
        type: 'drip.minted',
        playerId: 'test',
        timestamp: DateTime.now(),
        payload: {'badge': 'Legendary Drip'},
      ),
    );
    await tester.pump();
    await tester.pump(
      const Duration(milliseconds: 400),
    ); // allow animation to start
    // Modal should be visible
    expect(find.text('Legendary Drip'), findsOneWidget);
    expect(find.text('You unlocked a new Drip!'), findsOneWidget);
    expect(find.text('LEGENDARY'), findsOneWidget);
    // Wait for auto-dismiss
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    // Modal should be gone
    expect(find.text('Legendary Drip'), findsNothing);
  });

  testWidgets('DripRewardModal shows share button on drip.minted event', (
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
    // Emit drip.minted event
    controller.add(
      GameEvent(
        type: 'drip.minted',
        playerId: 'test',
        timestamp: DateTime.now(),
        payload: {'badge': 'Legendary Drip'},
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // Share button should be present
    expect(find.byIcon(Icons.share), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Share'), findsOneWidget);
  });
}
