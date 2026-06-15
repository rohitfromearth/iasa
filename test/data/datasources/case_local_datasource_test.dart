import 'package:flutter_test/flutter_test.dart';
import 'package:iasa/data/datasources/local/case_local_datasource.dart';
import 'package:iasa/data/models/case_model.dart';
import 'package:iasa/data/models/pending_submission_model.dart';
import 'package:iasa/domain/entities/submission_attachment.dart';
import 'package:iasa/domain/entities/submission_photo.dart';
import 'package:iasa/domain/enums/case_status.dart';
import 'package:iasa/domain/enums/sync_status.dart';
import 'package:iasa/domain/enums/user_role.dart';

import '../../helpers/test_database.dart';

void main() {
  late CaseLocalDataSource dataSource;

  setUpAll(initTestDatabaseFactory);

  setUp(() async {
    final db = await createTestDatabase();
    dataSource = CaseLocalDataSource(() async => db);
  });

  group('CaseLocalDataSource persistence', () {
    test('persists and reads pending submissions', () async {
      final submission = PendingSubmissionModel(
        id: 'pending-1',
        title: 'Chest pain',
        questionBody: 'Intermittent pain',
        submittedByRole: UserRole.warrior,
        syncStatus: SyncStatus.pending,
        attemptCount: 0,
        createdAt: DateTime.utc(2026, 6, 1),
      );

      await dataSource.insertPendingSubmission(submission);
      final pending = await dataSource.getPendingSubmissions();

      expect(pending, hasLength(1));
      expect(pending.first.id, 'pending-1');
      expect(pending.first.syncStatus, SyncStatus.pending);
    });

    test('persists and reads pending submissions with local media', () async {
      final submission = PendingSubmissionModel(
        id: 'pending-media',
        title: 'Skin rash',
        questionBody: 'Red patches for two days',
        submittedByRole: UserRole.warrior,
        syncStatus: SyncStatus.pending,
        attemptCount: 0,
        createdAt: DateTime.utc(2026, 6, 1),
        photos: [
          SubmissionPhoto(
            id: 'photo-1',
            localPath: '/tmp/photo-1.jpg',
            addedAt: DateTime.utc(2026, 6, 1, 10),
          ),
        ],
        attachments: [
          SubmissionAttachment(
            id: 'attachment-1',
            localPath: '/tmp/report.pdf',
            fileName: 'report.pdf',
            extension: 'pdf',
            addedAt: DateTime.utc(2026, 6, 1, 11),
          ),
        ],
      );

      await dataSource.insertPendingSubmission(submission);
      final pending = await dataSource.getPendingSubmissions();

      expect(pending, hasLength(1));
      expect(pending.first.photos, hasLength(1));
      expect(pending.first.photos.first.localPath, '/tmp/photo-1.jpg');
      expect(pending.first.attachments, hasLength(1));
      expect(pending.first.attachments.first.fileName, 'report.pdf');
    });

    test('upserts and reads cases ordered by updatedAt', () async {
      final older = CaseModel(
        id: 'case-1',
        title: 'Older',
        questionBody: 'Q1',
        status: CaseStatus.submitted,
        createdByRole: UserRole.warrior,
        syncStatus: SyncStatus.synced,
        createdAt: DateTime.utc(2026, 6, 1),
        updatedAt: DateTime.utc(2026, 6, 1),
      );
      final newer = CaseModel(
        id: 'case-2',
        title: 'Newer',
        questionBody: 'Q2',
        status: CaseStatus.submitted,
        createdByRole: UserRole.warrior,
        syncStatus: SyncStatus.synced,
        createdAt: DateTime.utc(2026, 6, 2),
        updatedAt: DateTime.utc(2026, 6, 3),
      );

      await dataSource.upsertCase(older);
      await dataSource.upsertCase(newer);

      final cases = await dataSource.getAllCases();

      expect(cases, hasLength(2));
      expect(cases.first.id, 'case-2');
      expect(cases.last.id, 'case-1');
    });

    test('resetStuckSyncingSubmissions moves syncing rows back to pending', () async {
      final submission = PendingSubmissionModel(
        id: 'pending-syncing',
        title: 'Stuck',
        questionBody: 'Body',
        submittedByRole: UserRole.warrior,
        syncStatus: SyncStatus.syncing,
        attemptCount: 1,
        createdAt: DateTime.utc(2026, 6, 1),
      );

      await dataSource.insertPendingSubmission(submission);
      await dataSource.resetStuckSyncingSubmissions();

      final pending = await dataSource.getPendingSubmissions();
      expect(pending, hasLength(1));
      expect(pending.first.syncStatus, SyncStatus.pending);
    });
  });
}
