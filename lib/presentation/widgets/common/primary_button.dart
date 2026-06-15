import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Primary call-to-action button with loading support.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            height: AppSpacing.lg,
            width: AppSpacing.lg,
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
        : icon == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: AppSpacing.md + AppSpacing.xs),
                  const SizedBox(width: AppSpacing.sm),
                  Text(label),
                ],
              );

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: child,
    );
  }
}
