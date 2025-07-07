import 'package:flutter/material.dart';

// Animation constants for consistent timing and values across the app
class AnimationConstants {
  // Timing constants
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 600);
  static const Duration extraLongAnimation = Duration(milliseconds: 1000);
  
  // XP Animation specific
  static const Duration xpFillDuration = Duration(milliseconds: 800);
  static const Duration xpGlowDuration = Duration(milliseconds: 1000);
  static const Duration xpPopupDuration = Duration(milliseconds: 600);
  static const Duration confettiDuration = Duration(milliseconds: 2000);
  
  // Scale constants
  static const double minScale = 0.8;
  static const double maxScale = 1.2;
  static const double pulseScale = 1.1;
  static const double levelUpScale = 1.5;
  
  // Opacity constants
  static const double minOpacity = 0.0;
  static const double maxOpacity = 1.0;
  static const double ghostOpacity = 0.3;
  static const double glowOpacity = 0.7;
  
  // Spacing constants
  static const double tinySpacing = 4.0;
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;
  
  // Animation curves
  static const Curve elasticCurve = Curves.elasticOut;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;
  static const Curve quickCurve = Curves.easeOutQuart;
}