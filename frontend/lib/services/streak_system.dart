import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Tracks user engagement streaks based on daily trading activity.
/// 
/// Manages streak counting, badge unlocking, and provides status messages
/// for the gamified trading experience.
class StreakSystem {
  static final StreakSystem _instance = StreakSystem._internal();
  factory StreakSystem() => _instance;
  StreakSystem._internal();

  // Core streak data
  int _currentStreak = 0;
  DateTime? _lastTradeDate;
  DateTime? _streakStartDate;
  List<String> _unlockedBadges = [];
  
  // Callbacks
  Function(int newStreak)? _onStreakChanged;
  Function(String badgeId)? _onBadgeUnlocked;
  
  // Constants
  static const Duration _streakWindow = Duration(hours: 24);
  static const Map<int, String> _streakBadges = {
    3: '🔥 Fire Starter',
    7: '⚡ Lightning Week',
    14: '💎 Diamond Hands',
    30: '👑 Streak Master',
    100: '🏆 Legendary Trader',
  };

  // Getters
  int get currentStreak => _currentStreak;
  bool get isStreakActive => _isStreakActive();
  DateTime? get lastTradeDate => _lastTradeDate;
  DateTime? get streakStartDate => _streakStartDate;
  List<String> get unlockedBadges => List.unmodifiable(_unlockedBadges);
  
  /// Initialize the streak system with optional callbacks.
  void initialize({
    Function(int newStreak)? onStreakChanged,
    Function(String badgeId)? onBadgeUnlocked,
  }) {
    _onStreakChanged = onStreakChanged;
    _onBadgeUnlocked = onBadgeUnlocked;
    _loadStreakData();
    debugPrint('StreakSystem initialized: $_currentStreak day streak');
  }

  /// Called when a user completes a trade.
  /// Updates streak count and handles badge unlocking.
  void onTradeCompleted() {
    final now = DateTime.now();
    final today = _normalizeToDay(now);
    
    // Check if this is the first trade ever
    if (_lastTradeDate == null) {
      _startNewStreak(today);
      _saveStreakData();
      return;
    }
    
    final lastTradeDay = _normalizeToDay(_lastTradeDate!);
    final daysDifference = today.difference(lastTradeDay).inDays;
    
    if (daysDifference == 0) {
      // Same day - no streak change, just update timestamp
      _lastTradeDate = now;
      debugPrint('Same day trade - streak maintained at $_currentStreak');
    } else if (daysDifference == 1) {
      // Next day - increment streak
      _currentStreak++;
      _lastTradeDate = now;
      
      debugPrint('Streak incremented to $_currentStreak days');
      
      // Check for badge unlocks
      _checkBadgeUnlocks();
      
      // Trigger callback
      _onStreakChanged?.call(_currentStreak);
      
      // Haptic feedback for streak milestone
      if (_isStreakMilestone(_currentStreak)) {
        HapticFeedback.mediumImpact();
      }
    } else {
      // Gap detected - reset streak
      debugPrint('Gap detected: $daysDifference days. Resetting streak.');
      _startNewStreak(today);
    }
    
    _saveStreakData();
  }

  /// Checks if the current streak is still active (within 24h window).
  bool _isStreakActive() {
    if (_lastTradeDate == null) return false;
    
    final now = DateTime.now();
    final timeSinceLastTrade = now.difference(_lastTradeDate!);
    
    return timeSinceLastTrade <= _streakWindow;
  }

  /// Starts a new streak from today.
  void _startNewStreak(DateTime startDate) {
    _currentStreak = 1;
    _lastTradeDate = startDate;
    _streakStartDate = startDate;
    
    debugPrint('New streak started on ${startDate.toLocal()}');
    _onStreakChanged?.call(_currentStreak);
  }

  /// Normalizes a DateTime to the start of the day for comparison.
  DateTime _normalizeToDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Checks for newly unlocked badges based on current streak.
  void _checkBadgeUnlocks() {
    for (final entry in _streakBadges.entries) {
      final requiredDays = entry.key;
      final badgeId = entry.value;
      
      if (_currentStreak >= requiredDays && !_unlockedBadges.contains(badgeId)) {
        _unlockedBadges.add(badgeId);
        debugPrint('Badge unlocked: $badgeId');
        _onBadgeUnlocked?.call(badgeId);
      }
    }
  }

