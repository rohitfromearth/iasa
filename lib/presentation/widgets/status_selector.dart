import 'package:flutter/material.dart';

import '../../domain/enums/case_status.dart';

/// Dropdown for selecting a [CaseStatus] workflow value.
class StatusSelector extends StatelessWidget {
  const StatusSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.label = 'New status',
  });

  final CaseStatus value;
  final ValueChanged<CaseStatus> onChanged;
  final bool enabled;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<CaseStatus>(
      key: ValueKey(value),
      initialSelection: value,
      enabled: enabled,
      label: Text(label),
      dropdownMenuEntries: CaseStatus.values
          .map(
            (status) => DropdownMenuEntry(
              value: status,
              label: statusSelectorLabel(status),
            ),
          )
          .toList(),
      onSelected: enabled
          ? (selected) {
              if (selected != null) {
                onChanged(selected);
              }
            }
          : null,
    );
  }
}

/// Human-readable label aligned with [CaseStatusChip] display text.
String statusSelectorLabel(CaseStatus status) => switch (status) {
      CaseStatus.submitted => 'Submitted',
      CaseStatus.inReview => 'In Review',
      CaseStatus.underDiscussion => 'Under Discussion',
      CaseStatus.answered => 'Answered',
      CaseStatus.rejected => 'Rejected',
      CaseStatus.closed => 'Closed',
    };
