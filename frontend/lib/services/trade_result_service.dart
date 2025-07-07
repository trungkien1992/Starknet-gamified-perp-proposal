import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;

import 'mock_trade_engine.dart';
import '../components/xp_burst_animation.dart';
import '../components/drip_reward_modal.dart';
import '../components/drip_inventory_widget.dart';

enum TradeStatus {
  idle,
  executing,
  resolved,
  error,
}

class TradeResultService {
  static final TradeResultService _instance = TradeResultService._internal();
  factory TradeResultService() => _instance;
  TradeResultService._internal();

  // Current state
  TradeStatus _status = TradeStatus.idle;
  MockTradeResult? _lastResult;
  
  // User progress tracking
  int _currentXp = 0;
  int _xpToLevelUp = 100;
  int _currentLevel = 1;
  
  // Service callbacks
  Function(MockTradeResult)? _onTradeResolved;
  Function(String)? _onDripEquipped;
  VoidCallback? _onLevelUp;
  
  // UI Controllers
  GlobalKey<XpBurstAnimationState>? _xpAnimationKey;
  
  // Getters
  TradeStatus get status => _status;
  MockTradeResult? get lastResult => _lastResult;
  int get currentXp => _currentXp;
  int get xpToLevelUp => _xpToLevelUp;
  int get currentLevel => _currentLevel;
  
  /// Initialize the service with user progress and callbacks
  void initialize({
    int initialXp = 0,
    int initialLevel = 1,
    Function(MockTradeResult)? onTradeResolved,
    Function(String)? onDripEquipped,
    VoidCallback? onLevelUp,
  }) {
    _currentXp = initialXp;
    _currentLevel = initialLevel;
    _xpToLevelUp = _calculateXpToLevelUp(initialLevel);
    _onTradeResolved = onTradeResolved;
    _onDripEquipped = onDripEquipped;
    _onLevelUp = onLevelUp;
    
    debugPrint('TradeResultService initialized: Level $_currentLevel, XP $_currentXp/$_xpToLevelUp');
  }
  
  /// Register XP animation widget for triggering
  void registerXpAnimation(GlobalKey<XpBurstAnimationState> key) {
    _xpAnimationKey = key;
  }
  
  /// Execute a trade with the given parameters
  Future<MockTradeResult> executeTrade({
    required String direction,
    required int leverage,
    String? asset,
    BuildContext? context,
  }) async {
    if (_status == TradeStatus.executing) {
      throw Exception('Trade already in progress');
    }
    
    _status = TradeStatus.executing;
    
    try {
      // Add small delay to ensure UI responsiveness
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Execute trade using MockTradeEngine
      final result = MockTradeEngine.resolveTrade(
        direction: direction,
        leverage: leverage,
        asset: asset,
      );
      
      // Store result
      _lastResult = result;
      _status = TradeStatus.resolved;
      
      // Process trade result
      await _processTradeResult(result, context);
      
      // Trigger callback
      _onTradeResolved?.call(result);
      
      return result;
      
    } catch (error) {
      _status = TradeStatus.error;
      debugPrint('Trade execution failed: $error');
      rethrow;
    } finally {
      // Reset status after processing
      Future.delayed(const Duration(milliseconds: 100), () {
        _status = TradeStatus.idle;
      });
    }
  }
  
  /// Process the trade result and trigger UI animations
  Future<void> _processTradeResult(MockTradeResult result, BuildContext? context) async {
    final startTime = DateTime.now();
    
    // Step 1: Update XP and trigger XP animation
    await _handleXpUpdate(result);
    
    // Step 2: Handle drip reward if applicable
    if (result.dripRarity != null && context != null) {
      await _handleDripReward(result, context);
    }
    
    // Step 3: Additional effects based on trade outcome
    await _handleTradeEffects(result);
    
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime).inMilliseconds;
    
    debugPrint('Trade processing completed in ${duration}ms');
    