  /// Returns true if the streak count is a notable milestone.
  bool _isStreakMilestone(int streak) {
    return _streakBadges.containsKey(streak) || streak % 10 == 0;
  }

  /// Returns a user-friendly status message about the current streak.
  String getStreakStatusMessage() {
    if (_currentStreak == 0) {
      return "Start your trading streak today! 🚀";
    }
    
    if (!_isStreakActive()) {
      return "Come back today to continue your streak! ⏰";
    }
    
    // Active streak messages
    switch (_currentStreak) {
      case 1:
        return "🔥 Great start! Keep trading tomorrow!";
      case 2:
        return "🔥 2-day streak! You're building momentum!";
      case 3:
        return "🔥 You're on fire! 3-day streak!";
      case 7:
        return "⚡ Amazing! Full week streak!";
      case 14:
        return "💎 Two weeks strong! Diamond hands!";
      case 30:
        return "👑 30-day streak! You're a legend!";
      default:
        if (_currentStreak >= 100) {
          return "🏆 $currentStreak-day LEGENDARY streak!";
        } else if (_currentStreak >= 50) {
          return "🌟 $currentStreak-day master streak!";
        } else if (_currentStreak >= 20) {
          return "💪 $currentStreak-day powerhouse streak!";
        } else if (_currentStreak >= 10) {
          return "🚀 $currentStreak-day rocket streak!";
        } else {
          return "🔥 You're on a $_currentStreak-day streak!";
        }
    }
  }

  /// Returns the next badge that can be unlocked and days remaining.
  Map<String, dynamic>? getNextBadgeInfo() {
    for (final entry in _streakBadges.entries) {
      final requiredDays = entry.key;
      final badgeId = entry.value;
      
      if (_currentStreak < requiredDays) {
        return {
          'badgeId': badgeId,
          'requiredDays': requiredDays,
          'daysRemaining': requiredDays - _currentStreak,
        };
      }
    }
    return null; // All badges unlocked
  }

  /// Returns time remaining until streak expires.
  Duration? getTimeUntilStreakExpires() {
    if (_lastTradeDate == null || !_isStreakActive()) return null;
    
    final expiryTime = _lastTradeDate!.add(_streakWindow);
    final now = DateTime.now();
    
    if (now.isBefore(expiryTime)) {
      return expiryTime.difference(now);
    }
    return null;
  }

  /// Manually reset the streak (for testing or admin purposes).
  void resetStreak() {
    _currentStreak = 0;
    _lastTradeDate = null;
    _streakStartDate = null;
    _unlockedBadges.clear();
    _saveStreakData();
    
    debugPrint('Streak manually reset');
    _onStreakChanged?.call(0);
  }

  /// Get streak statistics for analytics.
  Map<String, dynamic> getStreakStats() {
    final timeUntilExpiry = getTimeUntilStreakExpires();
    final nextBadge = getNextBadgeInfo();
    
    return {
      'currentStreak': _currentStreak,
      'isActive': _isStreakActive(),
      'lastTradeDate': _lastTradeDate?.toIso8601String(),
      'streakStartDate': _streakStartDate?.toIso8601String(),
      'unlockedBadges': _unlockedBadges,
      'timeUntilExpiry': timeUntilExpiry?.inHours,
      'nextBadge': nextBadge,
      'statusMessage': getStreakStatusMessage(),
    };
  }

  /// Save streak data to local storage (mock implementation).
  void _saveStreakData() {
    final data = {
      'currentStreak': _currentStreak,
      'lastTradeDate': _lastTradeDate?.toIso8601String(),
      'streakStartDate': _streakStartDate?.toIso8601String(),
      'unlockedBadges': _unlockedBadges,
    };
    
    // In a real app, this would save to SharedPreferences or secure storage
    debugPrint('Saving streak data: ${jsonEncode(data)}');
  }

