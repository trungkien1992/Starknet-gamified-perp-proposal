import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/starknet_client.dart';
import '../../data/datasources/mock_starknet_client.dart';
import '../../app/di.dart';

class MovePlayerUseCase {
  final IStarknetClient client; // Accepts either real or mock client
  MovePlayerUseCase(this.client);

  Future<String> call({required int x, required int y}) async {
    // For mock: just return a fake result
    if (client is MockStarknetClient) {
      return await client.executeTrade(direction: 'LONG', leverage: 1.0);
    }
    // For real: call the real method (replace with actual logic)
    return await client.executeTrade(direction: 'LONG', leverage: 1.0);
  }
}

final movePlayerUseCaseProvider = Provider<MovePlayerUseCase>((ref) {
  final client = ref.watch(starknetClientProvider);
  return MovePlayerUseCase(client);
});
