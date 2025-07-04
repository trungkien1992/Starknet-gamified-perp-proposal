import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/datasources/starknet_api.dart';

void main() {
  final api = StarknetApi();

  test('Fetch latest block number from Starknet', () async {
    final blockNumber = await api.getLatestBlockNumber();
    expect(blockNumber, isA<int>());
    expect(blockNumber, greaterThan(0));
  });

  // The following tests are skipped due to endpoint limitations:
  // - starknet_getBlockWithTxs and starknet_getBlockWithTxHashes are not supported by the Alchemy Sepolia endpoint.
  // test('Fetch latest block info from Starknet', () async {
  //   final blockInfo = await api.getBlockInfo();
  //   expect(blockInfo, isA<Map<String, dynamic>>());
  //   expect(blockInfo['block_number'], isNotNull);
  //   expect(blockInfo['block_hash'], isNotNull);
  // });
  // test('Fetch block with transaction hashes from Starknet', () async {
  //   final block = await api.getBlockWithTxHashes();
  //   expect(block, isA<Map<String, dynamic>>());
  //   expect(block['block_hash'], isNotNull);
  // });

  test('Connection health returns true for reachable endpoint', () async {
    bool connected = false;
    try {
      final blockNumber = await api.getLatestBlockNumber();
      connected = blockNumber > 0;
    } catch (_) {
      connected = false;
    }
    expect(connected, isTrue);
  });

  test('Error handling for invalid method', () async {
    // Intentionally call a non-existent method
    Future callInvalid() =>
        api.callContract(contractAddress: '0x0', entryPointSelector: 'invalid');
    expect(callInvalid, throwsException);
  });
}
