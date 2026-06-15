import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/ui_state.dart';
import '../../../domain/entities/case_entity.dart';
import '../../navigation/app_navigator.dart';
import '../../providers/case_list_provider.dart';
import '../../providers/submission_provider.dart';
import '../../theme/app_spacing.dart';
import '../../utils/sync_queue_helper.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/case_card.dart';
import '../../widgets/pending_sync_banner.dart';
import '../../widgets/ui_state_view.dart';

class CaseListScreen extends StatefulWidget {
  const CaseListScreen({super.key});

  @override
  State<CaseListScreen> createState() => _CaseListScreenState();
}

class _CaseListScreenState extends State<CaseListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaseListProvider>().loadCases();
    });
  }

  Future<void> _syncQueue() async {
    final synced = await syncQueueAndReload(context);
    if (!mounted) {
      return;
    }
    if (synced) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Queue synchronized. Cases updated.'),
        ),
      );
    } else {
      final error = context.read<SubmissionProvider>().lastError;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'My Cases',
      showBackButton: false,
      showLogout: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppNavigator.openSubmitQuestion(context),
        icon: const Icon(Icons.add),
        label: const Text('Submit Question'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Selector<SubmissionProvider, (int, bool)>(
            selector: (_, provider) =>
                (provider.pendingSubmissionCount, provider.isSyncing),
            builder: (_, data, _) {
              final (pendingCount, isSyncing) = data;
              if (pendingCount <= 0) {
                return const SizedBox.shrink();
              }
              return PendingSyncBanner(
                pendingCount: pendingCount,
                isSyncing: isSyncing,
                onSync: _syncQueue,
              );
            },
          ),
          Expanded(
            child: Selector<CaseListProvider, UiState<List<CaseEntity>>>(
              selector: (_, provider) => provider.state,
              builder: (_, state, _) {
                return RefreshIndicator(
                  onRefresh: () async {
                    await syncQueueAndReload(context);
                  },
                  child: UiStateView<List<CaseEntity>>(
                    state: state,
                    loadingMessage: 'Loading cases...',
                    emptyMessage: 'No cases available',
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
                              AppNavigator.openCaseDetail(context, caseEntity.id),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
