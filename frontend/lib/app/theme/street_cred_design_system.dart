import 'package:flutter/material.dart';
import 'street_cred_theme.dart';

/// Unified design system based on asset selection screen patterns
class StreetCredDesignSystem {
  // Border Radius System
  static const double radiusLarge = 30.0; // Major cards
  static const double radiusMedium = 16.0; // Secondary cards
  static const double radiusSmall = 12.0; // Info cards
  static const double radiusButton = 30.0; // Fully rounded

  // Spacing System
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 30.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationGlow = Duration(seconds: 2);

  // Border Widths
  static const double borderThin = 1.0;
  static const double borderMedium = 2.0;
  static const double borderThick = 3.0;

  /// Creates a dynamic background gradient based on theme color
  static BoxDecoration backgroundGradient(Color themeColor) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          themeColor.withValues(alpha: 0.1),
          StreetCredTheme.darkAlley,
          StreetCredTheme.darkGrey,
        ],
      ),
    );
  }

  /// Creates the signature card decoration from asset selection
  static BoxDecoration cardDecoration({
    required Color themeColor,
    bool isSelected = false,
    bool isPressed = false,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          themeColor.withValues(alpha: isSelected ? 0.4 : 0.2),
          themeColor.withValues(alpha: isSelected ? 0.2 : 0.1),
          StreetCredTheme.darkGrey.withValues(alpha: 0.9),
        ],
      ),
      borderRadius: BorderRadius.circular(radiusLarge),
      border: Border.all(
        color: themeColor,
        width: isSelected ? borderThick : borderMedium,
      ),
      boxShadow: [
        // Base glow
        BoxShadow(
          color: themeColor.withValues(alpha: isSelected ? 0.6 : 0.2),
          blurRadius: isSelected ? 30 : 15,
          spreadRadius: isSelected ? 5 : 2,
        ),
        // Press effect - additional intense glow
        if (isPressed && isSelected)
          BoxShadow(
            color: themeColor.withValues(alpha: 0.8),
            blurRadius: 40,
            spreadRadius: 8,
          ),
      ],
    );
  }

  /// Creates secondary card decoration
  static BoxDecoration secondaryCardDecoration(Color themeColor) {
    return BoxDecoration(
      color: StreetCredTheme.darkAlley.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(radiusMedium),
      border: Border.all(
        color: themeColor.withValues(alpha: 0.3),
        width: borderThin,
      ),
    );
  }

  /// Creates header container decoration
  static BoxDecoration headerDecoration(Color themeColor) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          themeColor.withValues(alpha: 0.3),
          themeColor.withValues(alpha: 0.1),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(radiusSmall),
      border: Border.all(
        color: themeColor.withValues(alpha: 0.5),
        width: borderThin,
      ),
    );
  }

  /// Creates button decoration with glow
  static BoxDecoration buttonDecoration({
    required Color themeColor,
    required double glowIntensity,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [themeColor, themeColor.withValues(alpha: 0.8)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(radiusButton),
      boxShadow: [
        BoxShadow(
          color: themeColor.withValues(alpha: glowIntensity * 0.6),
          blurRadius: 25,
          spreadRadius: 3,
        ),
      ],
    );
  }

  /// Creates status badge decoration
  static BoxDecoration statusBadgeDecoration(Color themeColor) {
    return BoxDecoration(
      color: themeColor.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(radiusSmall),
      border: Border.all(color: themeColor, width: borderThin),
      boxShadow: [
        BoxShadow(
          color: themeColor.withValues(alpha: 0.3),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ],
    );
  }

  /// Creates navigation button decoration
  static BoxDecoration navigationButtonDecoration(Color themeColor) {
    return BoxDecoration(
      color: themeColor.withValues(alpha: 0.2),
      shape: BoxShape.circle,
      border: Border.all(color: themeColor, width: borderMedium),
      boxShadow: [
        BoxShadow(
          color: themeColor.withValues(alpha: 0.3),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ],
    );
  }

  /// Typography styles matching asset selection
  static TextStyle titleStyle(Color themeColor) {
    return StreetCredTheme.graffitiTitle.copyWith(
      fontSize: 22,
      letterSpacing: 2,
      color: themeColor,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          color: themeColor.withValues(alpha: 0.6),
          blurRadius: 10,
          offset: const Offset(0, 0),
        ),
      ],
    );
  }

  static TextStyle subtitleStyle(Color themeColor) {
    return StreetCredTheme.graffitiSubtitle.copyWith(
      fontSize: 18,
      color: themeColor,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle bodyStyle() {
    return StreetCredTheme.graffitiBody.copyWith(
      fontSize: 14,
      color: Colors.white,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle captionStyle() {
    return StreetCredTheme.graffitiBody.copyWith(
      fontSize: 12,
      color: Colors.grey[400],
      fontWeight: FontWeight.w400,
    );
  }

  /// Page indicator decoration
  static BoxDecoration indicatorDecoration({
    required Color themeColor,
    required bool isSelected,
  }) {
    return BoxDecoration(
      color: isSelected ? themeColor : Colors.grey[600],
      borderRadius: BorderRadius.circular(6),
      boxShadow: isSelected
          ? [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ]
          : null,
    );
  }

  /// Performance-based color selection
  static Color getPerformanceColor(double value) {
    if (value > 0) return StreetCredTheme.longColor;
    if (value < 0) return StreetCredTheme.shortColor;
    return StreetCredTheme.neutralColor;
  }

  /// Ranking-based color selection
  static Color getRankingColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return StreetCredTheme.neonBlue;
    }
  }

  /// Asset-specific colors
  static Color getAssetColor(String symbol) {
    switch (symbol.toUpperCase()) {
      case 'BTC':
        return const Color(0xFFF7931A);
      case 'ETH':
        return const Color(0xFF627EEA);
      case 'STRK':
        return const Color(0xFF8C8DFC);
      default:
        return StreetCredTheme.neonPink;
    }
  }
}
