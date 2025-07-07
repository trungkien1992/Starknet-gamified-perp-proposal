import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

enum HapticFeedbackType { 
  selection, 
  success, 
  error, 
  warning,
  tradeExecuted,
  levelUp,
  dripReward,
}

class HapticManager {
  static bool _isEnabled = true;
  
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }
  
  static Future<void> provideFeedback(HapticFeedbackType type) async {
    if (!_isEnabled || kIsWeb) return;
    
    try {
      switch (type) {
        case HapticFeedbackType.selection:
          await HapticFeedback.selectionClick();
          break;
          
        case HapticFeedbackType.success:
        case HapticFeedbackType.tradeExecuted:
          await HapticFeedback.mediumImpact();
          // Add custom success pattern
          await Future.delayed(const Duration(milliseconds: 50));
          await HapticFeedback.lightImpact();
          break;
          
        case HapticFeedbackType.error:
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.heavyImpact();
          break;
          
        case HapticFeedbackType.warning:
          await HapticFeedback.mediumImpact();
          break;
          
        case HapticFeedbackType.levelUp:
          // Special pattern for level up
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.lightImpact();
          break;
          
        case HapticFeedbackType.dripReward:
          // Special pattern for drip rewards
          await HapticFeedback.lightImpact();
          await Future.delayed(const Duration(milliseconds: 80));
          await HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 80));
          await HapticFeedback.heavyImpact();
          break;
      }
    } catch (e) {
      // Haptic feedback may not be available on all devices
      if (kDebugMode) {
        print('Haptic feedback error: $e');
      }
    }
  }
  
  /// Provide haptic feedback for trading gestures based on intensity
  static Future<void> provideTradeGestureFeedback(double intensity) async {
    if (!_isEnabled || kIsWeb) return;
    
    try {
      if (intensity < 0.3) {
        await HapticFeedback.lightImpact();
      } else if (intensity < 0.7) {
        await HapticFeedback.mediumImpact();
      } else {
        await HapticFeedback.heavyImpact();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Trade gesture haptic feedback error: $e');
      }
    }
  }
}