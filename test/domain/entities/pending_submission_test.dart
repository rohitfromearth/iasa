import 'package:flutter_test/flutter_test.dart';
import 'package:iasa/domain/entities/pending_submission.dart';
import 'package:iasa/domain/enums/sync_status.dart';
import 'package:iasa/domain/enums/user_role.dart';

void main() {
  final createdAt = DateTime.utc(2026, 1, 1);

  PendingSubmission buildSubmission() => PendingSubmission(
        id: 'submission-uuid-1',
        title: 'New case',
        questionBody: 'Question text',
        submittedByRole: UserRole.warrior,
        syncStatus: SyncStatus.pending,
        attemptCount: 0,
        createdAt: createdAt,
      );

  test('copyWith tracks retry metadata', () {
    final original = buildSubmission();
    final retried = original.copyWith(
      syncStatus: SyncStatus.failed,
      attemptCount: 1,
      lastAttemptAt: DateTime.utc(2026, 1, 2),
      lastError: 'Network timeout',
    );

    expect(original.attemptCount, 0);
    expect(retried.attemptCount, 1);
    expect(retried.lastError, 'Network timeout');
  });

  test('equality is value-based', () {
    expect(buildSubmission(), equals(buildSubmission()));
  });
}
