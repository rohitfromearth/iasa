import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Banner prompting the user to synchronize pending outbox submissions.
class PendingSyncBanner extends StatelessWidget {
  const PendingSyncBanner({
    super.key,
    required this.pendingCount,
    required this.onSync,
    this.isSyncing = false,
  });

  final int pendingCount;
  final VoidCallback? onSync;
  final bool isSyncing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warningOrangeLight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xs,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              color: AppColors.warningOrange,
            ),
            const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
            Expanded(
              child: Text(
                '$pendingCount submission${pendingCount == 1 ? '' : 's'} '
                'waiting to sync',
                style: AppTypography.caption.copyWith(
                  color: AppColors.gray800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            FilledButton.tonal(
              onPressed: isSyncing ? null : onSync,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.warningOrange,
              ),
              child: isSyncing
                  ? const SizedBox(
                      width: AppSpacing.lg - AppSpacing.xs,
                      height: AppSpacing.lg - AppSpacing.xs,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sync Queue'),
            ),
          ],
        ),
      ),
    );
  }
}
