import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/ui_state.dart';
import '../../../domain/entities/case_entity.dart';
import '../../../domain/enums/case_status.dart';
import '../../providers/case_detail_provider.dart';
import '../../providers/case_list_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/case_status_display.dart';
import '../../widgets/status_selector.dart';
import '../../widgets/ui_state_view.dart';

class UpdateStatusScreen extends StatefulWidget {
  const UpdateStatusScreen({super.key, required this.caseId});

  final String caseId;

  @override
  State<UpdateStatusScreen> createState() => _UpdateStatusScreenState();
}

class _UpdateStatusScreenState extends State<UpdateStatusScreen> {
  CaseStatus? _selectedStatus;
  _SavePhase _savePhase = _SavePhase.initial;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaseDetailProvider>().loadCase(widget.caseId);
    });
  }

  Future<void> _saveStatus() async {
    final selected = _selectedStatus;
    if (selected == null) {
      setState(() => _savePhase = _SavePhase.error);
      return;
    }

    setState(() => _savePhase = _SavePhase.loading);
    await context.read<CaseDetailProvider>().updateCaseStatus(selected);

    if (!mounted) {
      return;
    }

    final updateError = context.read<CaseDetailProvider>().updateError;
    setState(() {
      _savePhase = updateError == null ? _SavePhase.success : _SavePhase.error;
    });

    if (updateError == null) {
      await context.read<CaseListProvider>().loadCases();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Update Status',
      body: Selector<
          CaseDetailProvider,
          (UiState<CaseEntity>, bool, String?)>(
        selector: (_, provider) => (
          provider.state,
          provider.isUpdating,
          provider.updateError,
        ),
        builder: (_, data, _) {
          final (loadState, isUpdating, updateError) = data;
          final isSaving = _savePhase == _SavePhase.loading || isUpdating;

          return UiStateView<CaseEntity>(
            state: loadState,
            loadingMessage: 'Loading case...',
            emptyMessage: 'Case not found',
            onRetry: () =>
                context.read<CaseDetailProvider>().loadCase(widget.caseId),
            successBuilder: (caseEntity) {
              final selectedStatus = _selectedStatus ?? caseEntity.status;
              final providerError = updateError;

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        _CaseSummaryCard(caseEntity: caseEntity),
                        const SizedBox(height: AppSpacing.md),
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: CaseStatusDisplay(caseEntity: caseEntity),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        StatusSelector(
                          value: selectedStatus,
                          enabled: !isSaving,
                          onChanged: (status) {
                            setState(() {
                              _selectedStatus = status;
                              if (_savePhase == _SavePhase.error) {
                                _savePhase = _SavePhase.initial;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (_savePhase == _SavePhase.loading)
                          const _UpdateStatusMessage(
                            icon: Icons.hourglass_top_rounded,
                            message: 'Updating status...',
                            color: AppColors.primaryBlue,
                            showProgress: true,
                          ),
                        if (_savePhase == _SavePhase.error) ...[
                          _UpdateStatusMessage(
                            icon: Icons.error_outline_rounded,
                            message: providerError ??
                                'Select a status and save to update this case.',
                            color: AppColors.errorRed,
                          ),
                        ],
                        if (_savePhase == _SavePhase.success)
                          const _UpdateStatusMessage(
                            icon: Icons.check_circle_outline_rounded,
                            message:
                                'Local status saved. Online status unchanged until sync.',
                            color: AppColors.successGreen,
                          ),
                        if (_savePhase == _SavePhase.initial)
                          Text(
                            'Choose a new local status. Online status stays as last confirmed from server.',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.gray600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: PrimaryButton(
                      label: 'Save Status',
                      onPressed: _saveStatus,
                      isLoading: isSaving,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

enum _SavePhase { initial, loading, error, success }

class _CaseSummaryCard extends StatelessWidget {
  const _CaseSummaryCard({required this.caseEntity});

  final CaseEntity caseEntity;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Case Summary',
            style: AppTypography.title.copyWith(
              fontSize: 18,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            caseEntity.title,
            style: AppTypography.title.copyWith(color: AppColors.gray900),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            caseEntity.questionBody,
            style: AppTypography.body.copyWith(color: AppColors.gray700),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _UpdateStatusMessage extends StatelessWidget {
  const _UpdateStatusMessage({
    required this.icon,
    required this.message,
    required this.color,
    this.showProgress = false,
  });

  final IconData icon;
  final String message;
  final Color color;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showProgress)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: SizedBox(
                width: AppSpacing.lg,
                height: AppSpacing.lg,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              ),
            )
          else
            Icon(icon, color: color, size: AppSpacing.lg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption.copyWith(
                color: AppColors.gray800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
