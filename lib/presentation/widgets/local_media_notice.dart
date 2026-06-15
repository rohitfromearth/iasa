import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Explains local-first media storage and demo upload on sync.
class LocalMediaNotice extends StatelessWidget {
  const LocalMediaNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningOrangeLight,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.warningOrange.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.warningOrange,
            size: AppSpacing.lg,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Files are stored locally when added. Demo upload to the mock server '
              'runs when you sync — local and online upload status are shown separately.',
              style: AppTypography.caption.copyWith(color: AppColors.gray800),
            ),
          ),
        ],
      ),
    );
  }
}
