import 'package:flutter/material.dart';

import '../../domain/entities/case_entity.dart';
import '../../domain/enums/sync_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'case_status_display.dart';

/// Card tile for a case in list views.
class CaseCard extends StatelessWidget {
  const CaseCard({
    super.key,
    required this.caseEntity,
    required this.onTap,
  });

  final CaseEntity caseEntity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      caseEntity.title,
                      style: AppTypography.title.copyWith(
                        color: AppColors.gray900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  CaseStatusDisplay(caseEntity: caseEntity, compact: true),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatUpdatedDate(caseEntity.updatedAt),
                      style: AppTypography.small.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                  ),
                  _SyncIndicator(syncStatus: caseEntity.syncStatus),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatUpdatedDate(DateTime updatedAt) {
    final local = updatedAt.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return 'Updated $local.year-$month-$day';
  }
}

class _SyncIndicator extends StatelessWidget {
  const _SyncIndicator({required this.syncStatus});

  final SyncStatus syncStatus;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (syncStatus) {
      SyncStatus.pending => (
          Icons.cloud_off_outlined,
          'Pending sync',
          AppColors.warningOrange,
        ),
      SyncStatus.syncing => (
          Icons.sync,
          'Syncing',
          AppColors.primaryBlue,
        ),
      SyncStatus.synced => (
          Icons.cloud_done_outlined,
          'Synced',
          AppColors.successGreen,
        ),
      SyncStatus.failed => (
          Icons.cloud_off_outlined,
          'Sync failed',
          AppColors.errorRed,
        ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (syncStatus == SyncStatus.syncing)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: SizedBox(
              width: AppSpacing.md,
              height: AppSpacing.md,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            ),
          )
        else
          Icon(icon, size: AppSpacing.md, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.small.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
