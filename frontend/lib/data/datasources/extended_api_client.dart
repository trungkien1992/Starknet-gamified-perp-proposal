import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

/// Extended Exchange API client for perpetual futures trading
class ExtendedApiClient {
  final String _baseUrl;
  final String _apiKey;
  final String _wsUrl;
  late http.Client _httpClient;
  WebSocketChannel? _wsChannel;
  StreamController<ExtendedMarketData>? _marketDataController;

  ExtendedApiClient({
    required String apiKey,
    String baseUrl = 'https://api.extended.exchange',
    String wsUrl = 'wss://ws.extended.exchange',
  })  : _apiKey = apiKey,
        _baseUrl = baseUrl,
        _wsUrl = wsUrl {
    _httpClient = http.Client();
  }

  /// Headers for API requests
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Api-Key': _apiKey,
        'User-Agent': 'StreetCredClash/1.0.0',
      };

  /// Get market data for supported perpetual futures
  Future<List<ExtendedMarket>> getMarkets() async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/v1/markets'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((item) => ExtendedMarket.fromJson(item)).toList();
    } else {
      throw ExtendedApiException(
        'Failed to fetch markets: ${response.statusCode}',
        response.statusCode,
      );
    }
  }

  /// Get real-time market data for a specific market
  Future<ExtendedMarketData> getMarketData(String market) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/v1/markets/$market/stats'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return ExtendedMarketData.fromJson(data);
    } else {
      throw ExtendedApiException(
        'Failed to fetch market data: ${response.statusCode}',
        response.statusCode,
      );
    }
  }

  /// Get order book for a market
  Future<ExtendedOrderBook> getOrderBook(String market) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/v1/markets/$market/orderbook'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return ExtendedOrderBook.fromJson(data);
    } else {
      throw ExtendedApiException(
        'Failed to fetch order book: ${response.statusCode}',
        response.statusCode,
      );
    }
  }

  /// Get recent trades for a market
  Future<List<ExtendedTrade>> getRecentTrades(String market) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/v1/markets/$market/trades'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((item) => ExtendedTrade.fromJson(item)).toList();
    } else {
      throw ExtendedApiException(
        'Failed to fetch trades: ${response.statusCode}',
        response.statusCode,
      );
    }
  }

  /// Create a new order (requires StarkKey signature in production)
  Future<ExtendedOrderResponse> createOrder({
    required String market,
    required String side, // 'BUY' or 'SELL'
    required String qty,
    required String price,
    String type = 'LIMIT',
    String? timeInForce = 'GTC',
    bool reduceOnly = false,
  }) async {
    final orderData = {
      'market': market,
      'type': type,
      'side': side,
      'qty': qty,
      'price': price,
      'timeInForce': timeInForce,
      'reduceOnly': reduceOnly,
      'fee': '0.0002', // Standard fee
      'expiration': DateTime.now()
          .add(const Duration(hours: 24))
          .millisecondsSinceEpoch
          .toString(),
    };

    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/v1/orders'),
      headers: _headers,
      body: json.encode(orderData),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return ExtendedOrderResponse.fromJson(data);
    } else {
      throw ExtendedApiException(
        'Failed to create order: ${response.body}',
        response.statusCode,
      );
    }
  }

  /// Cancel an existing order
  Future<void> cancelOrder(String orderId) async {
    final response = await _httpClient.delete(
      Uri.parse('$_baseUrl/v1/orders/$orderId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw ExtendedApiException(
        'Failed to cancel order: ${response.body}',
        response.statusCode,
      );
    }
  }

  /// Get account positions
  Future<List<ExtendedPosition>> getPositions() async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/v1/positions'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((item) => ExtendedPosition.fromJson(item)).toList();
    } else {
      throw ExtendedApiException(
        'Failed to fetch positions: ${response.statusCode}',
        response.statusCode,
      );
    }
  }

  /// Subscribe to real-time market data via WebSocket
  Stream<ExtendedMarketData> subscribeToMarketData(String market) {
    _marketDataController ??= StreamController<ExtendedMarketData>.broadcast();

    _connectWebSocket();
    _subscribeToChannel('market_data:$market');

    return _marketDataController!.stream;
  }

  /// Connect to WebSocket
  void _connectWebSocket() {
    if (_wsChannel != null) return;

    _wsChannel = WebSocketChannel.connect(
      Uri.parse('$_wsUrl/v1/ws'),
    );

    _wsChannel!.stream.listen(
      (data) {
        try {
          final decoded = json.decode(data);
          if (decoded['type'] == 'market_data') {
            final marketData = ExtendedMarketData.fromJson(decoded['data']);
            _marketDataController?.add(marketData);
          }
        } catch (e) {
          print('WebSocket data parsing error: $e');
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
        _reconnectWebSocket();
      },
      onDone: () {
        print('WebSocket connection closed');
        _reconnectWebSocket();
      },
    );
  }

  /// Subscribe to a specific WebSocket channel
  void _subscribeToChannel(String channel) {
    if (_wsChannel != null) {
      final subscribeMessage = {
        'type': 'subscribe',
        'channel': channel,
      };
      _wsChannel!.sink.add(json.encode(subscribeMessage));
    }
  }

  /// Reconnect WebSocket with exponential backoff
  void _reconnectWebSocket() {
    _wsChannel = null;
    Timer(const Duration(seconds: 5), () {
      _connectWebSocket();
    });
  }

  /// Dispose resources
  void dispose() {
    _wsChannel?.sink.close(status.goingAway);
    _marketDataController?.close();
    _httpClient.close();
  }
}

