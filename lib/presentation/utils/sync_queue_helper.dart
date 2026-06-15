import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/result.dart';
import '../providers/case_list_provider.dart';
import '../providers/submission_provider.dart';

/// Syncs the pending outbox, pulls remote cases when online, and updates UI.
Future<bool> syncQueueAndReload(BuildContext context) async {
  final submissionProvider = context.read<SubmissionProvider>();
  final caseListProvider = context.read<CaseListProvider>();

  final syncResult = await submissionProvider.syncPendingSubmissions();
  if (syncResult is! Success || !context.mounted) {
    return false;
  }

  await submissionProvider.hydratePendingSubmissions();
  if (!context.mounted) {
    return false;
  }

  await caseListProvider.refreshCases();
  return true;
}

/// Pull-to-refresh entry point: sync outbox, refresh remote cases, update list.
Future<void> refreshCasesFromPull(BuildContext context) async {
  await syncQueueAndReload(context);
}
