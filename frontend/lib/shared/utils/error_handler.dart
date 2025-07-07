import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

/// Centralized error handling system for the StreetCred Clash app
class ErrorHandler {
  static final List<AppError> _errorHistory = [];
  static const int maxErrorHistory = 100;

  /// Handle API-related errors
  static void handleApiError(Object error, StackTrace stackTrace, {BuildContext? context}) {
    final appError = _categorizeError(error, stackTrace);
    _logError(appError);
    _addToHistory(appError);
    
    if (context != null) {
      _showUserFriendlyError(context, appError);
    }
  }

  /// Handle trade execution errors specifically
  static void handleTradeError(Object error, StackTrace stackTrace, {BuildContext? context}) {
    final appError = TradeError(
      message: _getTradeErrorMessage(error),
      originalError: error,
      stackTrace: stackTrace,
    );
    
    _logError(appError);
    _addToHistory(appError);
    
    if (context != null) {
      _showTradeErrorDialog(context, appError);
    }
  }

  /// Handle WebSocket connection errors
  static void handleWebSocketError(Object error, StackTrace stackTrace) {
    final appError = NetworkError(
      message: 'Real-time connection issue: ${_getNetworkErrorMessage(error)}',
      code: 'WEBSOCKET_ERROR',
      originalError: error,
      stackTrace: stackTrace,
    );
    
    _logError(appError);
    _addToHistory(appError);
  }

  /// Handle validation errors
  static ValidationError handleValidationError(Map<String, String> fieldErrors, {String? generalMessage}) {
    final appError = ValidationError(
      message: generalMessage ?? 'Validation failed',
      fieldErrors: fieldErrors,
    );
    
    _logError(appError);
    _addToHistory(appError);
    
    return appError;
  }

  /// Categorize unknown errors into appropriate types
  static AppError _categorizeError(Object error, StackTrace stackTrace) {
    if (error is SocketException || error is HttpException) {
      return NetworkError(
        message: _getNetworkErrorMessage(error),
        originalError: error,
        stackTrace: stackTrace,
      );
    } else if (error is FormatException) {
      return ValidationError(
        message: 'Invalid data format: ${error.message}',
        originalError: error,
        stackTrace: stackTrace,
      );
    } else if (error is TimeoutException) {
      return NetworkError(
        message: 'Request timed out. Please check your connection.',
        code: 'TIMEOUT',
        originalError: error,
        stackTrace: stackTrace,
      );
    } else {
      return GenericError(
        message: 'An unexpected error occurred: ${error.toString()}',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get user-friendly network error messages
  static String _getNetworkErrorMessage(Object error) {
    if (error is SocketException) {
      if (error.osError?.errorCode == 7) {
        return 'No internet connection. Please check your network settings.';
      } else if (error.osError?.errorCode == 8) {
        return 'Could not reach the server. Please try again later.';
      }
      return 'Network connection problem. Please check your internet.';
    } else if (error is HttpException) {
      return 'Server communication error: ${error.message}';
    }
    return 'Network error occurred.';
  }

  /// Get user-friendly trade error messages
  static String _getTradeErrorMessage(Object error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('insufficient')) {
      return 'Insufficient balance for this trade.';
    } else if (errorString.contains('market closed')) {
      return 'Market is currently closed.';
    } else if (errorString.contains('invalid leverage')) {
      return 'Invalid leverage amount. Please use 1x-10x.';
    } else if (errorString.contains('timeout')) {
      return 'Trade request timed out. Please try again.';
    } else if (errorString.contains('rate limit')) {
      return 'Too many trades. Please wait a moment.';
    }
    
    return 'Trade could not be executed. Please try again.';
  }

  /// Show user-friendly error dialog
  static void _showUserFriendlyError(BuildContext context, AppError error) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        action: error is NetworkError 
          ? SnackBarAction(
              label: 'Retry',
              onPressed: () {
                // Implement retry logic
              },
            )
          : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show specialized trade error dialog
  static void _showTradeErrorDialog(BuildContext context, TradeError error) {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trade Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.message),
            const SizedBox(height: 8),
            const Text(
              'Your account balance and positions remain unchanged.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (error.isRetryable)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Implement retry logic
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  /// Log error with appropriate level
  static void _logError(AppError error) {
    if (kDebugMode) {
      print('=== Error Report ===');
      print('Type: ${error.runtimeType}');
      print('Message: ${error.message}');
      print('Code: ${error.code ?? 'N/A'}');
      print('Time: ${DateTime.now().toIso8601String()}');
      if (error.stackTrace != null) {
        print('Stack Trace:\n${error.stackTrace}');
      }
      print('==================');
    }
    
    // In production, send to crash reporting service
    // FirebaseCrashlytics.instance.recordError(error.originalError, error.stackTrace);
  }

  /// Add error to history for debugging
  static void _addToHistory(AppError error) {
    _errorHistory.add(error);
    if (_errorHistory.length > maxErrorHistory) {
      _errorHistory.removeAt(0);
    }
  }

  /// Get recent error history (for debugging)
  static List<AppError> getErrorHistory() {
    return List.unmodifiable(_errorHistory);
  }

  /// Clear error history
  static void clearErrorHistory() {
    _errorHistory.clear();
  }
}

/// Base class for all application errors
abstract class AppError {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  AppError({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  }) : timestamp = DateTime.now();

  @override
  String toString() => 'AppError: $message (Code: ${code ?? 'N/A'})';
}

/// Network-related errors
class NetworkError extends AppError {
  final bool isRetryable;

  NetworkError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    this.isRetryable = true,
  });
}

/// Trade execution errors
class TradeError extends AppError {
  final bool isRetryable;
  final Map<String, dynamic>? tradeContext;

  TradeError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    this.isRetryable = true,
    this.tradeContext,
  });
}

/// Validation errors with field-specific details
class ValidationError extends AppError {
  final Map<String, String> fieldErrors;

  ValidationError({
    required super.message,
    this.fieldErrors = const {},
    super.code,
    super.originalError,
    super.stackTrace,
  });

  bool hasFieldError(String field) => fieldErrors.containsKey(field);
  String? getFieldError(String field) => fieldErrors[field];
}

/// Generic errors for uncategorized issues
class GenericError extends AppError {
  GenericError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}