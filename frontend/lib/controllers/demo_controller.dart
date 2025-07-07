import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math' as math;

import '../services/mock_trade_engine.dart' as trade_engine;
import '../services/mock_data_loader.dart';
import '../services/streak_system.dart';
import '../components/drip_reward_modal.dart';
import '../components/trader_summary_card.dart';
import '../components/drip_inventory_widget.dart';
import '../components/leaderboard_widget.dart';
import '../utils/transition_animations.dart';
import '../shared/utils/error_handler.dart';
import '../shared/utils/haptic_manager.dart';
import '../shared/constants/animation_constants.dart';

/// Current screen state for navigation tracking
enum DemoScreen {
  trading,
  profile,
  leaderboard,
  inventory,
}

/// Demo controller that orchestrates the entire StreetCred Clash experience
class DemoController extends ChangeNotifier {
  static final DemoController _instance = DemoController._internal();
  factory DemoController() => _instance;
  DemoController._internal();

  // Service instances
  final MockDataLoader _dataLoader = MockDataLoader();
  final StreakSystem _streakSystem = StreakSystem();
  
  // Current app state
  DemoScreen _currentScreen = DemoScreen.trading;
  UserProfile? _profile;
  List<DripNFT> _inventory = [];
  List<LeaderboardEntry> _leaderboard = [];
  List<TradeActivity> _recentActivity = [];
  
  // Real-time state tracking
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _lastError;
  DateTime? _lastTradeTime;
  
  // Demo configuration
  static const Duration _responseTime = Duration(milliseconds: 150);
  static const bool _enableAnimations = true;
  static const int _maxInventorySize = 50;
  
  // Trade validation
  static const Set<String> _validDirections = {'LONG', 'SHORT', 'long', 'short'};
  static const double _minLeverage = 1.0;
  static const double _maxLeverage = 10.0;

  // Getters
  DemoScreen get currentScreen => _currentScreen;
  UserProfile? get profile => _profile;
  List<DripNFT> get inventory => List.unmodifiable(_inventory);
  List<LeaderboardEntry> get leaderboard => List.unmodifiable(_leaderboard);
  List<TradeActivity> get recentActivity => List.unmodifiable(_recentActivity);
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  
  // Computed getters
  int get currentXp => _profile?.currentXp ?? 0;
  int get totalXp => _profile?.totalXp ?? 0;
  int get currentLevel => _profile?.level ?? 1;
  int get currentStreak => _profile?.currentStreak ?? 0;
  int get totalTrades => _profile?.totalTrades ?? 0;
  double get winRate => _profile?.winRate ?? 0.0;