    // Ensure we stay under 300ms total latency
    if (duration > 300) {
      debugPrint('Warning: Trade processing exceeded 300ms target');
    }
  }
  
  /// Handle XP update and animation
  Future<void> _handleXpUpdate(MockTradeResult result) async {
    if (result.xpGained <= 0) return;
    
    final previousXp = _currentXp;
    final newXp = _currentXp + result.xpGained;
    
    // Check for level up
    bool willLevelUp = newXp >= _xpToLevelUp;
    
    // Update XP
    _currentXp = newXp;
    
    // Handle level up
    if (willLevelUp) {
      _currentLevel++;
      _currentXp = newXp - _xpToLevelUp;
      _xpToLevelUp = _calculateXpToLevelUp(_currentLevel);
      
      debugPrint('Level up! New level: $_currentLevel');
      
      // Trigger level up callback
      _onLevelUp?.call();
    }
    
    // Trigger XP animation if widget is registered
    if (_xpAnimationKey?.currentState != null) {
      _xpAnimationKey!.currentState!.animateXpGain(
        previousXp: previousXp,
        xpGained: result.xpGained,
        willLevelUp: willLevelUp,
      );
    }
    
    debugPrint('XP updated: ${previousXp} -> ${_currentXp} (+${result.xpGained})');
  }
  
  /// Handle drip reward modal
  Future<void> _handleDripReward(MockTradeResult result, BuildContext context) async {
    if (result.dripRarity == null) return;
    
    // Create drip NFT based on result
    final drip = _createDripFromResult(result);
    
    // Small delay for XP animation to start
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Show drip reward modal
    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => DripRewardModal(
          reward: DripReward(
            id: drip.id ?? 'drip_${DateTime.now().millisecondsSinceEpoch}',
            name: drip.name,
            rarity: _mapRarityToDripRarity(result.dripRarity!),
            imageUrl: drip.imageUrl,
          ),
          onEquip: (dripId) {
            _onDripEquipped?.call(dripId);
            Navigator.of(context).pop();
          },
          onClose: () => Navigator.of(context).pop(),
        ),
      );
    }
  }
  
  /// Handle additional trade effects (haptics, sounds, etc.)
  Future<void> _handleTradeEffects(MockTradeResult result) async {
    // Haptic feedback based on result
    if (result.pnl > 0) {
      HapticFeedback.mediumImpact(); // Profit
    } else if (result.pnl < -10) {
      HapticFeedback.heavyImpact(); // Big loss
    } else {
      HapticFeedback.lightImpact(); // Small loss
    }
    
    // Log trade for analytics
    debugPrint('Trade completed: PnL ${result.pnl}%, XP +${result.xpGained}, Drip: ${result.dripRarity}');
  }
  
  /// Create a DripNFT from the trade result
  DripNFT _createDripFromResult(MockTradeResult result) {
    if (result.dripRarity == null) {
      throw Exception('Cannot create drip from result without rarity');
    }
    
    final rarityName = result.dripRarity!.name;
    final dripNames = _getDripNamesForRarity(rarityName);
    final randomName = dripNames[math.Random().nextInt(dripNames.length)];
    
    return DripNFT(
      name: randomName,
      rarity: rarityName,
      imageUrl: _getPlaceholderImageUrl(rarityName),
      id: 'drip_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
  
  /// Map MockTradeEngine rarity to DripReward rarity
  DripRarity _mapRarityToDripRarity(DripRarity mockRarity) {
    switch (mockRarity) {
      case DripRarity.common:
        return DripRarity.common;
      case DripRarity.rare:
        return DripRarity.rare;
      case DripRarity.epic:
        return DripRarity.epic;
      case DripRarity.legendary:
        return DripRarity.legendary;
    }
  }
  
  /// Get drip names based on rarity
  List<String> _getDripNamesForRarity(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return ['Basic Cap', 'Street Tee', 'Plain Kicks', 'Simple Chain'];
      case 'rare':
        return ['Neon Shades', 'Graffiti Hoodie', 'Chrome Watch', 'LED Sneakers'];
      case 'epic':
        return ['Holographic Jacket', 'Diamond Earrings', 'Cyber Gloves', 'Plasma Visor'];
      case 'legendary':
        return ['Golden Crown', 'Legendary Aura', 'Mythic Wings', 'Infinity Gauntlet'];
      default:
        return ['Unknown Drip'];
    }
  }
  
  /// Get placeholder image URL for rarity
  String _getPlaceholderImageUrl(String rarity) {
    // In a real app, these would be actual image URLs
    return 'https://example.com/drip_${rarity.toLowerCase()}.png';
  }
  
  /// Calculate XP required for next level
  int _calculateXpToLevelUp(int level) {
    // Exponential XP scaling: 100 * (1.5^level)
    return (100 * math.pow(1.5, level - 1)).round();
  }
  
  /// Reset service state (for testing or user logout)
  void reset() {
    _status = TradeStatus.idle;
    _lastResult = null;
    _currentXp = 0;
    _currentLevel = 1;
    _xpToLevelUp = 100;
    _xpAnimationKey = null;
  }
  
  /// Get formatted trade statistics
  Map<String, dynamic> getStats() {
    return {
      'level': _currentLevel,
      'currentXp': _currentXp,
      'xpToLevelUp': _xpToLevelUp,
      'status': _status.name,
      'lastTrade': _lastResult?.toString(),
    };
  }
}

/// Extension for XpBurstAnimation to work with TradeResultService
extension XpBurstAnimationState on State<XpBurstAnimation> {
  void animateXpGain({
    required int previousXp,
    required int xpGained,
    required bool willLevelUp,
  }) {
    // This would trigger the animation in the XpBurstAnimation widget
    // Implementation depends on the specific animation controller setup
    debugPrint('Animating XP gain: $previousXp -> ${previousXp + xpGained} (+$xpGained)');
  }
}

/// Utility class for testing the service
class TradeResultServiceTester {
  static Future<void> runTestTrade({
    required BuildContext context,
    String direction = "long",
    int leverage = 5,
    String? asset,
  }) async {
    final service = TradeResultService();
    
    try {
      final result = await service.executeTrade(
        direction: direction,
        leverage: leverage,
        asset: asset,
        context: context,
      );
      
      debugPrint('Test trade completed: $result');
      
    } catch (error) {
      debugPrint('Test trade failed: $error');
    }
  }
  
  static void printServiceStats() {
    final service = TradeResultService();
    final stats = service.getStats();
    debugPrint('Service Stats: $stats');
  }
}