import 'package:flutter/material.dart';

import '../../domain/entities/case_entity.dart';
import '../../domain/enums/case_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'case_status_chip.dart';
import 'status_selector.dart';

/// Shows local workflow status alongside last known online status when they differ.
class CaseStatusDisplay extends StatelessWidget {
  const CaseStatusDisplay({
    super.key,
    required this.caseEntity,
    this.compact = false,
  });

  final CaseEntity caseEntity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactStatusDisplay(caseEntity: caseEntity);
    }

    return _ExpandedStatusDisplay(caseEntity: caseEntity);
  }
}

class _CompactStatusDisplay extends StatelessWidget {
  const _CompactStatusDisplay({required this.caseEntity});

  final CaseEntity caseEntity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CaseStatusChip(status: caseEntity.status),
        if (caseEntity.hasUnsyncedStatusChange) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Online: ${statusSelectorLabel(caseEntity.displayOnlineStatus)}',
            style: AppTypography.small.copyWith(color: AppColors.gray600),
            textAlign: TextAlign.right,
          ),
          Text(
            'Not yet synced',
            style: AppTypography.small.copyWith(
              color: AppColors.warningOrange,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ],
    );
  }
}

class _ExpandedStatusDisplay extends StatelessWidget {
  const _ExpandedStatusDisplay({required this.caseEntity});

  final CaseEntity caseEntity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusRow(
          label: 'Local',
          status: caseEntity.status,
        ),
        const SizedBox(height: AppSpacing.sm),
        _StatusRow(
          label: 'Online',
          status: caseEntity.displayOnlineStatus,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          caseEntity.hasUnsyncedStatusChange
              ? 'Online status is ${statusSelectorLabel(caseEntity.displayOnlineStatus)}. '
                  'Local change not yet synced to server.'
              : 'Local and online status match.',
          style: AppTypography.caption.copyWith(
            color: caseEntity.hasUnsyncedStatusChange
                ? AppColors.warningOrange
                : AppColors.gray600,
            fontWeight: caseEntity.hasUnsyncedStatusChange
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.status,
  });

  final String label;
  final CaseStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.gray800,
            ),
          ),
        ),
        CaseStatusChip(status: status),
      ],
    );
  }
}
