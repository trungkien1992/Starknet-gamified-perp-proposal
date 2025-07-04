import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/datasources/starknet_api.dart';

void main() {
  final api = StarknetApi();

  group('Starknet API Diagnostics', () {
    test('Test basic connectivity and supported methods', () async {
      print('\n🔍 Testing basic connectivity...');
      final connectivity = await api.testConnectivity();

      for (final entry in connectivity.entries) {
        print('${entry.key}: ${entry.value}');
      }
    });

    test('Get list of supported methods', () async {
      print('\n📋 Testing supported methods...');
      final supported = await api.getSupportedMethods();

      print('\n✅ Supported methods:');
      for (final entry in supported.entries) {
        if (entry.value) {
          print('  - ${entry.key}');
        }
      }

      print('\n❌ Unsupported methods:');
      for (final entry in supported.entries) {
        if (!entry.value) {
          print('  - ${entry.key}');
        }
      }
    });

    test('Smart block query with fallback strategies', () async {
      print(
        '\n🧠 Testing smart block query with multiple parameter formats...',
      );

      // Test with latest tag
      print('\n--- Testing with "latest" tag ---');
      final latestResult = await api.getBlockWithFallback(blockTag: 'latest');
      if (latestResult != null) {
        print('✅ Success with latest tag!');
      } else {
        print('❌ All latest tag formats failed');
      }

      // Test with block number
      print('\n--- Testing with block number 170000 ---');
      final blockNumberResult = await api.getBlockWithFallback(
        blockNumber: 170000,
      );
      if (blockNumberResult != null) {
        print('✅ Success with block number!');
      } else {
        print('❌ All block number formats failed');
      }

      // Test with block hash
      print('\n--- Testing with block hash ---');
      final blockHashResult = await api.getBlockWithFallback(
        blockHash:
            '0x06e58089d8e8f664823d26454f49a5a0f2ff697fe000000000000000000000000',
      );
      if (blockHashResult != null) {
        print('✅ Success with block hash!');
      } else {
        print('❌ All block hash formats failed');
      }
    });

    test('Test alternative methods for block data', () async {
      print('\n🔄 Testing alternative block methods...');

      final alternativeMethods = [
        'starknet_getBlockWithTxHashes',
        'starknet_getBlockWithReceipts',
        'starknet_getBlockTransactionCount',
      ];

      for (final method in alternativeMethods) {
        print('\n--- Testing $method ---');
        try {
          // Try with latest tag
          final result = await api.postRpc(
            method,
            params: [
              {'block_id': 'latest'},
            ],
          );
          print('✅ $method with "latest": ${result.containsKey('result')}');
        } catch (e) {
          print('❌ $method with "latest": $e');
        }

        try {
          // Try with block number
          final result = await api.postRpc(
            method,
            params: [
              {'block_id': 170000},
            ],
          );
          print('✅ $method with block number: ${result.containsKey('result')}');
        } catch (e) {
          print('❌ $method with block number: $e');
        }
      }
    });

    test('Test all endpoints for starknet_getBlockWithTxs', () async {
      print('\n🌐 Testing all endpoints for starknet_getBlockWithTxs...');
      final results = await api.testAllEndpoints(
        'starknet_getBlockWithTxs',
        params: [
          {'block_id': 'latest'},
        ],
      );

      for (final entry in results.entries) {
        print('\n--- ${entry.key} ---');
        print('Result: ${entry.value}');
      }
    });
  });
}
