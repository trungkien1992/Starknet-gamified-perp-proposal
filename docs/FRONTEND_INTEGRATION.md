# Frontend Integration Guide

## Overview

This guide covers integrating the Flutter frontend with Starknet smart contracts, including wallet connections, transaction signing, and state management.

## 🏗️ Architecture

### Flutter-Starknet Integration

```
Flutter App
├── UI Layer (Widgets)
├── State Management (Providers/Riverpod)
├── Business Logic (Use Cases)
├── Data Layer (Repositories)
└── Starknet Integration
    ├── Wallet Connection
    ├── Contract Interaction
    ├── Transaction Signing
    └── Event Listening
```

### Key Components

- **Wallet Provider**: Manages wallet connections and account state
- **Contract Client**: Handles contract interactions
- **Transaction Manager**: Manages transaction signing and confirmation
- **State Management**: Manages application state and UI updates

## 🔌 Wallet Integration

### Wallet Provider Setup

```dart
// lib/features/trade/providers/wallet_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starknet_flutter/starknet_flutter.dart';

class WalletState {
  final bool isConnected;
  final String? address;
  final String? balance;
  final bool isLoading;
  final String? error;

  WalletState({
    this.isConnected = false,
    this.address,
    this.balance,
    this.isLoading = false,
    this.error,
  });

  WalletState copyWith({
    bool? isConnected,
    String? address,
    String? balance,
    bool? isLoading,
    String? error,
  }) {
    return WalletState(
      isConnected: isConnected ?? this.isConnected,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final StarknetClient _client;

  WalletNotifier(this._client) : super(WalletState());

  Future<void> connectWallet() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Connect to wallet (ArgentX, Braavos, etc.)
      final account = await _client.connectWallet();
      
      // Get account details
      final address = account.address;
      final balance = await _client.getBalance(address);

      state = state.copyWith(
        isConnected: true,
        address: address,
        balance: balance.toString(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> disconnectWallet() async {
    await _client.disconnectWallet();
    state = WalletState();
  }

  Future<void> refreshBalance() async {
    if (state.address != null) {
      final balance = await _client.getBalance(state.address!);
      state = state.copyWith(balance: balance.toString());
    }
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  final client = ref.watch(starknetClientProvider);
  return WalletNotifier(client);
});
```

### Wallet Connection UI

```dart
// lib/features/trade/ui/widgets/wallet_connection.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletConnectionWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletProvider);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wallet Connection',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            
            if (walletState.isLoading)
              CircularProgressIndicator()
            else if (walletState.isConnected)
              _buildConnectedState(context, ref, walletState)
            else
              _buildDisconnectedState(context, ref),
            
            if (walletState.error != null)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  walletState.error!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedState(BuildContext context, WidgetRef ref, WalletState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Connected: ${state.address}'),
        Text('Balance: ${state.balance} ETH'),
        SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => ref.read(walletProvider.notifier).refreshBalance(),
              child: Text('Refresh'),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => ref.read(walletProvider.notifier).disconnectWallet(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Disconnect'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDisconnectedState(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => ref.read(walletProvider.notifier).connectWallet(),
      child: Text('Connect Wallet'),
    );
  }
}
```

## 📜 Contract Integration

### Contract Client Setup

```dart
// lib/data/datasources/starknet_client.dart
import 'package:starknet_flutter/starknet_flutter.dart';

class StarknetClient {
  final String rpcUrl;
  final String? contractAddress;

  StarknetClient({
    required this.rpcUrl,
    this.contractAddress,
  });

  // Contract interaction methods
  Future<String> mintNFT(String recipient, int tokenId) async {
    try {
      final result = await _invokeContract(
        function: 'mint',
        calldata: [recipient, tokenId.toString()],
      );
      return result;
    } catch (e) {
      throw ContractException('Failed to mint NFT: $e');
    }
  }

  Future<String> getTokenURI(int tokenId) async {
    try {
      final result = await _callContract(
        function: 'token_uri',
        calldata: [tokenId.toString()],
      );
      return result;
    } catch (e) {
      throw ContractException('Failed to get token URI: $e');
    }
  }

  Future<String> getBalance(String address) async {
    try {
      final result = await _callContract(
        function: 'balance_of',
        calldata: [address],
      );
      return result;
    } catch (e) {
      throw ContractException('Failed to get balance: $e');
    }
  }

  Future<String> _invokeContract({
    required String function,
    required List<String> calldata,
  }) async {
    // Implement contract invocation
    // This would use the actual Starknet SDK
    throw UnimplementedError('Contract invocation not implemented');
  }

  Future<String> _callContract({
    required String function,
    required List<String> calldata,
  }) async {
    // Implement contract calls
    // This would use the actual Starknet SDK
    throw UnimplementedError('Contract calls not implemented');
  }
}

class ContractException implements Exception {
  final String message;
  ContractException(this.message);
  
  @override
  String toString() => message;
}
```

