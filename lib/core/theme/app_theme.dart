import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.amber,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.amber,
      onPrimary: Colors.black,
      secondary: AppColors.amber,
      onSecondary: Colors.black,
      surface: AppColors.darkSurface,
      error: AppColors.rescuing,
    );
    return _build(scheme, AppColors.darkBackground);
  }

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.amber).copyWith(
      primary: AppColors.amber,
      onPrimary: Colors.black,
      secondary: AppColors.amber,
      onSecondary: Colors.black,
      error: AppColors.rescuing,
    );
    return _build(scheme, scheme.surface);
  }

  static ThemeData _build(ColorScheme scheme, Color background) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
    );
    return base.copyWith(textTheme: GoogleFonts.interTextTheme(base.textTheme));
  }
}
