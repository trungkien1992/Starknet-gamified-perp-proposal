import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/weather_service.dart';

/// Provider for the weather service singleton
final weatherServiceProvider = Provider<WeatherService>((ref) {
  final service = WeatherService();
  
  // Dispose service when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider for current weather state
final weatherStateProvider = StreamProvider<WeatherState>((ref) {
  final weatherService = ref.watch(weatherServiceProvider);
  
  // Create a stream that emits when weather service notifies listeners
  return Stream.periodic(const Duration(seconds: 1), (_) {
    return weatherService.currentWeather;
  }).distinct((prev, next) => 
    prev.condition == next.condition && 
    prev.intensity == next.intensity &&
    prev.lastUpdated == next.lastUpdated
  );
});

/// Provider for current weather condition
final weatherConditionProvider = Provider<WeatherCondition>((ref) {
  final weatherAsync = ref.watch(weatherStateProvider);
  return weatherAsync.when(
    data: (weather) => weather.condition,
    loading: () => WeatherCondition.clear,
    error: (_, __) => WeatherCondition.clear,
  );
});

/// Provider for rain status
final isRainingProvider = Provider<bool>((ref) {
  final weatherAsync = ref.watch(weatherStateProvider);
  return weatherAsync.when(
    data: (weather) => weather.isRaining,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for market volatility multiplier
final volatilityMultiplierProvider = Provider<double>((ref) {
  final weatherAsync = ref.watch(weatherStateProvider);
  return weatherAsync.when(
    data: (weather) => weather.volatilityMultiplier,
    loading: () => 1.0,
    error: (_, __) => 1.0,
  );
});

/// Provider for ink efficiency bonus
final inkEfficiencyBonusProvider = Provider<double>((ref) {
  final weatherService = ref.watch(weatherServiceProvider);
  return weatherService.inkEfficiencyBonus;
});

/// Provider for weather display info
final weatherDisplayProvider = Provider<Map<String, dynamic>>((ref) {
  final weatherAsync = ref.watch(weatherStateProvider);
  return weatherAsync.when(
    data: (weather) => {
      'emoji': weather.emoji,
      'description': weather.description,
      'marketImpact': weather.marketImpact,
      'temperature': weather.temperature,
      'intensity': weather.intensity,
      'favorable': weather.volatilityMultiplier > 1.2,
    },
    loading: () => {
      'emoji': '☀️',
      'description': 'Loading...',
      'marketImpact': 'NORMAL CONDITIONS',
      'temperature': 24,
      'intensity': 0.0,
      'favorable': false,
    },
    error: (_, __) => {
      'emoji': '❓',
      'description': 'Weather unavailable',
      'marketImpact': 'NORMAL CONDITIONS',
      'temperature': 24,
      'intensity': 0.0,
      'favorable': false,
    },
  );
});

/// Actions for manual weather control (prototype testing)
final weatherActionsProvider = Provider<WeatherActions>((ref) {
  final weatherService = ref.read(weatherServiceProvider);
  return WeatherActions(weatherService);
});

class WeatherActions {
  final WeatherService _weatherService;
  
  WeatherActions(this._weatherService);
  
  /// Toggle between rain and clear weather
  void toggleWeather() => _weatherService.toggleWeather();
  
  /// Enable manual toggle mode for demo
  void enableDemoMode() => _weatherService.enableManualToggleMode();
  
  /// Disable manual mode and return to auto updates
  void disableDemo() => _weatherService.disableManualToggleMode();
  
  /// Force immediate weather update
  void forceUpdate() => _weatherService.forceUpdate();
}