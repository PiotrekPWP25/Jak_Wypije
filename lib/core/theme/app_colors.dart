import 'package:flutter/material.dart';

/// Brand colors used across the app.
abstract final class AppColors {
  /// Amber accent (#FFB300).
  static const Color amber = Color(0xFFFFB300);

  /// Bar saved by the community ("uratowany").
  static const Color saved = Color(0xFF43A047);

  /// Bar currently being rescued ("ratowany").
  static const Color rescuing = Color(0xFFFF6F61);

  /// Popular, well-known bar.
  static const Color regular = Color(0xFF78909C);

  static const Color userLocation = Color(0xFF42A5F5);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1C1C1C);
}