### Contract Repository

```dart
// lib/data/repositories_impl/trade_repository_impl.dart
import 'package:starknet_flutter/starknet_flutter.dart';

class TradeRepositoryImpl implements TradeRepository {
  final StarknetClient _client;

  TradeRepositoryImpl(this._client);

  @override
  Future<String> mintNFT(String recipient, int tokenId) async {
    return await _client.mintNFT(recipient, tokenId);
  }

  @override
  Future<String> getTokenURI(int tokenId) async {
    return await _client.getTokenURI(tokenId);
  }

  @override
  Future<String> getBalance(String address) async {
    return await _client.getBalance(address);
  }
}
```

## 🎮 Game Integration

### Player Movement Use Case

```dart
// lib/domain/use_cases/move_player_use_case.dart
import 'package:starknet_flutter/starknet_flutter.dart';

class MovePlayerUseCase {
  final TradeRepository _repository;

  MovePlayerUseCase(this._repository);

  Future<MoveResult> execute(MoveParams params) async {
    try {
      // Validate move parameters
      _validateMove(params);

      // Execute move on contract
      final transactionHash = await _repository.executeMove(
        player: params.player,
        direction: params.direction,
        amount: params.amount,
      );

      // Wait for transaction confirmation
      final confirmation = await _repository.waitForConfirmation(transactionHash);

      return MoveResult.success(
        transactionHash: transactionHash,
        confirmation: confirmation,
      );
    } catch (e) {
      return MoveResult.failure(error: e.toString());
    }
  }

  void _validateMove(MoveParams params) {
    if (params.amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }
    
    if (params.direction < 0 || params.direction > 3) {
      throw ArgumentError('Invalid direction');
    }
  }
}

class MoveParams {
  final String player;
  final int direction;
  final double amount;

  MoveParams({
    required this.player,
    required this.direction,
    required this.amount,
  });
}

class MoveResult {
  final bool isSuccess;
  final String? transactionHash;
  final String? confirmation;
  final String? error;

  MoveResult.success({
    required this.transactionHash,
    required this.confirmation,
  }) : isSuccess = true, error = null;

  MoveResult.failure({required this.error})
      : isSuccess = false, transactionHash = null, confirmation = null;
}
```

## 🧭 Navigation & Routing (2024 Update)

