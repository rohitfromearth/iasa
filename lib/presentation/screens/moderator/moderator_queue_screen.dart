import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/ui_state.dart';
import '../../../domain/entities/case_entity.dart';
import '../../navigation/app_navigator.dart';
import '../../providers/case_list_provider.dart';
import '../../theme/app_spacing.dart';
import '../../utils/sync_queue_helper.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/case_card.dart';
import '../../widgets/ui_state_view.dart';

class ModeratorQueueScreen extends StatefulWidget {
  const ModeratorQueueScreen({super.key});

  @override
  State<ModeratorQueueScreen> createState() => _ModeratorQueueScreenState();
}

class _ModeratorQueueScreenState extends State<ModeratorQueueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaseListProvider>().loadCases();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Moderator Queue',
      showBackButton: false,
      showLogout: true,
      body: Selector<CaseListProvider, UiState<List<CaseEntity>>>(
        selector: (_, provider) => provider.moderatorQueueState,
        builder: (_, state, _) {
          return RefreshIndicator(
            onRefresh: () => syncQueueAndReload(context),
            child: UiStateView<List<CaseEntity>>(
              state: state,
              loadingMessage: 'Loading queue...',
              emptyMessage: 'No open cases in queue',
              onRetry: () => context.read<CaseListProvider>().loadCases(),
              successBuilder: (cases) => ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: cases.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final caseEntity = cases[index];
                  return CaseCard(
                    caseEntity: caseEntity,
                    onTap: () =>
                        AppNavigator.openUpdateStatus(context, caseEntity.id),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
