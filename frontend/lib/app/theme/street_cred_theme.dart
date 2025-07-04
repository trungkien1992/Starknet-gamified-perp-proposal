import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StreetCredTheme {
  // Neon Color Palette
  static const Color neonPink = Color(0xFFFF0080);
  static const Color neonGreen = Color(0xFF00FF41);
  static const Color neonBlue = Color(0xFF00FFFF);
  static const Color neonPurple = Color(0xFF8A2BE2);
  static const Color neonOrange = Color(0xFFFF6B35);
  static const Color neonYellow = Color(0xFFFFFF00);

  // Dark Background Colors
  static const Color darkAlley = Color(0xFF0A0A0A);
  static const Color darkGrey = Color(0xFF1A1A1A);
  static const Color mediumGrey = Color(0xFF2A2A2A);

  // Trade Direction Colors
  static const Color longColor = neonGreen;
  static const Color shortColor = neonPink;
  static const Color neutralColor = neonBlue;

  // Custom Fonts
  static TextStyle get graffitiTitle => GoogleFonts.orbitron(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: neonPink,
    shadows: [
      Shadow(
        color: neonPink.withValues(alpha: 0.8),
        blurRadius: 10,
        offset: const Offset(0, 0),
      ),
    ],
  );

  static TextStyle get graffitiSubtitle => GoogleFonts.orbitron(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: neonBlue,
    shadows: [
      Shadow(
        color: neonBlue.withValues(alpha: 0.6),
        blurRadius: 5,
        offset: const Offset(0, 0),
      ),
    ],
  );

  static TextStyle get graffitiBody => GoogleFonts.rajdhani(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static TextStyle get inkDisplay => GoogleFonts.orbitron(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: neonYellow,
    shadows: [
      Shadow(
        color: neonYellow.withValues(alpha: 0.8),
        blurRadius: 15,
        offset: const Offset(0, 0),
      ),
      Shadow(
        color: neonOrange.withValues(alpha: 0.6),
        blurRadius: 8,
        offset: const Offset(2, 2),
      ),
    ],
  );

  // Theme Data
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: neonPink,
    scaffoldBackgroundColor: darkAlley,
    appBarTheme: AppBarTheme(
      backgroundColor: darkGrey,
      foregroundColor: neonPink,
      titleTextStyle: graffitiSubtitle,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: mediumGrey,
      elevation: 8,
      shadowColor: neonPink.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: neonPink.withValues(alpha: 0.3), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: neonPink,
        foregroundColor: Colors.white,
        textStyle: graffitiBody,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
        shadowColor: neonPink.withValues(alpha: 0.5),
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: graffitiTitle,
      headlineMedium: graffitiSubtitle,
      bodyLarge: graffitiBody,
      bodyMedium: graffitiBody.copyWith(fontSize: 14),
    ),
  );

  // Custom Gradients
  static const LinearGradient neonGradient = LinearGradient(
    colors: [neonPink, neonPurple, neonBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sprayGradient = LinearGradient(
    colors: [neonGreen, neonBlue, neonPink],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Box Decorations
  static BoxDecoration get neonBorder => BoxDecoration(
    border: Border.all(color: neonPink, width: 2),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: neonPink.withValues(alpha: 0.3),
        blurRadius: 10,
        spreadRadius: 2,
      ),
    ],
  );

  static BoxDecoration get sprayCanDecoration => BoxDecoration(
    gradient: const LinearGradient(
      colors: [darkGrey, mediumGrey],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: neonBlue, width: 3),
    boxShadow: [
      BoxShadow(
        color: neonBlue.withValues(alpha: 0.4),
        blurRadius: 15,
        spreadRadius: 2,
      ),
    ],
  );
}
