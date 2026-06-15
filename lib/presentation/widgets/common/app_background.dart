import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../theme/app_colors.dart';

/// Full-screen blurred background used across the application shell.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  static const double _blurSigma = 8;
  static const double _overlayOpacity = 0.2;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AppConstants.aboutBackgroundAsset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: _blurSigma,
              sigmaY: _blurSigma,
            ),
            child: Container(
              color: AppColors.white.withValues(alpha: _overlayOpacity),
            ),
          ),
        ),
      ],
    );
  }
}
