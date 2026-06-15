import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Labeled content block for case detail and similar screens.
class DetailSection extends StatelessWidget {
  const DetailSection({
    super.key,
    required this.title,
    required this.body,
    this.icon,
  });

  final String title;
  final String body;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppSpacing.lg, color: AppColors.primaryBlue),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  title,
                  style: AppTypography.title.copyWith(
                    fontSize: 18,
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              style: AppTypography.body.copyWith(color: AppColors.gray800),
            ),
          ],
        ),
      ),
    );
  }
}
