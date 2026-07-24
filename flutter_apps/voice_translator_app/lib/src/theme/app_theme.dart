import 'package:flutter/material.dart';

class AppTheme {
  // Cosmic Dark Colors (Galaxy & Rooms)
  static const Color cosmicBackground = Color(0xFF09071A);
  static const Color cosmicCardBg = Color(0xFF14112E);
  static const Color cosmicCardBorder = Color(0xFF2B2556);
  static const Color cosmicAccentPurple = Color(0xFF7F32FF);
  static const Color cosmicAccentPink = Color(0xFFD946EF);
  static const Color cosmicGlowCyan = Color(0xFF06B6D4);
  
  // Signal Light Colors (Chats)
  static const Color signalBackground = Color(0xFFF7F8FD);
  static const Color signalCardBg = Colors.white;
  static const Color signalTextPrimary = Color(0xFF1E1B4B);
  static const Color signalTextSecondary = Color(0xFF64748B);
  static const Color signalBubbleUser = Color(0xFF6366F1);
  static const Color signalBubbleOther = Color(0xFFF1F5F9);
  
  // Universal Accents
  static const Color onlineGreen = Color(0xFF10B981);
  static const Color liveRed = Color(0xFFEF4444);

  // Linear & Radial Gradients
  static const RadialGradient cosmicOrbitalGlow = RadialGradient(
    colors: [
      Color(0x997F32FF),
      Color(0x333B0764),
      Color(0x0009071A),
    ],
    radius: 0.85,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF7F32FF), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonButtonGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: cosmicBackground,
      colorScheme: const ColorScheme.dark(
        primary: cosmicAccentPurple,
        secondary: cosmicAccentPink,
        surface: cosmicCardBg,
        onSurface: Colors.white,
      ),
      useMaterial3: true,
      cardTheme: CardThemeData(
        color: cosmicCardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: cosmicCardBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: signalBackground,
      colorScheme: const ColorScheme.light(
        primary: signalBubbleUser,
        secondary: cosmicAccentPurple,
        surface: signalCardBg,
        onSurface: signalTextPrimary,
      ),
      useMaterial3: true,
      cardTheme: CardThemeData(
        color: signalCardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
    );
  }
}
