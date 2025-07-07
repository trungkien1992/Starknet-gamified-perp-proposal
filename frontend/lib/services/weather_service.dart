import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

enum WeatherCondition {
  clear,
  lightRain,
  heavyRain,
  fog,
  storm,
}

class WeatherState {
  final WeatherCondition condition;
  final double intensity; // 0.0 to 1.0
  final double volatilityMultiplier;
  final bool isRaining;
  final double windSpeed; // km/h
  final int temperature; // Celsius
  final DateTime lastUpdated;
  final String description;

  const WeatherState({
    this.condition = WeatherCondition.clear,
    this.intensity = 0.0,
    this.volatilityMultiplier = 1.0,
    this.isRaining = false,
    this.windSpeed = 0.0,
    this.temperature = 24,
    required this.lastUpdated,
    this.description = 'Clear',
  });

  WeatherState copyWith({
    WeatherCondition? condition,
    double? intensity,
    double? volatilityMultiplier,
    bool? isRaining,
    double? windSpeed,
    int? temperature,
    DateTime? lastUpdated,
    String? description,
  }) {
    return WeatherState(
      condition: condition ?? this.condition,
      intensity: intensity ?? this.intensity,
      volatilityMultiplier: volatilityMultiplier ?? this.volatilityMultiplier,
      isRaining: isRaining ?? this.isRaining,
      windSpeed: windSpeed ?? this.windSpeed,
      temperature: temperature ?? this.temperature,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      description: description ?? this.description,
    );
  }

  /// Get emoji representation of weather
  String get emoji {
    switch (condition) {
      case WeatherCondition.clear:
        return '☀️';
      case WeatherCondition.lightRain:
        return '🌧️';
      case WeatherCondition.heavyRain:
        return '⛈️';
      case WeatherCondition.fog:
        return '🌫️';
      case WeatherCondition.storm:
        return '⚡';
    }
  }

  /// Get market impact description
  String get marketImpact {
    if (volatilityMultiplier >= 2.0) return 'EXTREME VOLATILITY';
    if (volatilityMultiplier >= 1.5) return 'HIGH VOLATILITY';
    if (volatilityMultiplier >= 1.2) return 'INCREASED VOLATILITY';
    return 'NORMAL CONDITIONS';
  }
}

class WeatherService extends ChangeNotifier {
  static const String _hkoApiBase = 'https://data.weather.gov.hk/weatherAPI/opendata';
  static const String _hongKongStationId = '45007'; // Hong Kong Observatory HQ
  
  WeatherState _currentWeather = WeatherState(
    lastUpdated: DateTime.now(),
  );
  
  Timer? _updateTimer;
  Timer? _mockToggleTimer;
  bool _isManualToggleMode = false;
  final math.Random _random = math.Random();

  WeatherState get currentWeather => _currentWeather;
  bool get isRaining => _currentWeather.isRaining;
  double get volatilityMultiplier => _currentWeather.volatilityMultiplier;
  double get rainIntensity => _currentWeather.intensity;

  WeatherService() {
    _startPeriodicUpdates();
  }

