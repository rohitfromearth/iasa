import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Branded logo shown on splash and auth surfaces.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 120,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppConstants.appLogoAsset,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: AppConstants.appName,
    );
  }
}
