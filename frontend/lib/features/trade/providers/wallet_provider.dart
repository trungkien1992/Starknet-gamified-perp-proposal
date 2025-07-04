import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/extended_provider.dart';

/// StateNotifier for managing wallet connection state.
/// Replace mock logic with real wallet integration in production.
class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier(this.ref) : super(WalletState());
  final Ref ref;

  /// Connects to Starknet using Katana test account.
  /// Shows connection progress with realistic delay.
  Future<void> connect() async {
    // Set loading state
    ref.read(walletLoadingProvider.notifier).state = true;
    try {
      // Simulate connecting to Katana RPC
      await Future.delayed(const Duration(seconds: 2));

      // Use actual Katana test account from our running instance
      state = state.copyWith(
        address:
            '0x4e545931e54504eead01ed39a56d335ee7ea73e25b2da764731f06e931b186d',
        isConnected: true,
      );

      print('✅ Connected to Katana wallet: ${state.address}');
    } catch (e) {
      print('❌ Wallet connection failed: $e');
      // Handle connection errors gracefully
    } finally {
      ref.read(walletLoadingProvider.notifier).state = false;
    }
  }

  /// Disconnects the wallet and clears state.
  void disconnect() {
    state = WalletState();
    // TODO: Clear persisted wallet state if implemented
  }

  /// Executes a trade with the given direction and leverage using Extended Exchange.
  Future<void> executeTrade(String direction, double leverage, {String? market}) async {
    if (!state.isConnected) {
      throw Exception('Wallet not connected');
    }

    try {
      final tradingService = ref.read(extendedTradingServiceProvider);
      final selectedMarket = market ?? ref.read(selectedMarketProvider) ?? 'ETH-USD';
      
      // Calculate position size based on leverage (simplified for demo)
      final baseQuantity = leverage * 0.01; // Adjust based on account size
      
      print(
        'Executing $direction trade for $selectedMarket with ${leverage}x leverage',
      );

      // Execute trade through Extended Exchange
      final orderResponse = await tradingService.executeTrade(
        market: selectedMarket,
        direction: direction,
        leverage: leverage,
        quantity: baseQuantity.toStringAsFixed(6),
      );

      print('Trade executed successfully: Order ID ${orderResponse.orderId}');
      
      // TODO: Update local trade history
      // TODO: Emit game events for XP/rewards
      
    } catch (e) {
      print('Trade execution failed: $e');
      rethrow;
    }
  }
}

/// Wallet state class
class WalletState {
  final String? address;
  final bool isConnected;

  const WalletState({this.address, this.isConnected = false});

  WalletState copyWith({String? address, bool? isConnected}) {
    return WalletState(
      address: address ?? this.address,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

/// Provider for wallet connection state.
final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>(
  (ref) => WalletNotifier(ref),
);

/// Provider for wallet connection loading state.
final walletLoadingProvider = StateProvider<bool>((ref) => false);