  /// Initialize the demo controller with all services and mock data
  Future<void> initialize({bool forceReset = false}) async {
    if (_isInitialized && !forceReset) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      debugPrint('🎮 Initializing DemoController...');
      
      // Initialize streak system
      _streakSystem.initialize(
        onStreakChanged: _handleStreakChanged,
        onBadgeUnlocked: _handleBadgeUnlocked,
      );
      
      // Load initial mock data
      await _loadInitialData();
      
      _isInitialized = true;
      debugPrint('✅ DemoController initialized successfully');
      
    } catch (error) {
      _setError('Failed to initialize demo: $error');
      debugPrint('❌ DemoController initialization failed: $error');
    } finally {
      _setLoading(false);
    }
  }

  /// Core method: Handle a mock trade with full orchestration
  Future<MockTradeResult> handleMockTrade({
    required String direction,
    required int leverage,
    String? asset,
    BuildContext? context,
  }) async {
    if (!_isInitialized) {
      final error = ValidationError(message: 'DemoController not initialized');
      ErrorHandler.handleApiError(error, StackTrace.current, context: context);
      throw error;
    }
    
    // Validate input parameters
    final validation = _validateTradeParams(direction, leverage, asset);
    if (!validation.isValid) {
      final error = ErrorHandler.handleValidationError(validation.errors);
      if (context != null) {
        ErrorHandler.handleApiError(error, StackTrace.current, context: context);
      }
      throw error;
    }
    
    _clearError();
    final startTime = DateTime.now();
    
    try {
      debugPrint('🎯 Handling mock trade: $direction ${leverage}x ${asset ?? ""}');
      
      // Provide immediate haptic feedback
      await HapticManager.provideTradeGestureFeedback(leverage / 10.0);
      
      // Execute trade with timeout
      final result = await MockTradeEngine.resolveTrade(
        direction: direction,
        leverage: leverage,
        asset: asset,
      );
      
      // Update streak
      _streakSystem.onTradeCompleted();
      
      // Update profile state
      await _updateProfileFromTrade(result);
      
      // Add to activity history
      _addTradeActivity(result, direction, leverage, asset);
      
      // Show UI feedback
      if (context != null && _enableAnimations) {
        await _showTradeEffects(context, result);
      }
      
      // Update last trade time
      _lastTradeTime = DateTime.now();
      
      final duration = DateTime.now().difference(startTime);
      debugPrint('✅ Trade completed in ${duration.inMilliseconds}ms');
      
      notifyListeners();
      return result;
      
    } catch (error) {
      _setError('Trade execution failed: $error');
      debugPrint('❌ Trade failed: $error');
      
      // Handle trade-specific errors with haptic feedback
      await HapticManager.provideFeedback(HapticFeedbackType.error);
      
      if (context != null) {
        ErrorHandler.handleTradeError(error, StackTrace.current, context: context);
      }
      
      rethrow;
    }
  }

  /// Navigate to a different screen
  void navigateToScreen(DemoScreen screen) {
    if (_currentScreen != screen) {
      _currentScreen = screen;
      debugPrint('📱 Navigated to ${screen.name}');
      notifyListeners();
    }
  }

  /// Add a new drip to inventory
  Future<void> addDripToInventory(DripNFT drip) async {
    if (_inventory.length >= _maxInventorySize) {
      debugPrint('⚠️ Inventory full, removing oldest drip');
      _inventory.removeAt(0);
    }
    
    _inventory.add(drip);
    
    // Update profile
    if (_profile != null) {
      _profile = UserProfile(
        username: _profile!.username,
        avatarUrl: _profile!.avatarUrl,
        level: _profile!.level,
        currentXp: _profile!.currentXp,
        xpToLevelUp: _profile!.xpToLevelUp,
        totalXp: _profile!.totalXp,
        currentStreak: _profile!.currentStreak,
        lastTradeDate: _profile!.lastTradeDate,
        totalTrades: _profile!.totalTrades,
        winRate: _profile!.winRate,
        unlockedBadges: _profile!.unlockedBadges,
        ownedDrips: List.from(_inventory),
      );
    }
    
    debugPrint('💎 Added drip to inventory: ${drip.name}');
    notifyListeners();
  }

  /// Reset demo to initial state
  Future<void> reset({bool quickReset = false}) async {
    debugPrint('🔄 Resetting demo state...');
    
    _setLoading(!quickReset);
    _clearError();
    
    // Reset services
    _streakSystem.resetStreak();
    
    // Clear state
    _currentScreen = DemoScreen.trading;
    _profile = null;
    _inventory.clear();
    _leaderboard.clear();
    _recentActivity.clear();
    _lastTradeTime = null;
    
    if (!quickReset) {
      // Reload fresh data
      await _loadInitialData();
    }
    
    _setLoading(false);
    debugPrint('✅ Demo reset complete');
    notifyListeners();
  }

  /// Load predefined mock state for consistent demos
  Future<void> loadMockState({String scenario = 'default'}) async {
    debugPrint('📋 Loading mock state: $scenario');
    _setLoading(true);
    
    try {
      switch (scenario) {
        case 'successful_trader':
          _profile = await DemoPresets.getSuccessfulTrader();
          _leaderboard = await DemoPresets.getCompetitiveLeaderboard();
          break;
          
        case 'new_trader':
          _profile = await DemoPresets.getNewTrader();
          _leaderboard = await _dataLoader.getMockLeaderboard(count: 15);
          break;
          
        case 'competitive':
          _profile = await _dataLoader.getMockUserProfile(username: 'DemoKing');
          _leaderboard = await DemoPresets.getCompetitiveLeaderboard();
          break;
          
        default:
          await _loadInitialData();
          break;
      }
      
      // Sync inventory
      if (_profile != null) {
        _inventory = List.from(_profile!.ownedDrips);
      }
      
      // Load activity
      _recentActivity = await _dataLoader.getMockTradeActivity();
      
      debugPrint('✅ Mock state loaded: $scenario');
      
    } catch (error) {
      _setError('Failed to load mock state: $error');
      debugPrint('❌ Failed to load mock state: $error');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Get demo statistics for debugging
  Map<String, dynamic> getDemoStats() {
    return {
      'initialized': _isInitialized,
      'currentScreen': _currentScreen.name,
      'profile': _profile != null,
      'inventorySize': _inventory.length,
      'leaderboardSize': _leaderboard.length,
      'activitySize': _recentActivity.length,
      'streakStats': _streakSystem.getStreakStats(),
      'lastTradeTime': _lastTradeTime?.toIso8601String(),
      'isLoading': _isLoading,
      'lastError': _lastError,
    };
  }

  /// Simulate time passage for testing streaks
  void simulateTimePassing({int hours = 24}) {
    _streakSystem.simulateDaysForTesting(hours ~/ 24);
    debugPrint('⏰ Simulated $hours hours passing');
    notifyListeners();
  }

  // Private helper methods

  Future<void> _loadInitialData() async {
    // Load user profile
    _profile = await _dataLoader.getMockUserProfile(username: 'DemoUser');
    
    // Load inventory from profile
    _inventory = List.from(_profile!.ownedDrips);
    
    // Load leaderboard
    _leaderboard = await _dataLoader.getMockLeaderboard(
      count: 25,
      currentUsername: _profile!.username,
    );
    
    // Load recent activity
    _recentActivity = await _dataLoader.getMockTradeActivity();
    
    debugPrint('📊 Initial data loaded');
  }

  Future<void> _updateProfileFromTrade(MockTradeResult result) async {
    if (_profile == null) return;
    
    // Calculate new XP and level
    final newCurrentXp = _profile!.currentXp + result.xpGained;
    int newLevel = _profile!.level;
    int adjustedXp = newCurrentXp;
    
    // Handle level up
    if (newCurrentXp >= _profile!.xpToLevelUp) {
      newLevel++;
      adjustedXp = newCurrentXp - _profile!.xpToLevelUp;
    }
    
    // Calculate new win rate
    final totalTrades = _profile!.totalTrades + 1;
    final wins = (_profile!.winRate * _profile!.totalTrades).round();
    final newWins = result.pnl > 0 ? wins + 1 : wins;
    final newWinRate = newWins / totalTrades;
    
    // Update profile
    _profile = UserProfile(
      username: _profile!.username,
      avatarUrl: _profile!.avatarUrl,
      level: newLevel,
      currentXp: adjustedXp,
      xpToLevelUp: _calculateXpToLevelUp(newLevel),
      totalXp: _profile!.totalXp + result.xpGained,
      currentStreak: _streakSystem.currentStreak,
      lastTradeDate: DateTime.now(),
      totalTrades: totalTrades,
      winRate: double.parse(newWinRate.toStringAsFixed(3)),
      unlockedBadges: _profile!.unlockedBadges,
      ownedDrips: List.from(_inventory),
    );
    
    // Add drip if earned
    if (result.dripRarity != null) {
      final newDrip = _createDripFromResult(result);
      await addDripToInventory(newDrip);
    }
  }

  void _addTradeActivity(MockTradeResult result, String direction, int leverage, String? asset) {
    final activity = TradeActivity(
      timestamp: DateTime.now(),
      direction: direction,
      leverage: leverage,
      pnl: result.pnl,
      xpGained: result.xpGained,
      asset: asset ?? 'BTC',
    );
    
    _recentActivity.insert(0, activity);
    
    // Keep only recent 20 activities
    if (_recentActivity.length > 20) {
      _recentActivity = _recentActivity.take(20).toList();
    }
  }

  Future<void> _showTradeEffects(BuildContext context, MockTradeResult result) async {
    // Show summary card
    TraderSummaryCardHelper.showTradeSummary(
      context,
      pnl: result.pnl,
      xpGained: result.xpGained,
      dripRarity: result.dripRarity?.name,
      totalXp: _profile?.totalXp,
    );
    
    // Small delay before potential drip modal
    await Future.delayed(const Duration(milliseconds: 3000));
    
    // Show drip modal if earned
    if (result.dripRarity != null && context.mounted) {
      final drip = _createDripFromResult(result);
      await _showDripModal(context, drip);
    }
  }

  Future<void> _showDripModal(BuildContext context, DripNFT drip) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TransitionAnimations.fadeScaleModal(
        child: DripRewardModal(
          reward: DripReward(
            id: drip.id ?? 'reward_${DateTime.now().millisecondsSinceEpoch}',
            name: drip.name,
            rarity: _mapStringToRarity(drip.rarity),
            imageUrl: drip.imageUrl,
          ),
          onEquip: (dripId) {
            Navigator.of(context).pop();
            debugPrint('💎 Drip equipped: $dripId');
          },
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  DripNFT _createDripFromResult(MockTradeResult result) {
    final rarityName = result.dripRarity!.name;
    final dripNames = {
      'common': ['Basic Cap', 'Street Tee', 'Plain Kicks'],
      'rare': ['Neon Shades', 'Chrome Watch', 'LED Sneakers'],
      'epic': ['Holographic Jacket', 'Cyber Gloves', 'Plasma Visor'],
      'legendary': ['Golden Crown', 'Mythic Wings', 'Infinity Gauntlet'],
    };
    
    final names = dripNames[rarityName] ?? dripNames['common']!;
    final randomName = names[math.Random().nextInt(names.length)];
    
    return DripNFT(
      id: 'drip_${DateTime.now().millisecondsSinceEpoch}',
      name: randomName,
      rarity: rarityName,
      imageUrl: 'https://streetcred.assets/drips/$rarityName/${randomName.toLowerCase().replaceAll(' ', '_')}.png',
    );
  }

  DripRarity _mapStringToRarity(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'rare': return DripRarity.rare;
      case 'epic': return DripRarity.epic;
      case 'legendary': return DripRarity.legendary;
      default: return DripRarity.common;
    }
  }

  int _calculateXpToLevelUp(int level) {
    return (100 * math.pow(1.5, level - 1)).round();
  }

  void _handleStreakChanged(int newStreak) {
    debugPrint('🔥 Streak changed: $newStreak days');
    // Profile will be updated in next trade
  }

  void _handleBadgeUnlocked(String badgeId) {
    debugPrint('🏆 Badge unlocked: $badgeId');
    if (_profile != null) {
      final newBadges = List<String>.from(_profile!.unlockedBadges);
      if (!newBadges.contains(badgeId)) {
        newBadges.add(badgeId);
        
        _profile = UserProfile(
          username: _profile!.username,
          avatarUrl: _profile!.avatarUrl,
          level: _profile!.level,
          currentXp: _profile!.currentXp,
          xpToLevelUp: _profile!.xpToLevelUp,
          totalXp: _profile!.totalXp,
          currentStreak: _profile!.currentStreak,
          lastTradeDate: _profile!.lastTradeDate,
          totalTrades: _profile!.totalTrades,
          winRate: _profile!.winRate,
          unlockedBadges: newBadges,
          ownedDrips: _profile!.ownedDrips,
        );
        
        notifyListeners();
      }
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _lastError = error;
    notifyListeners();
  }

  void _clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }
  
  /// Validate trade parameters
  ValidationResult _validateTradeParams(String direction, int leverage, String? asset) {
    final errors = <String, String>{};
    
    // Validate direction
    if (!_validDirections.contains(direction)) {
      errors['direction'] = 'Invalid direction: must be LONG or SHORT';
    }
    
    // Validate leverage
    if (leverage < _minLeverage || leverage > _maxLeverage) {
      errors['leverage'] = 'Invalid leverage: must be between ${_minLeverage.toInt()}x and ${_maxLeverage.toInt()}x';
    }
    
    // Validate asset (optional, but if provided should be valid)
    if (asset != null && asset.isNotEmpty) {
      const validAssets = {'BTC', 'ETH', 'STRK', 'BTC-USDT', 'ETH-USDT', 'STRK-USDT'};
      if (!validAssets.contains(asset.toUpperCase())) {
        errors['asset'] = 'Invalid asset: $asset not supported';
      }
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

/// Validation result helper class
class ValidationResult {
  final bool isValid;
  final Map<String, String> errors;
  
  const ValidationResult({
    required this.isValid,
    required this.errors,
  });
}

/// Extension methods for easy integration
extension DemoControllerExtensions on DemoController {
  /// Quick access to user's current rank
  int? get currentRank {
    if (profile == null) return null;
    
    final userEntry = leaderboard.firstWhere(
      (entry) => entry.username == profile!.username,
      orElse: () => const LeaderboardEntry(username: '', xp: 0, rank: 0),
    );
    
    return userEntry.rank > 0 ? userEntry.rank : null;
  }
  
  /// Check if user should see streak reminder
  bool get shouldShowStreakReminder {
    return _streakSystem.shouldShowStreakReminder();
  }
  
  /// Get streak status message
  String get streakStatusMessage {
    return _streakSystem.getStreakStatusMessage();
  }
}

/// Utility class for demo testing and validation
class DemoControllerTester {
  static Future<void> runDemoTests() async {
    final controller = DemoController();
    
    debugPrint('\n🧪 Running Demo Controller Tests...');
    
    // Test initialization
    await controller.initialize(forceReset: true);
    assert(controller.isInitialized, 'Controller should be initialized');
    
    // Test mock trade
    final result = await controller.handleMockTrade(
      direction: 'long',
      leverage: 5,
      asset: 'BTC',
    );
    assert(result.xpGained > 0, 'Should gain XP from trade');
    
    // Test state scenarios
    await controller.loadMockState(scenario: 'successful_trader');
    assert(controller.profile != null, 'Should have profile');
    assert(controller.currentLevel > 5, 'Successful trader should be high level');
    
    // Test reset
    await controller.reset();
    
    debugPrint('✅ All demo tests passed!');
    
    // Print final stats
    final stats = controller.getDemoStats();
    debugPrint('📊 Demo Stats: $stats');
  }
}