  /// Start automatic weather updates every 5 minutes
  void _startPeriodicUpdates() {
    // Initial update
    _updateWeather();
    
    // Periodic updates every 5 minutes
    _updateTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!_isManualToggleMode) {
        _updateWeather();
      }
    });
  }

  /// Fetch real Hong Kong Observatory weather data
  Future<void> _updateWeather() async {
    try {
      // Try to fetch real HKO data
      await _fetchRealWeatherData();
    } catch (e) {
      if (kDebugMode) {
        print('Weather API unavailable, using mock data: $e');
      }
      // Fallback to realistic mock data
      _generateMockWeatherData();
    }
  }

  /// Fetch data from Hong Kong Observatory API
  Future<void> _fetchRealWeatherData() async {
    final response = await http.get(
      Uri.parse('$_hkoApiBase/weather.php?dataType=rhrread&lang=en'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _updateStateFromHKOData(data);
    } else {
      throw Exception('HKO API returned ${response.statusCode}');
    }
  }

  /// Parse Hong Kong Observatory API response
  void _updateStateFromHKOData(Map<String, dynamic> data) {
    try {
      // Extract current weather from HKO response
      final rainfall = data['rainfall']?['data']?.first;
      final temperature = data['temperature']?['data']?.first;
      final humidity = data['humidity']?['data']?.first;
      final uvIndex = data['uvindex']?['data']?.first;

      final rainValue = double.tryParse(rainfall?['value']?.toString() ?? '0') ?? 0.0;
      final tempValue = int.tryParse(temperature?['value']?.toString() ?? '24') ?? 24;
      final humidityValue = double.tryParse(humidity?['value']?.toString() ?? '60') ?? 60.0;

      // Determine weather condition based on rainfall
      WeatherCondition condition;
      double intensity;
      bool isRaining;
      
      if (rainValue == 0) {
        condition = WeatherCondition.clear;
        intensity = 0.0;
        isRaining = false;
      } else if (rainValue < 2.5) {
        condition = WeatherCondition.lightRain;
        intensity = 0.3;
        isRaining = true;
      } else if (rainValue < 10) {
        condition = WeatherCondition.lightRain;
        intensity = 0.6;
        isRaining = true;
      } else {
        condition = WeatherCondition.heavyRain;
        intensity = 0.9;
        isRaining = true;
      }

      // Calculate volatility multiplier based on weather
      final volatilityMultiplier = _calculateVolatilityMultiplier(condition, intensity);

      _currentWeather = WeatherState(
        condition: condition,
        intensity: intensity,
        volatilityMultiplier: volatilityMultiplier,
        isRaining: isRaining,
        windSpeed: 0.0, // HKO API doesn't provide wind in this endpoint
        temperature: tempValue,
        lastUpdated: DateTime.now(),
        description: _getWeatherDescription(condition, intensity),
      );

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing HKO data: $e');
      }
      _generateMockWeatherData();
    }
  }

  /// Generate realistic mock weather data for development/testing
  void _generateMockWeatherData() {
    // Realistic Hong Kong weather patterns
    final conditions = [
      WeatherCondition.clear,
      WeatherCondition.lightRain,
      WeatherCondition.heavyRain,
      WeatherCondition.fog,
    ];
    
    // Hong Kong has 60% chance of rain annually
    final isRainy = _random.nextDouble() < 0.6;
    WeatherCondition condition;
    double intensity;

    if (isRainy) {
      condition = _random.nextDouble() < 0.7 
          ? WeatherCondition.lightRain 
          : WeatherCondition.heavyRain;
      intensity = condition == WeatherCondition.lightRain 
          ? 0.3 + _random.nextDouble() * 0.3  // 0.3-0.6
          : 0.6 + _random.nextDouble() * 0.4; // 0.6-1.0
    } else {
      condition = _random.nextDouble() < 0.9 
          ? WeatherCondition.clear 
          : WeatherCondition.fog;
      intensity = condition == WeatherCondition.fog ? 0.4 : 0.0;
    }

    final volatilityMultiplier = _calculateVolatilityMultiplier(condition, intensity);

    _currentWeather = WeatherState(
      condition: condition,
      intensity: intensity,
      volatilityMultiplier: volatilityMultiplier,
      isRaining: condition == WeatherCondition.lightRain || 
                condition == WeatherCondition.heavyRain,
      windSpeed: _random.nextDouble() * 20, // 0-20 km/h
      temperature: 20 + _random.nextInt(15), // 20-35°C typical for HK
      lastUpdated: DateTime.now(),
      description: _getWeatherDescription(condition, intensity),
    );

    notifyListeners();
  }

  /// Calculate volatility multiplier based on weather conditions
  double _calculateVolatilityMultiplier(WeatherCondition condition, double intensity) {
    switch (condition) {
      case WeatherCondition.clear:
        return 1.0;
      case WeatherCondition.lightRain:
        return 1.2 + (intensity * 0.3); // 1.2 - 1.5
      case WeatherCondition.heavyRain:
        return 1.5 + (intensity * 0.5); // 1.5 - 2.0
      case WeatherCondition.fog:
        return 1.1 + (intensity * 0.2); // 1.1 - 1.3
      case WeatherCondition.storm:
        return 2.0 + (intensity * 0.5); // 2.0 - 2.5
    }
  }

  /// Get human-readable weather description
  String _getWeatherDescription(WeatherCondition condition, double intensity) {
    switch (condition) {
      case WeatherCondition.clear:
        return 'Clear skies';
      case WeatherCondition.lightRain:
        return intensity < 0.5 ? 'Light rain' : 'Moderate rain';
      case WeatherCondition.heavyRain:
        return 'Heavy rain';
      case WeatherCondition.fog:
        return 'Foggy conditions';
      case WeatherCondition.storm:
        return 'Thunderstorm';
    }
  }

  /// Enable manual weather toggle for prototype testing
  void enableManualToggleMode() {
    _isManualToggleMode = true;
    _updateTimer?.cancel();
    
    // Start automatic toggle every 30 seconds for demo purposes
    _mockToggleTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      toggleWeather();
    });
  }

  /// Disable manual mode and return to automatic updates
  void disableManualToggleMode() {
    _isManualToggleMode = false;
    _mockToggleTimer?.cancel();
    _startPeriodicUpdates();
  }

  /// Toggle between rain and clear weather (for prototype demo)
  void toggleWeather() {
    if (_currentWeather.isRaining) {
      // Switch to clear
      _currentWeather = WeatherState(
        condition: WeatherCondition.clear,
        intensity: 0.0,
        volatilityMultiplier: 1.0,
        isRaining: false,
        windSpeed: 5.0,
        temperature: 26,
        lastUpdated: DateTime.now(),
        description: 'Clear Hong Kong skies',
      );
    } else {
      // Switch to rain
      final intensity = 0.4 + _random.nextDouble() * 0.4; // 0.4-0.8
      _currentWeather = WeatherState(
        condition: WeatherCondition.lightRain,
        intensity: intensity,
        volatilityMultiplier: 1.2 + (intensity * 0.3),
        isRaining: true,
        windSpeed: 10.0 + _random.nextDouble() * 10,
        temperature: 22 + _random.nextInt(6),
        lastUpdated: DateTime.now(),
        description: 'Hong Kong rain showers',
      );
    }
    notifyListeners();
  }

  /// Force weather update (useful for testing)
  void forceUpdate() {
    _updateWeather();
  }

  /// Get ink efficiency bonus based on weather
  /// Rain provides 2x ink efficiency as per research requirements
  double get inkEfficiencyBonus {
    return _currentWeather.isRaining ? 2.0 : 1.0;
  }

  /// Check if weather conditions favor trading
  bool get favorableConditions {
    return _currentWeather.volatilityMultiplier > 1.2;
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _mockToggleTimer?.cancel();
    super.dispose();
  }
}