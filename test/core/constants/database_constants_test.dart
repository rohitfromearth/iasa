import 'package:flutter_test/flutter_test.dart';
import 'package:iasa/core/constants/database_constants.dart';

void main() {
  group('DatabaseConstants', () {
    test('schemaV1Statements creates both tables and all indexes', () {
      expect(DatabaseConstants.schemaV1Statements, hasLength(11));
      expect(
        DatabaseConstants.schemaV1Statements.first,
        contains(DatabaseConstants.tableCases),
      );
      expect(
        DatabaseConstants.schemaV1Statements[1],
        contains(DatabaseConstants.tablePendingSubmissions),
      );
    });

    test('cases table defines expected columns', () {
      final ddl = DatabaseConstants.createCasesTable;

      expect(ddl, contains(DatabaseConstants.colId));
      expect(ddl, contains(DatabaseConstants.colTitle));
      expect(ddl, contains(DatabaseConstants.colQuestionBody));
      expect(ddl, contains(DatabaseConstants.colAnswerBody));
      expect(ddl, contains(DatabaseConstants.colStatus));
      expect(ddl, contains(DatabaseConstants.colOnlineStatus));
      expect(ddl, contains(DatabaseConstants.colCreatedByRole));
      expect(ddl, contains(DatabaseConstants.colSyncStatus));
      expect(ddl, contains(DatabaseConstants.colCreatedAt));
      expect(ddl, contains(DatabaseConstants.colUpdatedAt));
      expect(ddl, contains(DatabaseConstants.colLastSyncedAt));
      expect(ddl, contains(DatabaseConstants.colVerifiedAt));
      expect(ddl, isNot(contains('server_id')));
      expect(ddl, isNot(contains('is_dirty')));
    });

    test('pending_submissions table defines foreign key to cases', () {
      final ddl = DatabaseConstants.createPendingSubmissionsTable;

      expect(ddl, contains(DatabaseConstants.colId));
      expect(ddl, contains(DatabaseConstants.colCaseId));
      expect(ddl, contains(DatabaseConstants.colAttemptCount));
      expect(ddl, contains(DatabaseConstants.colLastError));
      expect(
        ddl,
        contains(
          'FOREIGN KEY (${DatabaseConstants.colCaseId}) '
          'REFERENCES ${DatabaseConstants.tableCases}(${DatabaseConstants.colId})',
        ),
      );
    });

    test('pending submission media tables reference pending_submissions', () {
      expect(
        DatabaseConstants.createPendingSubmissionPhotosTable,
        contains(DatabaseConstants.tablePendingSubmissionPhotos),
      );
      expect(
        DatabaseConstants.createPendingSubmissionAttachmentsTable,
        contains(DatabaseConstants.tablePendingSubmissionAttachments),
      );
      expect(
        DatabaseConstants.createPendingSubmissionPhotosTable,
        contains(
          'REFERENCES ${DatabaseConstants.tablePendingSubmissions}',
        ),
      );
    });

    test('schemaV3 migration creates media tables and indexes', () {
      expect(DatabaseConstants.schemaV3MigrationStatements, hasLength(4));
    });

    test('schemaV4 migration adds upload status columns', () {
      expect(DatabaseConstants.schemaV4MigrationStatements, hasLength(4));
      expect(
        DatabaseConstants.addPhotoUploadStatusColumn,
        contains(DatabaseConstants.colUploadStatus),
      );
    });

    test('schema does not include sync_queue', () {
      for (final statement in DatabaseConstants.schemaV1Statements) {
        expect(statement.toLowerCase(), isNot(contains('sync_queue')));
      }
    });

    test('foreign keys pragma is defined', () {
      expect(DatabaseConstants.enableForeignKeys, 'PRAGMA foreign_keys = ON');
    });
  });
}
