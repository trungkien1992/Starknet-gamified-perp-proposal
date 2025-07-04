// File: frontend/lib/app/di.dart
//
// We update our dependency injection file to provide the Starknet client.
// NOTE: This file is now a combination of previous and new providers.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/data/datasources/graphql_client.dart';
import 'package:frontend/data/datasources/starknet_client.dart' as starknet;
import 'package:frontend/data/repositories_impl/trade_repository_impl.dart';
import 'package:frontend/domain/repositories/trade_repository.dart';
import 'package:frontend/domain/use_cases/move_player_use_case.dart';
import 'package:frontend/data/datasources/starknet_api.dart';
import 'package:frontend/data/datasources/mock_starknet_client.dart';
import 'app_mode.dart';
import '../features/drip/state/drip_provider.dart';

// --- DATA LAYER PROVIDERS ---

/// App-wide config for mock mode toggle
final mockModeProvider = Provider<bool>(
  (ref) => false,
); // Set to true for mock mode

final appModeProvider = Provider<AppMode>((ref) => getAppMode());

void printAppModeBanner(AppMode mode) {
  print('==============================');
  print('   APP MODE: ${mode.name.toUpperCase()}');
  print('==============================');
}

class MockStarknetContractReader extends starknet.StarknetContractReader {
  @override
  Future<int> getLatestBlockNumber() async => 42;
  @override
  Future<bool> isConnected() async => true;
  @override
  Future<Map<String, dynamic>> readContract({
    required String contractAddress,
    required String functionName,
    List<dynamic> calldata = const [],
  }) async => {'mock': true};
}

/// Provides the Starknet contract reader service, toggling between mock and real
final starknetContractReaderProvider =
    Provider<starknet.StarknetContractReader>((ref) {
      final mockMode = ref.watch(mockModeProvider);
      if (mockMode) {
        return MockStarknetContractReader();
      } else {
        return starknet.StarknetContractReader();
      }
    });

// final tradeRepositoryProvider = Provider<TradeRepository>((ref) {
//   return GraphQLTradeRepositoryImpl(client);
// });

// --- DOMAIN LAYER PROVIDERS (USE CASES) ---

final movePlayerUseCaseProvider = Provider<MovePlayerUseCase>((ref) {
  final client = ref.watch(starknetClientProvider);
  return MovePlayerUseCase(client);
});

// Provide a singleton StarknetApi instance
final starknetApiProvider = Provider<StarknetApi>((ref) {
  return StarknetApi();
});

final starknetClientProvider = Provider<starknet.IStarknetClient>((ref) {
  final mode = ref.watch(appModeProvider);
  printAppModeBanner(mode);
  if (mode == AppMode.mock) {
    return MockStarknetClient();
  } else {
    return starknet.StarknetClient();
  }
});

void logAppMode() {
  final mode = getAppMode();
  print('[Startup] Running in ${mode.name} mode');
}
