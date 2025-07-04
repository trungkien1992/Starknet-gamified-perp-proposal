import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/drip/ui/drip_inventory_widget.dart';
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

  testWidgets('DripInventoryWidget displays NFTs and allows equip', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: Scaffold(body: DripInventoryWidget())),
      ),
    );
    await tester.pumpAndSettle();
    // Should show 3 mock NFTs
    expect(find.text('Diamond Spray'), findsOneWidget);
    expect(find.text('XP Flame Hoodie'), findsOneWidget);
    expect(find.text('Starter Cap'), findsOneWidget);
    // Tap to equip XP Flame Hoodie
    await tester.tap(find.text('XP Flame Hoodie'));
    await tester.pumpAndSettle();
    // Should show check icon on XP Flame Hoodie
    final checkIcons = find.byIcon(Icons.check_circle);
    expect(checkIcons, findsOneWidget);
  });
}
