import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.amber).copyWith(
      primary: AppColors.amber,
      onPrimary: AppColors.brown,
      primaryContainer: const Color(0xFFFFE6A8),
      onPrimaryContainer: AppColors.brown,
      secondary: AppColors.green,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFD6EFD9),
      onSecondaryContainer: const Color(0xFF103D19),
      error: AppColors.coral,
      surface: AppColors.cream,
      onSurface: AppColors.brown,
      onSurfaceVariant: AppColors.brownSoft,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: AppColors.creamCard,
      surfaceContainer: const Color(0xFFFBF5EA),
      surfaceContainerHigh: AppColors.creamHigh,
      surfaceContainerHighest: AppColors.creamHighest,
      outline: const Color(0xFF8A7563),
      outlineVariant: AppColors.creamOutline,
    );
    return _build(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.amber,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.amber,
      onPrimary: AppColors.brown,
      primaryContainer: const Color(0xFF5A4300),
      onPrimaryContainer: const Color(0xFFFFE6A8),
      secondary: const Color(0xFF5CC26F),
      onSecondary: const Color(0xFF0B2E12),
      secondaryContainer: const Color(0xFF1F4A28),
      onSecondaryContainer: const Color(0xFFD6EFD9),
      error: AppColors.coral,
      surface: AppColors.darkBackground,
      onSurface: AppColors.cream,
      onSurfaceVariant: const Color(0xFFCDBFAE),
      surfaceContainerLowest: const Color(0xFF140E08),
      surfaceContainerLow: const Color(0xFF221811),
      surfaceContainer: AppColors.darkSurface,
      surfaceContainerHigh: AppColors.darkHigh,
      surfaceContainerHighest: AppColors.darkHighest,
      outline: const Color(0xFF9C8B79),
      outlineVariant: AppColors.darkOutline,
    );
    return _build(scheme);
  }

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
    );
    final text = GoogleFonts.nunitoTextTheme(base.textTheme).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: scheme.outlineVariant),
    );
    return base.copyWith(
      textTheme: text.copyWith(
        headlineSmall:
            text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: rounded,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: scheme.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primary,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(
          text.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
        selectedColor: scheme.primary,
        checkmarkColor: scheme.onPrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}
