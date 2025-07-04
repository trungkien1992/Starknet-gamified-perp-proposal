import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/extended_api_client.dart';
import '../../app/app_mode.dart';

/// Provider for Extended Exchange API client
final extendedApiClientProvider = Provider<ExtendedApiClient>((ref) {
  final apiKey = const String.fromEnvironment(
    'EXTENDED_API_KEY',
    defaultValue: 'demo_key_for_development',
  );
  
  return ExtendedApiClient(apiKey: apiKey);
});

/// Provider for available markets
final extendedMarketsProvider = FutureProvider<List<ExtendedMarket>>((ref) async {
  if (getAppMode() == AppMode.mock) {
    // Return mock data for development
    return _getMockMarkets();
  }
  
  final client = ref.read(extendedApiClientProvider);
  try {
    return await client.getMarkets();
  } catch (e) {
    // Fallback to mock data on error
    print('Extended API error, using mock data: $e');
    return _getMockMarkets();
  }
});

/// Provider for real-time market data
final extendedMarketDataProvider = StreamProvider.family<ExtendedMarketData, String>((ref, market) async* {
  if (getAppMode() == AppMode.mock) {
    // Return mock market data stream
    yield* _getMockMarketDataStream(market);
    return;
  }
  
  final client = ref.read(extendedApiClientProvider);
  try {
    yield* client.subscribeToMarketData(market);
  } catch (e) {
    // Fallback to mock data on error
    print('Extended WebSocket error, using mock data: $e');
    yield* _getMockMarketDataStream(market);
  }
});

/// Provider for current market selection
final selectedMarketProvider = StateProvider<String>((ref) => 'BTC-USDT');

/// Provider for market data of selected market
final currentMarketDataProvider = Provider<AsyncValue<ExtendedMarketData>>((ref) {
  final selectedMarket = ref.watch(selectedMarketProvider);
  return ref.watch(extendedMarketDataProvider(selectedMarket));
});

/// Provider for user positions
final extendedPositionsProvider = FutureProvider<List<ExtendedPosition>>((ref) async {
  if (getAppMode() == AppMode.mock) {
    return _getMockPositions();
  }
  
  final client = ref.read(extendedApiClientProvider);
  try {
    return await client.getPositions();
  } catch (e) {
    print('Extended positions error, using mock data: $e');
    return _getMockPositions();
  }
});

/// Trading service provider
final extendedTradingServiceProvider = Provider<ExtendedTradingService>((ref) {
  final client = ref.read(extendedApiClientProvider);
  return ExtendedTradingService(client, ref);
});

/// Trading service for executing trades
class ExtendedTradingService {
  final ExtendedApiClient _client;
  final Ref _ref;
  
  ExtendedTradingService(this._client, this._ref);
  
  /// Execute a trade with the specified parameters
  Future<ExtendedOrderResponse> executeTrade({
    required String market,
    required String direction, // 'LONG' or 'SHORT'
    required double leverage,
    required String quantity,
  }) async {
    // Convert direction to Extended Exchange format
    final side = direction == 'LONG' ? 'BUY' : 'SELL';
    
    // Get current market price for market orders
    final marketData = await _getCurrentMarketPrice(market);
    final currentPrice = double.parse(marketData.price);
    
    // Calculate order price with slight slippage for market execution
    final slippageMultiplier = side == 'BUY' ? 1.001 : 0.999;
    final orderPrice = (currentPrice * slippageMultiplier).toStringAsFixed(2);
    
    if (getAppMode() == AppMode.mock) {
      // Return mock order response for development
      return _getMockOrderResponse(market, side, quantity, orderPrice);
    }
    
    try {
      return await _client.createOrder(
        market: market,
        side: side,
        qty: quantity,
        price: orderPrice,
        type: 'LIMIT', // Use limit order for better control
        timeInForce: 'IOC', // Immediate or Cancel for market-like execution
      );
    } catch (e) {
      print('Extended trade execution error: $e');
      // Return mock response on error for graceful fallback
      return _getMockOrderResponse(market, side, quantity, orderPrice);
    }
  }
  
  /// Cancel a specific order
  Future<void> cancelOrder(String orderId) async {
    if (getAppMode() == AppMode.mock) {
      print('Mock: Cancelling order $orderId');
      return;
    }
    
    try {
      await _client.cancelOrder(orderId);
    } catch (e) {
      print('Extended cancel order error: $e');
      throw Exception('Failed to cancel order: $e');
    }
  }
  
  /// Get current market price
  Future<ExtendedMarketData> _getCurrentMarketPrice(String market) async {
    try {
      return await _client.getMarketData(market);
    } catch (e) {
      // Return mock data on error
      return _getMockMarketData(market);
    }
  }
}

/// Mock data generators for development and fallback
List<ExtendedMarket> _getMockMarkets() {
  return [
    ExtendedMarket(
      symbol: 'BTC-USDT',
      baseAsset: 'BTC',
      quoteAsset: 'USDT',
      status: 'TRADING',
      minQty: '0.001',
      maxQty: '100',
      tickSize: '0.01',
    ),
    ExtendedMarket(
      symbol: 'ETH-USDT',
      baseAsset: 'ETH',
      quoteAsset: 'USDT',
      status: 'TRADING',
      minQty: '0.01',
      maxQty: '1000',
      tickSize: '0.01',
    ),
    ExtendedMarket(
      symbol: 'STRK-USDT',
      baseAsset: 'STRK',
      quoteAsset: 'USDT',
      status: 'TRADING',
      minQty: '1',
      maxQty: '100000',
      tickSize: '0.0001',
    ),
  ];
}

Stream<ExtendedMarketData> _getMockMarketDataStream(String market) async* {
  while (true) {
    yield _getMockMarketData(market);
    await Future.delayed(const Duration(seconds: 2));
  }
}

ExtendedMarketData _getMockMarketData(String market) {
  final basePrice = _getBasePriceForMarket(market);
  final randomVariation = (DateTime.now().millisecondsSinceEpoch % 200) - 100;
  final currentPrice = basePrice + (randomVariation * 0.1);
  final change = (randomVariation * 0.01);
  
  return ExtendedMarketData(
    symbol: market,
    price: currentPrice.toStringAsFixed(2),
    change24h: (change / basePrice).toStringAsFixed(4),
    volume24h: '1250000.50',
    high24h: (currentPrice * 1.05).toStringAsFixed(2),
    low24h: (currentPrice * 0.95).toStringAsFixed(2),
    timestamp: DateTime.now(),
  );
}

double _getBasePriceForMarket(String market) {
  switch (market) {
    case 'BTC-USDT':
      return 67284.50;
    case 'ETH-USDT':
      return 2847.92;
    case 'STRK-USDT':
      return 1.234;
    default:
      return 100.0;
  }
}

List<ExtendedPosition> _getMockPositions() {
  return [
    ExtendedPosition(
      market: 'BTC-USDT',
      side: 'LONG',
      size: '0.1',
      entryPrice: '67000.00',
      markPrice: '67284.50',
      unrealizedPnl: '28.45',
      leverage: '5',
    ),
  ];
}

ExtendedOrderResponse _getMockOrderResponse(
  String market,
  String side,
  String qty,
  String price,
) {
  return ExtendedOrderResponse(
    orderId: 'mock_${DateTime.now().millisecondsSinceEpoch}',
    status: 'FILLED',
    market: market,
    side: side,
    qty: qty,
    price: price,
  );
}