/// Extended Exchange market information
class ExtendedMarket {
  final String symbol;
  final String baseAsset;
  final String quoteAsset;
  final String status;
  final String minQty;
  final String maxQty;
  final String tickSize;

  ExtendedMarket({
    required this.symbol,
    required this.baseAsset,
    required this.quoteAsset,
    required this.status,
    required this.minQty,
    required this.maxQty,
    required this.tickSize,
  });

  factory ExtendedMarket.fromJson(Map<String, dynamic> json) {
    return ExtendedMarket(
      symbol: json['symbol'] ?? '',
      baseAsset: json['baseAsset'] ?? '',
      quoteAsset: json['quoteAsset'] ?? '',
      status: json['status'] ?? '',
      minQty: json['minQty'] ?? '0',
      maxQty: json['maxQty'] ?? '0',
      tickSize: json['tickSize'] ?? '0',
    );
  }
}

/// Real-time market data
class ExtendedMarketData {
  final String symbol;
  final String price;
  final String change24h;
  final String volume24h;
  final String high24h;
  final String low24h;
  final DateTime timestamp;

  ExtendedMarketData({
    required this.symbol,
    required this.price,
    required this.change24h,
    required this.volume24h,
    required this.high24h,
    required this.low24h,
    required this.timestamp,
  });

  factory ExtendedMarketData.fromJson(Map<String, dynamic> json) {
    return ExtendedMarketData(
      symbol: json['symbol'] ?? '',
      price: json['price'] ?? '0',
      change24h: json['change24h'] ?? '0',
      volume24h: json['volume24h'] ?? '0',
      high24h: json['high24h'] ?? '0',
      low24h: json['low24h'] ?? '0',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  double get changePercent {
    try {
      return double.parse(change24h) * 100;
    } catch (e) {
      return 0.0;
    }
  }

  bool get isPositive => changePercent >= 0;
}

/// Order book data
class ExtendedOrderBook {
  final List<OrderBookEntry> bids;
  final List<OrderBookEntry> asks;
  final DateTime timestamp;

  ExtendedOrderBook({
    required this.bids,
    required this.asks,
    required this.timestamp,
  });

  factory ExtendedOrderBook.fromJson(Map<String, dynamic> json) {
    return ExtendedOrderBook(
      bids: (json['bids'] as List? ?? [])
          .map((item) => OrderBookEntry.fromJson(item))
          .toList(),
      asks: (json['asks'] as List? ?? [])
          .map((item) => OrderBookEntry.fromJson(item))
          .toList(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

class OrderBookEntry {
  final String price;
  final String quantity;

  OrderBookEntry({required this.price, required this.quantity});

  factory OrderBookEntry.fromJson(List<dynamic> json) {
    return OrderBookEntry(
      price: json[0]?.toString() ?? '0',
      quantity: json[1]?.toString() ?? '0',
    );
  }
}

/// Trade data
class ExtendedTrade {
  final String id;
  final String price;
  final String qty;
  final String side;
  final DateTime timestamp;

  ExtendedTrade({
    required this.id,
    required this.price,
    required this.qty,
    required this.side,
    required this.timestamp,
  });

  factory ExtendedTrade.fromJson(Map<String, dynamic> json) {
    return ExtendedTrade(
      id: json['id']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      qty: json['qty']?.toString() ?? '0',
      side: json['side']?.toString() ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

/// Order response
class ExtendedOrderResponse {
  final String orderId;
  final String status;
  final String market;
  final String side;
  final String qty;
  final String price;

  ExtendedOrderResponse({
    required this.orderId,
    required this.status,
    required this.market,
    required this.side,
    required this.qty,
    required this.price,
  });

  factory ExtendedOrderResponse.fromJson(Map<String, dynamic> json) {
    return ExtendedOrderResponse(
      orderId: json['orderId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      market: json['market']?.toString() ?? '',
      side: json['side']?.toString() ?? '',
      qty: json['qty']?.toString() ?? '0',
      price: json['price']?.toString() ?? '0',
    );
  }
}

/// Position data
class ExtendedPosition {
  final String market;
  final String side;
  final String size;
  final String entryPrice;
  final String markPrice;
  final String unrealizedPnl;
  final String leverage;

  ExtendedPosition({
    required this.market,
    required this.side,
    required this.size,
    required this.entryPrice,
    required this.markPrice,
    required this.unrealizedPnl,
    required this.leverage,
  });

  factory ExtendedPosition.fromJson(Map<String, dynamic> json) {
    return ExtendedPosition(
      market: json['market']?.toString() ?? '',
      side: json['side']?.toString() ?? '',
      size: json['size']?.toString() ?? '0',
      entryPrice: json['entryPrice']?.toString() ?? '0',
      markPrice: json['markPrice']?.toString() ?? '0',
      unrealizedPnl: json['unrealizedPnl']?.toString() ?? '0',
      leverage: json['leverage']?.toString() ?? '1',
    );
  }

  double get pnlPercent {
    try {
      final entryPriceNum = double.parse(entryPrice);
      final markPriceNum = double.parse(markPrice);
      if (entryPriceNum == 0) return 0.0;
      
      final change = (markPriceNum - entryPriceNum) / entryPriceNum;
      return side == 'LONG' ? change * 100 : -change * 100;
    } catch (e) {
      return 0.0;
    }
  }
}

/// Extended API Exception
class ExtendedApiException implements Exception {
  final String message;
  final int? statusCode;

  ExtendedApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ExtendedApiException: $message (status: $statusCode)';
}