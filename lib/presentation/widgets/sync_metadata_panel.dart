import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'metadata_tile.dart';

/// Panel showing last synchronization and verification timestamps.
class SyncMetadataPanel extends StatelessWidget {
  const SyncMetadataPanel({
    super.key,
    this.lastSyncedAt,
    this.verifiedAt,
  });

  final DateTime? lastSyncedAt;
  final DateTime? verifiedAt;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Synchronization',
              style: AppTypography.title.copyWith(
                fontSize: 18,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            MetadataTile(
              label: 'Last Synced',
              value: _format(lastSyncedAt) ?? 'Not synchronized',
              icon: Icons.sync,
            ),
            const Divider(height: AppSpacing.lg, color: AppColors.gray200),
            MetadataTile(
              label: 'Verified At',
              value: _format(verifiedAt) ?? 'Not verified',
              icon: Icons.verified_outlined,
            ),
          ],
        ),
      ),
    );
  }

  String? _format(DateTime? value) {
    if (value == null) {
      return null;
    }
    final local = value.toLocal();
    return '${local.year}-${_two(local.month)}-${_two(local.day)} '
        '${_two(local.hour)}:${_two(local.minute)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
