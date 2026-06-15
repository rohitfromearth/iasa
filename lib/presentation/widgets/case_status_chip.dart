import 'package:flutter/material.dart';

import '../../domain/enums/case_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Chip displaying the workflow status of a healthcare case.
class CaseStatusChip extends StatelessWidget {
  const CaseStatusChip({super.key, required this.status});

  final CaseStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = switch (status) {
      CaseStatus.submitted => (
          'Submitted',
          AppColors.primaryBlue,
          AppColors.primaryBlueLight.withValues(alpha: 0.2),
        ),
      CaseStatus.inReview => (
          'In Review',
          AppColors.warningOrange,
          AppColors.warningOrangeLight,
        ),
      CaseStatus.underDiscussion => (
          'Under Discussion',
          AppColors.gray700,
          AppColors.gray200,
        ),
      CaseStatus.answered => (
          'Answered',
          AppColors.successGreen,
          AppColors.successGreenLight,
        ),
      CaseStatus.rejected => (
          'Rejected',
          AppColors.errorRed,
          AppColors.errorRedLight,
        ),
      CaseStatus.closed => (
          'Closed',
          AppColors.gray600,
          AppColors.gray100,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTypography.small.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