The app uses [GoRouter](https://pub.dev/packages/go_router) for declarative navigation. All routes are defined centrally in `lib/app/routing/app_router.dart`.

**Main routes:**
- `/` (Tutorial or Onboarding)
- `/arena` (Trade Arena)
- `/drip` (Drip Inventory)
- `/profile` (Player Profile)
- `/streaks` (Streak Progression)
- `/reward` (Reward Screen)

**Login-based redirect:**
- If the user is not connected (wallet not connected), all protected routes redirect to `/`.
- This is handled in the GoRouter `redirect` callback, which checks `walletProvider.isConnected`.

**Navigation links:**
- The Trade Arena header includes icon buttons to `/drip` and `/streaks` for quick access.
- Use `context.go('/drip')` or `context.go('/streaks')` for navigation in code.

---

## 🏆 XP Flow & State Management

- **XPNotifier**: A `StateNotifier<int>` manages XP state, with `addXP` and `resetXP` methods.
- **XP increments**: Each successful move or trade increments XP (see `SwipeBar` logic).
- **Visual feedback**: XP is displayed in the Trade Arena header.

---

## 🧪 Testing

### Widget Tests

A widget test verifies navigation and login-based redirect:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/routing/app_router.dart';
import 'package:frontend/features/trade/providers/wallet_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class TestWalletNotifier extends WalletNotifier {
  TestWalletNotifier() : super(_DummyRef());
}
class _DummyRef implements Ref {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('GoRouter navigation and login redirect', (WidgetTester tester) async {
    final walletNotifier = TestWalletNotifier();
    final container = ProviderContainer(overrides: [
      walletProvider.overrideWith((ref) => walletNotifier),
    ]);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    appRouter.go('/drip');
    await tester.pumpAndSettle();
    expect(find.text('Tutorial Screen'), findsOneWidget);
    walletNotifier.state = walletNotifier.state.copyWith(isConnected: true);
    appRouter.go('/drip');
    await tester.pumpAndSettle();
    expect(find.text('Drip Screen'), findsOneWidget);
    appRouter.go('/streaks');
    await tester.pumpAndSettle();
    expect(find.text('Streak Screen'), findsOneWidget);
  });
}
```

### Integration Tests

```dart
// test/integration/wallet_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Wallet Integration Tests', () {
    testWidgets('should connect to wallet and display balance', (tester) async {
      // Start the app
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Tap connect wallet button
      await tester.tap(find.byKey(Key('connect-wallet')));
      await tester.pumpAndSettle();

      // Verify wallet connection
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('Balance:'), findsOneWidget);

      // Verify wallet address is displayed
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('should execute trade transaction', (tester) async {
      // Setup connected wallet
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Connect wallet first
      await tester.tap(find.byKey(Key('connect-wallet')));
      await tester.pumpAndSettle();

      // Execute trade
      await tester.tap(find.byKey(Key('execute-trade')));
      await tester.pumpAndSettle();

      // Verify transaction result
      expect(find.text('Transaction successful'), findsOneWidget);
    });
  });
}
```

## 🔧 Configuration

### Environment Setup

```dart
// lib/core/config/environment.dart
class Environment {
  static const String starknetRpcUrl = String.fromEnvironment(
    'STARKNET_RPC_URL',
    defaultValue: 'http://localhost:5050',
  );

  static const String contractAddress = String.fromEnvironment(
    'CONTRACT_ADDRESS',
    defaultValue: '',
  );

  static const bool isDevelopment = bool.fromEnvironment(
    'IS_DEVELOPMENT',
    defaultValue: true,
  );
}
```

### Dependency Injection

```dart
// lib/app/di/di.dart
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Register Starknet client
  getIt.registerLazySingleton<StarknetClient>(
    () => StarknetClient(
      rpcUrl: Environment.starknetRpcUrl,
      contractAddress: Environment.contractAddress,
    ),
  );

  // Register repositories
  getIt.registerLazySingleton<TradeRepository>(
    () => TradeRepositoryImpl(getIt<StarknetClient>()),
  );

  // Register use cases
  getIt.registerLazySingleton<MovePlayerUseCase>(
    () => MovePlayerUseCase(getIt<TradeRepository>()),
  );
}
```

## 🚨 Error Handling

### Error Types

```dart
enum StarknetErrorType {
  walletConnectionFailed,
  contractCallFailed,
  transactionFailed,
  insufficientBalance,
  networkError,
  unknown,
}

class StarknetError implements Exception {
  final StarknetErrorType type;
  final String message;
  final String? details;

