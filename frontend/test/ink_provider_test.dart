import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lib/main.dart';

void main() {
  test('inkProvider accumulates positive deltas', () async {
    final container = ProviderContainer(overrides: [
      inkProvider.overrideWith((ref) => Stream.value(12)),
    ]);
    expect(container.read(totalInkProvider), 12);
  });
}
