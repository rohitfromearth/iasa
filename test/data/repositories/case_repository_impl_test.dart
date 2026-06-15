import 'package:flutter_test/flutter_test.dart';
import 'package:iasa/core/utils/result.dart';
import 'package:iasa/data/datasources/local/case_local_datasource.dart';
import 'package:iasa/data/models/case_model.dart';
import 'package:iasa/data/repositories/case_repository_impl.dart';
import 'package:iasa/domain/enums/case_status.dart';
import 'package:iasa/domain/enums/sync_status.dart';
import 'package:iasa/domain/enums/user_role.dart';
import 'package:iasa/domain/value_objects/submit_question_params.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_database.dart';

void main() {
  late CaseLocalDataSource localDataSource;
  late FakeNetworkInfo networkInfo;
  late FakeUuidGenerator uuidGenerator;
  late TestApiDataSource apiDataSource;
  late CaseRepositoryImpl repository;

  setUpAll(initTestDatabaseFactory);

  setUp(() async {
    final db = await createTestDatabase();
    localDataSource = CaseLocalDataSource(() async => db);
    networkInfo = FakeNetworkInfo();
    uuidGenerator = FakeUuidGenerator(['uuid-1', 'uuid-2']);
    apiDataSource = TestApiDataSource();
    repository = CaseRepositoryImpl(
      localDataSource: localDataSource,
      apiDataSource: apiDataSource,
      networkInfo: networkInfo,
      uuidGenerator: uuidGenerator,
    );
  });

  group('CaseRepositoryImpl', () {
    test('submitQuestion persists locally without calling API', () async {
      final result = await repository.submitQuestion(
        const SubmitQuestionParams(
          title: 'Headache',
          questionBody: 'Pain for 3 days',
        ),
      );

      expect(result, isA<Success>());
      final submission = (result as Success).data;
      expect(submission.id, 'uuid-1');
      expect(submission.syncStatus, SyncStatus.pending);
      expect(apiDataSource.submittedKeys, isEmpty);

      final pending = await localDataSource.getPendingSubmissions();
      expect(pending, hasLength(1));
      expect(pending.first.id, 'uuid-1');
    });

    test('getPendingSubmissions returns pending and failed outbox rows', () async {
      await repository.submitQuestion(
        const SubmitQuestionParams(
          title: 'Headache',
          questionBody: 'Pain for 3 days',
        ),
      );

      final result = await repository.getPendingSubmissions();

      expect(result, isA<Success>());
      expect((result as Success).data, hasLength(1));
      expect((result as Success).data.first.syncStatus, SyncStatus.pending);
    });

    test('syncPendingSubmissions retries failed submissions', () async {
      await repository.submitQuestion(
        const SubmitQuestionParams(
          title: 'Headache',
          questionBody: 'Pain for 3 days',
        ),
      );

      apiDataSource.failSubmissions = true;
      final firstSync = await repository.syncPendingSubmissions();
      expect(firstSync, isA<Success>());
      expect((firstSync as Success).data.failedCount, 1);
      expect((firstSync as Success).data.syncedCount, 0);

      final failedPending = await localDataSource.getPendingSubmissions();
      expect(failedPending, hasLength(1));
      expect(failedPending.first.syncStatus, SyncStatus.failed);
      expect(failedPending.first.attemptCount, 1);

      apiDataSource.failSubmissions = false;
      final secondSync = await repository.syncPendingSubmissions();
      expect(secondSync, isA<Success>());
      expect((secondSync as Success).data.syncedCount, 1);
      expect((secondSync as Success).data.failedCount, 0);

      final cases = await localDataSource.getAllCases();
      expect(cases, hasLength(1));
      expect(cases.first.id, 'uuid-1');
      expect(apiDataSource.submittedKeys, ['uuid-1', 'uuid-1']);
    });

    test('refreshCases fetches remote cases into local storage', () async {
      apiDataSource.seedCase(
        CaseModel(
          id: 'remote-case-1',
          title: 'Remote case',
          questionBody: 'Remote question',
          status: CaseStatus.answered,
          createdByRole: UserRole.warrior,
          syncStatus: SyncStatus.synced,
          createdAt: DateTime.utc(2026, 6, 1),
          updatedAt: DateTime.utc(2026, 6, 2),
          lastSyncedAt: DateTime.utc(2026, 6, 2),
        ),
      );

      final result = await repository.refreshCases();

      expect(result, isA<Success>());
      final cases = (result as Success).data;
      expect(cases, hasLength(1));
      expect(cases.first.id, 'remote-case-1');
      expect(cases.first.onlineStatus, CaseStatus.answered);
      expect(cases.first.lastSyncedAt, isNotNull);

      final localCases = await localDataSource.getAllCases();
      expect(localCases, hasLength(1));
      expect(localCases.first.id, 'remote-case-1');
    });

    test('updateLocalCaseStatus keeps online status while local status changes',
        () async {
      apiDataSource.seedCase(
        CaseModel(
          id: 'remote-case-1',
          title: 'Remote case',
          questionBody: 'Remote question',
          status: CaseStatus.submitted,
          createdByRole: UserRole.warrior,
          syncStatus: SyncStatus.synced,
          createdAt: DateTime.utc(2026, 6, 1),
          updatedAt: DateTime.utc(2026, 6, 2),
          lastSyncedAt: DateTime.utc(2026, 6, 2),
        ),
      );

      await repository.refreshCases();

      final updateResult = await repository.updateLocalCaseStatus(
        caseId: 'remote-case-1',
        status: CaseStatus.inReview,
      );

      expect(updateResult, isA<Success>());
      final updated = (updateResult as Success).data;
      expect(updated.status, CaseStatus.inReview);
      expect(updated.onlineStatus, CaseStatus.submitted);
      expect(updated.hasUnsyncedStatusChange, isTrue);

      final refreshResult = await repository.refreshCases();
      final refreshed = (refreshResult as Success).data.single;
      expect(refreshed.status, CaseStatus.inReview);
      expect(refreshed.onlineStatus, CaseStatus.submitted);
      expect(refreshed.hasUnsyncedStatusChange, isTrue);
    });
  });
}
