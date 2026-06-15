import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

/// Application theme configuration built on Material 3 design tokens.
abstract final class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryBlue,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.primaryBlueLight,
      onPrimaryContainer: AppColors.primaryBlueDark,
      secondary: AppColors.gray700,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.gray200,
      onSecondaryContainer: AppColors.gray900,
      tertiary: AppColors.successGreen,
      onTertiary: AppColors.white,
      error: AppColors.errorRed,
      onError: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.gray900,
      onSurfaceVariant: AppColors.gray600,
      outline: AppColors.gray300,
      outlineVariant: AppColors.gray200,
      shadow: AppColors.black,
      scrim: AppColors.black,
      inverseSurface: AppColors.gray900,
      onInverseSurface: AppColors.gray100,
      inversePrimary: AppColors.primaryBlueLight,
      surfaceTint: AppColors.primaryBlue,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: AppTypography.textTheme,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: AppColors.white.withValues(alpha: 0.88),
        foregroundColor: AppColors.gray900,
        titleTextStyle: AppTypography.title,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorder,
          side: const BorderSide(color: AppColors.gray200),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonBorder,
          ),
          textStyle: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: const BorderSide(color: AppColors.gray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: const BorderSide(color: AppColors.gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
        labelStyle: AppTypography.caption,
        hintStyle: AppTypography.caption.copyWith(color: AppColors.gray500),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryBlue,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.gray200,
        thickness: 1,
      ),
    );
  }
}
