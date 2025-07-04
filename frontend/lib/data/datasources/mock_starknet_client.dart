import 'starknet_client.dart';

class MockStarknetClient implements IStarknetClient {
  @override
  Future<String> executeTrade({
    required String direction,
    required double leverage,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Return a fake PnL result
    final pnl = (direction == 'LONG' ? 1 : -1) * (leverage * 10).toInt();
    return 'Mock trade executed: $direction, PnL: $pnl';
  }

  @override
  Future<List<String>> getFakeNFTs() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return ['Mock NFT #1', 'Mock NFT #2'];
  }

  @override
  Future<int> getXP() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return 100;
  }

  @override
  Future<bool> isConnected() async => true;
}
