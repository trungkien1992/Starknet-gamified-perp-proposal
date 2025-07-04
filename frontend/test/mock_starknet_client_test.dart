import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/datasources/mock_starknet_client.dart';

void main() {
  test('MockStarknetClient returns fake trade result', () async {
    final client = MockStarknetClient();
    final result = await client.executeTrade(direction: 'LONG', leverage: 2.0);
    expect(result, contains('Mock trade executed'));
  });

  test('MockStarknetClient returns fake NFTs', () async {
    final client = MockStarknetClient();
    final nfts = await client.getFakeNFTs();
    expect(nfts, contains('Mock NFT #1'));
  });

  test('MockStarknetClient returns fake XP', () async {
    final client = MockStarknetClient();
    final xp = await client.getXP();
    expect(xp, 100);
  });

  test('MockStarknetClient is always connected', () async {
    final client = MockStarknetClient();
    final connected = await client.isConnected();
    expect(connected, isTrue);
  });
}
