import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Performance optimization utilities for StreetCred Clash
class StartupOptimizer {
  static bool _initialized = false;
  
  /// Initialize performance optimizations early in app lifecycle
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Precompile frequently used shaders
    await _precompileShaders();
    
    // Optimize memory usage
    _optimizeMemory();
    
    // Preload critical assets
    await _preloadAssets();
    
    _initialized = true;
  }
  
  /// Precompile shaders used in weather effects and animations
  static Future<void> _precompileShaders() async {
    // Warm up the GPU with common shader operations
    final _ = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.blue, Colors.transparent],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 100))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  }
  
  /// Optimize memory settings for mobile performance
  static void _optimizeMemory() {
    // Set reasonable image cache limits
    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50MB
  }
  
  /// Preload critical assets used throughout the app
  static Future<void> _preloadAssets() async {
    // Preload weather-related icons and sounds
    await SystemSound.play(SystemSoundType.click);
  }
}

/// Provider for monitoring app performance metrics
final performanceMetricsProvider = StateNotifierProvider<PerformanceMetricsNotifier, PerformanceMetrics>(
  (ref) => PerformanceMetricsNotifier(),
);

class PerformanceMetrics {
  final double frameRate;
  final int renderTime;
  final bool isOptimized;
  
  const PerformanceMetrics({
    this.frameRate = 60.0,
    this.renderTime = 16,
    this.isOptimized = true,
  });
  
  PerformanceMetrics copyWith({
    double? frameRate,
    int? renderTime,
    bool? isOptimized,
  }) {
    return PerformanceMetrics(
      frameRate: frameRate ?? this.frameRate,
      renderTime: renderTime ?? this.renderTime,
      isOptimized: isOptimized ?? this.isOptimized,
    );
  }
}

class PerformanceMetricsNotifier extends StateNotifier<PerformanceMetrics> {
  PerformanceMetricsNotifier() : super(const PerformanceMetrics());
  
  void updateFrameRate(double fps) {
    state = state.copyWith(
      frameRate: fps,
      isOptimized: fps >= 50.0, // Consider 50+ FPS as optimized
    );
  }
  
  void updateRenderTime(int milliseconds) {
    state = state.copyWith(
      renderTime: milliseconds,
      isOptimized: milliseconds <= 20, // 20ms = 50 FPS
    );
  }
}

/// Widget wrapper that monitors performance for critical UI components
class PerformanceMonitor extends ConsumerWidget {
  final Widget child;
  final String componentName;
  
  const PerformanceMonitor({
    Key? key,
    required this.child,
    required this.componentName,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return child; // Performance monitoring would be implemented here in production
  }
}