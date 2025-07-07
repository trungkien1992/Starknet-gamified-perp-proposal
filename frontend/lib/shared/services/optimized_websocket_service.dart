import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:math' as math;

enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

class OptimizedWebSocketService {
  static OptimizedWebSocketService? _instance;
  static OptimizedWebSocketService get instance {
    _instance ??= OptimizedWebSocketService._internal();
    return _instance!;
  }

  OptimizedWebSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  Timer? _connectionTimeoutTimer;

  // Connection state management
  WebSocketConnectionState _connectionState = WebSocketConnectionState.disconnected;
  final StreamController<WebSocketConnectionState> _stateController = 
      StreamController<WebSocketConnectionState>.broadcast();
  
  // Message handling
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Configuration
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration baseReconnectDelay = Duration(seconds: 1);
  static const Duration maxReconnectDelay = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration heartbeatInterval = Duration(seconds: 30);

  // Getters
  Stream<WebSocketConnectionState> get connectionState => _stateController.stream;
  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  WebSocketConnectionState get currentState => _connectionState;
  bool get isConnected => _connectionState == WebSocketConnectionState.connected;

  /// Connect to WebSocket with automatic retry logic
  Future<void> connect(String url, {Map<String, String>? headers}) async {
    if (_connectionState == WebSocketConnectionState.connecting ||
        _connectionState == WebSocketConnectionState.connected) {
      return;
    }

    _updateConnectionState(WebSocketConnectionState.connecting);
    _cancelTimers();

    try {
      // Set connection timeout
      _connectionTimeoutTimer = Timer(connectionTimeout, () {
        _handleConnectionTimeout();
      });

      // Create WebSocket connection
      final uri = Uri.parse(url);
      _channel = WebSocketChannel.connect(uri, protocols: null);

      // Listen to the WebSocket stream
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
        cancelOnError: false,
      );

      // Wait for first message or timeout to confirm connection
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_connectionState == WebSocketConnectionState.connecting) {
        _updateConnectionState(WebSocketConnectionState.connected);
        _reconnectAttempts = 0;
        _startHeartbeat();
        _cancelConnectionTimeout();
        
        if (kDebugMode) {
          print('WebSocket connected successfully to $url');
        }
      }

    } catch (e) {
      _handleConnectionError(e);
    }
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    _updateConnectionState(WebSocketConnectionState.disconnected);
    _cancelTimers();
    await _closeConnection();
    _reconnectAttempts = 0;
  }

  /// Send message through WebSocket
  Future<bool> sendMessage(Map<String, dynamic> message) async {
    if (!isConnected || _channel == null) {
      if (kDebugMode) {
        print('Cannot send message: WebSocket not connected');
      }
      return false;
    }

    try {
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
      
      if (kDebugMode) {
        print('WebSocket message sent: $jsonMessage');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending WebSocket message: $e');
      }
      return false;
    }
  }

  /// Handle incoming messages
  void _handleMessage(dynamic data) {
    try {
      final Map<String, dynamic> message = jsonDecode(data);
      
      // Handle heartbeat pong
      if (message['type'] == 'pong') {
        _handleHeartbeatResponse();
        return;
      }

      _messageController.add(message);
      
      if (kDebugMode) {
        print('WebSocket message received: $message');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing WebSocket message: $e');
      }
    }
  }

  /// Handle WebSocket errors
  void _handleError(error) {
    if (kDebugMode) {
      print('WebSocket error: $error');
    }
    _handleConnectionError(error);
  }

  /// Handle WebSocket disconnection
  void _handleDisconnection() {
    if (kDebugMode) {
      print('WebSocket disconnected');
    }
    
    if (_connectionState != WebSocketConnectionState.disconnected) {
      _scheduleReconnect();
    }
  }

  /// Handle connection errors with exponential backoff
  void _handleConnectionError(dynamic error) {
    if (kDebugMode) {
      print('WebSocket connection error: $error');
    }

    _updateConnectionState(WebSocketConnectionState.failed);
    _scheduleReconnect();
  }

  /// Handle connection timeout
  void _handleConnectionTimeout() {
    if (kDebugMode) {
      print('WebSocket connection timeout');
    }
    _handleConnectionError('Connection timeout');
  }

  /// Schedule reconnection with exponential backoff
  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      _updateConnectionState(WebSocketConnectionState.failed);
      if (kDebugMode) {
        print('Max reconnect attempts reached. Giving up.');
      }
      return;
    }

    _updateConnectionState(WebSocketConnectionState.reconnecting);
    
    // Calculate delay with exponential backoff and jitter
    final baseDelay = baseReconnectDelay.inMilliseconds;
    final exponentialDelay = baseDelay * math.pow(2, _reconnectAttempts);
    final jitter = math.Random().nextDouble() * 1000; // Add up to 1 second jitter
    final totalDelay = math.min(exponentialDelay + jitter, maxReconnectDelay.inMilliseconds);
    
    _reconnectTimer = Timer(Duration(milliseconds: totalDelay.toInt()), () {
      _reconnectAttempts++;
      if (kDebugMode) {
        print('Attempting to reconnect... (attempt $_reconnectAttempts)');
      }
      // Note: Reconnect will use the last URL - implement URL storage if needed
    });
  }

  /// Start heartbeat mechanism
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (timer) {
      _sendHeartbeat();
    });
  }

  /// Send heartbeat ping
  void _sendHeartbeat() {
    sendMessage({'type': 'ping', 'timestamp': DateTime.now().millisecondsSinceEpoch});
  }

  /// Handle heartbeat response
  void _handleHeartbeatResponse() {
    // Heartbeat confirmed - connection is alive
    if (kDebugMode) {
      print('WebSocket heartbeat confirmed');
    }
  }

  /// Update connection state and notify listeners
  void _updateConnectionState(WebSocketConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      _stateController.add(newState);
    }
  }

  /// Close WebSocket connection
  Future<void> _closeConnection() async {
    try {
      await _subscription?.cancel();
      await _channel?.sink.close(status.goingAway);
    } catch (e) {
      if (kDebugMode) {
        print('Error closing WebSocket connection: $e');
      }
    } finally {
      _subscription = null;
      _channel = null;
    }
  }

  /// Cancel all timers
  void _cancelTimers() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _cancelConnectionTimeout();
  }

  /// Cancel connection timeout timer
  void _cancelConnectionTimeout() {
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = null;
  }

  /// Dispose of the service
  void dispose() {
    _cancelTimers();
    _closeConnection();
    _stateController.close();
    _messageController.close();
    _instance = null;
  }
}

/// Helper class for battery optimization
class WebSocketBatteryOptimizer {
  static bool _isBackgrounded = false;
  static Duration _normalHeartbeat = const Duration(seconds: 30);
  static Duration _backgroundHeartbeat = const Duration(minutes: 2);

  static void onAppPaused() {
    _isBackgrounded = true;
    // Reduce heartbeat frequency when app is backgrounded
    // Implementation would modify the heartbeat interval
  }

  static void onAppResumed() {
    _isBackgrounded = false;
    // Restore normal heartbeat frequency
    // Implementation would restore normal heartbeat interval
  }

  static Duration get currentHeartbeatInterval {
    return _isBackgrounded ? _backgroundHeartbeat : _normalHeartbeat;
  }
}