  /// Load streak data from local storage (mock implementation).
  void _loadStreakData() {
    // In a real app, this would load from SharedPreferences or secure storage
    // For now, we'll use sample data for testing
    
    // Mock loaded data - replace with actual storage logic
    final mockData = {
      'currentStreak': 0,
      'lastTradeDate': null,
      'streakStartDate': null,
      'unlockedBadges': <String>[],
    };
    
    _currentStreak = mockData['currentStreak'] as int;
    
    if (mockData['lastTradeDate'] != null) {
      _lastTradeDate = DateTime.parse(mockData['lastTradeDate'] as String);
    }
    
    if (mockData['streakStartDate'] != null) {
      _streakStartDate = DateTime.parse(mockData['streakStartDate'] as String);
    }
    
    _unlockedBadges = List<String>.from(mockData['unlockedBadges'] as List);
    
    // Validate streak is still active after loading
    if (!_isStreakActive() && _currentStreak > 0) {
      debugPrint('Loaded streak has expired. Resetting to 0.');
      _currentStreak = 0;
      _streakStartDate = null;
    }
    
    debugPrint('Loaded streak data: $_currentStreak days');
  }

  /// Simulate days passing for testing purposes.
  void simulateDaysForTesting(int days) {
    if (_lastTradeDate != null) {
      _lastTradeDate = _lastTradeDate!.add(Duration(days: days));
    }
  }
}

/// Utility class for testing the streak system.
class StreakSystemTester {
  static void runStreakTests() {
    final streakSystem = StreakSystem();
    
    streakSystem.initialize(
      onStreakChanged: (newStreak) => debugPrint('✅ Streak changed: $newStreak'),
      onBadgeUnlocked: (badgeId) => debugPrint('🏆 Badge unlocked: $badgeId'),
    );
    
    // Test 1: First trade
    debugPrint('\n=== Test 1: First Trade ===');
    streakSystem.onTradeCompleted();
    debugPrint('Status: ${streakSystem.getStreakStatusMessage()}');
    
    // Test 2: Same day trade
    debugPrint('\n=== Test 2: Same Day Trade ===');
    streakSystem.onTradeCompleted();
    debugPrint('Status: ${streakSystem.getStreakStatusMessage()}');
    
    // Test 3: Next day trade
    debugPrint('\n=== Test 3: Next Day Trade ===');
    streakSystem.simulateDaysForTesting(1);
    streakSystem.onTradeCompleted();
    debugPrint('Status: ${streakSystem.getStreakStatusMessage()}');
    
    // Test 4: Streak break
    debugPrint('\n=== Test 4: Streak Break ===');
    streakSystem.simulateDaysForTesting(2);
    streakSystem.onTradeCompleted();
    debugPrint('Status: ${streakSystem.getStreakStatusMessage()}');
    
    // Test 5: Build to badge unlock
    debugPrint('\n=== Test 5: Badge Unlock ===');
    for (int i = 0; i < 3; i++) {
      streakSystem.simulateDaysForTesting(1);
      streakSystem.onTradeCompleted();
    }
    debugPrint('Status: ${streakSystem.getStreakStatusMessage()}');
    debugPrint('Badges: ${streakSystem.unlockedBadges}');
    
    // Print final stats
    debugPrint('\n=== Final Stats ===');
    final stats = streakSystem.getStreakStats();
    debugPrint(jsonEncode(stats));
  }
}

/// Extension methods for easy integration with other services
extension StreakSystemIntegration on StreakSystem {
  /// Quick check if user should see a streak reminder
  bool shouldShowStreakReminder() {
    if (currentStreak == 0) return false;
    
    final timeUntilExpiry = getTimeUntilStreakExpires();
    if (timeUntilExpiry == null) return true; // Expired
    
    // Show reminder if less than 4 hours remaining
    return timeUntilExpiry.inHours <= 4;
  }
  
  /// Get reward multiplier based on streak (for XP bonuses)
  double getStreakMultiplier() {
    if (currentStreak >= 30) return 2.0;
    if (currentStreak >= 14) return 1.5;
    if (currentStreak >= 7) return 1.3;
    if (currentStreak >= 3) return 1.2;
    return 1.0;
  }
  
  /// Check if today is a new streak milestone
  bool isMilestoneDay() {
    return _streakBadges.containsKey(currentStreak);
  }
}