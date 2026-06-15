import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/network_info.dart';
import '../../../core/state/ui_state.dart';
import '../../../domain/entities/case_entity.dart';
import '../../providers/case_detail_provider.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/case_status_display.dart';
import '../../widgets/detail_section.dart';
import '../../widgets/offline_answer_banner.dart';
import '../../widgets/sync_metadata_panel.dart';
import '../../widgets/ui_state_view.dart';

class CaseDetailScreen extends StatefulWidget {
  const CaseDetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  bool? _isConnected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCase());
  }

  Future<void> _loadCase() async {
    final detailProvider = context.read<CaseDetailProvider>();
    final networkInfo = context.read<NetworkInfo>();
    await detailProvider.loadCase(widget.caseId);
    final connected = await networkInfo.isConnected;
    if (!mounted) {
      return;
    }
    setState(() => _isConnected = connected);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Case Detail',
      body: Selector<CaseDetailProvider, UiState<CaseEntity>>(
        selector: (_, provider) => provider.state,
        builder: (_, state, _) {
          return UiStateView<CaseEntity>(
            state: state,
            loadingMessage: 'Loading case...',
            emptyMessage: 'Case not found',
            onRetry: _loadCase,
            successBuilder: (caseEntity) => _CaseDetailBody(
              caseEntity: caseEntity,
              showOfflineWarning:
                  caseEntity.answerBody != null && _isConnected == false,
            ),
          );
        },
      ),
    );
  }
}

class _CaseDetailBody extends StatelessWidget {
  const _CaseDetailBody({
    required this.caseEntity,
    required this.showOfflineWarning,
  });

  final CaseEntity caseEntity;
  final bool showOfflineWarning;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          caseEntity.title,
          style: AppTypography.heading.copyWith(fontSize: 24),
        ),
        const SizedBox(height: AppSpacing.md),
        DetailSection(
          title: 'Question',
          body: caseEntity.questionBody,
          icon: Icons.help_outline_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        DetailSection(
          title: 'Answer',
          body: caseEntity.answerBody ?? 'No answer yet',
          icon: Icons.chat_bubble_outline_rounded,
        ),
        if (showOfflineWarning) ...[
          const SizedBox(height: AppSpacing.md),
          const OfflineAnswerBanner(),
        ],
        const SizedBox(height: AppSpacing.md),
        CaseStatusDisplay(caseEntity: caseEntity),
        const SizedBox(height: AppSpacing.md),
        SyncMetadataPanel(
          lastSyncedAt: caseEntity.lastSyncedAt,
          verifiedAt: caseEntity.verifiedAt,
        ),
      ],
    );
  }
}
