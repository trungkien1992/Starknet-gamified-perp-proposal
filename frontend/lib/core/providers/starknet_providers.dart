import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Core Starknet blockchain interaction providers
/// Separated from feature-specific providers for better organization

/// A provider to fetch the latest block number from Starknet.
/// Uses autoDispose for memory efficiency when not in use.
final latestBlockProvider = FutureProvider.autoDispose<int>((ref) async {
  // TODO: Implement real Starknet API integration
  await Future.delayed(const Duration(seconds: 1));
  return 12345; // Mock block number
});

/// A provider to test Starknet connection health.
/// Useful for connection status indicators.
final starknetConnectionProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  // TODO: Implement real Starknet connection test
  await Future.delayed(const Duration(milliseconds: 500));
  return true; // Mock connection success
});

/// A provider to test contract reading capabilities.
/// This validates ABI handling and contract interaction patterns.
final contractReaderTestProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      // TODO: Implement real contract reading
      await Future.delayed(const Duration(milliseconds: 300));
      return {
        'balance': '1000',
        'owner': '0x1234567890123456789012345678901234567890',
      };
    });

/// Enhanced block information provider.
/// Demonstrates full RPC capabilities with detailed block data.
final blockInfoProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  // TODO: Implement real block info fetching
  await Future.delayed(const Duration(milliseconds: 200));
  return {
    'blockNumber': 12345,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'transactions': 50,
  };
});

/// Connection status provider with error handling
/// Uses AsyncValue for proper loading/error states
final connectionStatusProvider = FutureProvider.autoDispose<AsyncValue<bool>>((
  ref,
) async {
  try {
    final isConnected = await ref.watch(starknetConnectionProvider.future);
    return AsyncValue.data(isConnected);
  } catch (error, stackTrace) {
    return AsyncValue.error(error, stackTrace);
  }
});
