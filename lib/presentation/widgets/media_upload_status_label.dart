import 'package:flutter/material.dart';

import '../../domain/enums/sync_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Shows local vs online upload state for submission media.
class MediaUploadStatusLabel extends StatelessWidget {
  const MediaUploadStatusLabel({
    super.key,
    required this.uploadStatus,
    this.uploadedAt,
  });

  final SyncStatus uploadStatus;
  final DateTime? uploadedAt;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (uploadStatus) {
      SyncStatus.synced => ('Online: uploaded (demo)', AppColors.successGreen),
      SyncStatus.failed => ('Online: upload failed', AppColors.errorRed),
      SyncStatus.syncing => ('Online: uploading…', AppColors.warningOrange),
      SyncStatus.pending => ('Online: not uploaded yet', AppColors.warningOrange),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Local: saved on device',
          style: AppTypography.small.copyWith(color: AppColors.gray600),
        ),
        Text(
          label,
          style: AppTypography.small.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
