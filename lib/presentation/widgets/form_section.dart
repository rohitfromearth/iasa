import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Groups a labeled form field inside a Material 3 card.
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.child,
    this.title,
    this.helperText,
  });

  final Widget child;
  final String? title;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: AppTypography.title.copyWith(
                  fontSize: 18,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            child,
            if (helperText != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                helperText!,
                style: AppTypography.small.copyWith(color: AppColors.gray600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
