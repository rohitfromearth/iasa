import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography scale for headings, titles, body text, and captions.
abstract final class AppTypography {
  static const String _fontFamily = 'Roboto';

  static const TextStyle heading = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.25,
    color: AppColors.gray900,
  );

  static const TextStyle title = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.gray900,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.gray800,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.gray600,
  );

  static const TextStyle small = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    color: AppColors.gray600,
  );

  static TextTheme get textTheme => const TextTheme(
        displaySmall: heading,
        headlineMedium: heading,
        titleLarge: title,
        titleMedium: title,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: caption,
        labelLarge: body,
        labelMedium: caption,
        labelSmall: small,
      );
}