  StarknetError({
    required this.type,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'StarknetError($type): $message${details != null ? ' - $details' : ''}';
}
```

### Error Handling in UI

```dart
class ErrorHandler {
  static String getUserFriendlyMessage(StarknetError error) {
    switch (error.type) {
      case StarknetErrorType.walletConnectionFailed:
        return 'Failed to connect wallet. Please try again.';
      case StarknetErrorType.contractCallFailed:
        return 'Contract call failed. Please check your connection.';
      case StarknetErrorType.transactionFailed:
        return 'Transaction failed. Please check your balance and try again.';
      case StarknetErrorType.insufficientBalance:
        return 'Insufficient balance for this transaction.';
      case StarknetErrorType.networkError:
        return 'Network error. Please check your internet connection.';
      case StarknetErrorType.unknown:
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
```

## 📱 UI Components

### Trade Screen

```dart
// lib/features/trade/ui/trade_screen.dart
class TradeScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends ConsumerState<TradeScreen> {
  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final tradeState = ref.watch(tradeProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Trade')),
      body: Column(
        children: [
          WalletConnectionWidget(),
          if (walletState.isConnected) ...[
            TradeFormWidget(),
            TradeHistoryWidget(),
          ] else
            Center(
              child: Text('Please connect your wallet to start trading'),
            ),
        ],
      ),
    );
  }
}
```

### Swipe Bar Widget

```dart
// lib/features/trade/ui/widgets/swipe_bar.dart
class SwipeBar extends StatefulWidget {
  final Function(double) onSwipe;
  final double minValue;
  final double maxValue;
  final double initialValue;

  SwipeBar({
    required this.onSwipe,
    this.minValue = 0.0,
    this.maxValue = 100.0,
    this.initialValue = 50.0,
  });

  @override
  State<SwipeBar> createState() => _SwipeBarState();
}

class _SwipeBarState extends State<SwipeBar> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _currentValue = (_currentValue + details.delta.dx).clamp(
            widget.minValue,
            widget.maxValue,
          );
        });
        widget.onSwipe(_currentValue);
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Stack(
          children: [
            Positioned(
              left: (_currentValue - widget.minValue) /
                  (widget.maxValue - widget.minValue) *
                  (MediaQuery.of(context).size.width - 80),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.drag_handle, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 🔄 State Management

### Trade State

```dart
// lib/features/trade/state/trade_state.dart
class TradeState {
  final bool isLoading;
  final String? error;
  final List<Trade> trades;
  final double currentPosition;
  final String? lastTransactionHash;

  TradeState({
    this.isLoading = false,
    this.error,
    this.trades = const [],
    this.currentPosition = 0.0,
    this.lastTransactionHash,
  });

  TradeState copyWith({
    bool? isLoading,
    String? error,
    List<Trade>? trades,
    double? currentPosition,
    String? lastTransactionHash,
  }) {
    return TradeState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      trades: trades ?? this.trades,
      currentPosition: currentPosition ?? this.currentPosition,
      lastTransactionHash: lastTransactionHash ?? this.lastTransactionHash,
    );
  }
}

class Trade {
  final String id;
  final double amount;
  final String direction;
  final DateTime timestamp;
  final String transactionHash;

  Trade({
    required this.id,
    required this.amount,
    required this.direction,
    required this.timestamp,
    required this.transactionHash,
  });
}
```

## 📊 Performance Optimization

### Caching Strategy

```dart
class CacheManager {
  static final Map<String, dynamic> _cache = {};
  static const Duration _defaultExpiry = Duration(minutes: 5);

  static T? get<T>(String key) {
    final item = _cache[key];
    if (item != null && item['expiry'].isAfter(DateTime.now())) {
      return item['data'] as T;
    }
    _cache.remove(key);
    return null;
  }

  static void set<T>(String key, T data, {Duration? expiry}) {
    _cache[key] = {
      'data': data,
      'expiry': DateTime.now().add(expiry ?? _defaultExpiry),
    };
  }

  static void clear() {
    _cache.clear();
  }
}
```

### Lazy Loading

```dart
class LazyTradeList extends StatefulWidget {
  @override
  State<LazyTradeList> createState() => _LazyTradeListState();
}

class _LazyTradeListState extends State<LazyTradeList> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreTrades();
    }
  }

  Future<void> _loadMoreTrades() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Load more trades
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: trades.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == trades.length) {
          return Center(child: CircularProgressIndicator());
        }
        return TradeListItem(trade: trades[index]);
      },
    );
  }
}
```

## 🔒 Security Considerations

### Input Validation

```dart
class InputValidator {
  static String? validateAmount(String amount) {
    if (amount.isEmpty) {
      return 'Amount is required';
    }

    final double? value = double.tryParse(amount);
    if (value == null) {
      return 'Invalid amount format';
    }

    if (value <= 0) {
      return 'Amount must be positive';
    }

    if (value > 1000000) {
      return 'Amount too large';
    }

    return null;
  }

  static String? validateAddress(String address) {
    if (address.isEmpty) {
      return 'Address is required';
    }

    if (!address.startsWith('0x')) {
      return 'Invalid address format';
    }

    if (address.length != 66) {
      return 'Invalid address length';
    }

    return null;
  }
}
```

### Secure Storage

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> savePrivateKey(String privateKey) async {
    await _storage.write(key: 'private_key', value: privateKey);
  }

  static Future<String?> getPrivateKey() async {
    return await _storage.read(key: 'private_key');
  }

  static Future<void> clearPrivateKey() async {
    await _storage.delete(key: 'private_key');
  }
}
```

## 📚 Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Starknet Flutter SDK](https://github.com/NethermindEth/starknet-flutter)
- [Riverpod Documentation](https://riverpod.dev/)
- [Flutter Testing Guide](https://flutter.dev/docs/testing) 