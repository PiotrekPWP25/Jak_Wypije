import 'package:flutter/material.dart';

/// Brand palette taken from the JakWypiję logo.
abstract final class AppColors {
  /// Beer amber – primary accent (#FFB300).
  static const Color amber = Color(0xFFFFB300);

  /// Route / map pin green – "on the plan", "OK", calm areas.
  static const Color green = Color(0xFF2E9E44);

  /// Coral – crowds and warnings.
  static const Color coral = Color(0xFFFF6F61);

  /// Indigo – night quiet zones and night transport.
  static const Color night = Color(0xFF5C6BC0);

  // Darker variants for TEXT on light (cream) surfaces – the brand amber,
  // green and coral are too light for text there (contrast ≥ 4.5:1 here).
  static const Color amberDeep = Color(0xFF8A5A00);
  static const Color greenDeep = Color(0xFF1E6B2F);
  static const Color coralDeep = Color(0xFFB23A2C);

  /// Accent colour for text: amber on dark surfaces, deep amber on light.
  static Color accentText(Brightness brightness) =>
      brightness == Brightness.dark ? amber : amberDeep;

  /// Logo outline brown.
  static const Color brown = Color(0xFF3B2314);
  static const Color brownSoft = Color(0xFF6B5443);

  /// Neutral for popular (non-highlighted) bars.
  static const Color regular = Color(0xFF8D7B6A);

  static const Color userLocation = Color(0xFF42A5F5);

  // Light (cream) surfaces.
  static const Color cream = Color(0xFFF7F1E5);
  static const Color creamCard = Color(0xFFFFFBF3);
  static const Color creamHigh = Color(0xFFF1E8D8);
  static const Color creamHighest = Color(0xFFEADFCB);
  static const Color creamOutline = Color(0xFFDCCDB8);

  // Dark (roasted) surfaces.
  static const Color darkBackground = Color(0xFF1A120B);
  static const Color darkSurface = Color(0xFF2A1F16);
  static const Color darkHigh = Color(0xFF33271C);
  static const Color darkHighest = Color(0xFF3D3024);
  static const Color darkOutline = Color(0xFF4A3B2E);

  // Trophy tiers.
  static const Color bronze = Color(0xFFCD7F32);
  static const Color silver = Color(0xFFB0B7BF);
  static const Color gold = Color(0xFFFFC83D);
}
