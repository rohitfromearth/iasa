import 'package:flutter_test/flutter_test.dart';
import 'package:iasa/core/utils/result.dart';
import 'package:iasa/domain/entities/pending_submission.dart';
import 'package:iasa/domain/enums/sync_status.dart';
import 'package:iasa/domain/enums/user_role.dart';
import 'package:iasa/domain/value_objects/sync_result.dart';
import 'package:iasa/presentation/providers/submission_provider.dart';

import 'provider_test_helpers.dart';

SubmissionProvider _buildProvider({
  Result<List<PendingSubmission>>? pendingResult,
  Result<SyncResult>? syncResult,
  Result<PendingSubmission>? submitResult,
}) {
  return SubmissionProvider(
    submitQuestionUseCase: StubSubmitQuestionUseCase(
      submitResult ?? Success(buildPending(id: 'pending-1')),
    ),
    syncPendingSubmissionsUseCase: StubSyncPendingSubmissionsUseCase(
      syncResult ?? const Success(SyncResult(syncedCount: 0, failedCount: 0)),
    ),
    getPendingSubmissionsUseCase: StubGetPendingSubmissionsUseCase(
      pendingResult ?? const Success([]),
    ),
    roleResolver: () => UserRole.moderator,
  );
}

void main() {
  test('SubmissionProvider submitQuestion tracks queued submission', () async {
    final provider = _buildProvider();

    final result = await provider.submitQuestion(
      title: 'Headache',
      questionBody: 'Pain',
    );

    expect(result, isA<Success>());
    expect(provider.pendingSubmissionCount, 1);
    expect(provider.queuedCount, 1);
    expect(provider.submissions.first.syncStatus, SyncStatus.pending);
  });

  test('SubmissionProvider hydratePendingSubmissions restores persisted outbox',
      () async {
    final provider = _buildProvider(
      pendingResult: Success([
        buildPending(id: 'persisted-1'),
        buildPending(id: 'persisted-2').copyWith(
          syncStatus: SyncStatus.failed,
          lastError: 'Network timeout',
        ),
      ]),
    );

    await provider.hydratePendingSubmissions();

    expect(provider.pendingSubmissionCount, 2);
    expect(provider.queuedCount, 1);
    expect(provider.failedCount, 1);
    expect(provider.submissions.map((item) => item.id),
        containsAll(['persisted-1', 'persisted-2']));
  });

  test('SubmissionProvider syncPendingSubmissions applies synced and failed states',
      () async {
    final provider = _buildProvider(
      syncResult: const Success(SyncResult(syncedCount: 1, failedCount: 0)),
    );

    await provider.submitQuestion(title: 'Headache', questionBody: 'Pain');
    await provider.syncPendingSubmissions();

    expect(provider.syncedCount, 1);
    expect(provider.queuedCount, 0);
    expect(provider.pendingSubmissionCount, 0);
    expect(provider.submissions.first.syncStatus, SyncStatus.synced);
  });

  test('SubmissionProvider syncPendingSubmissions tracks failed retry state',
      () async {
    final provider = _buildProvider(
      syncResult: const Success(SyncResult(syncedCount: 0, failedCount: 1)),
    );

    await provider.submitQuestion(title: 'Headache', questionBody: 'Pain');
    await provider.syncPendingSubmissions();

    expect(provider.failedCount, 1);
    expect(provider.pendingSubmissionCount, 1);
    expect(provider.submissions.first.syncStatus, SyncStatus.failed);
  });
}
