/// SQLite table, column, index, and DDL constants.
///
/// Exposed as testable strings so schema shape can be verified without a device DB.
abstract final class DatabaseConstants {
  // ---------------------------------------------------------------------------
  // Tables
  // ---------------------------------------------------------------------------

  static const String tableCases = 'cases';
  static const String tablePendingSubmissions = 'pending_submissions';
  static const String tablePendingSubmissionPhotos = 'pending_submission_photos';
  static const String tablePendingSubmissionAttachments =
      'pending_submission_attachments';

  // ---------------------------------------------------------------------------
  // cases columns
  // ---------------------------------------------------------------------------

  static const String colId = 'id';
  static const String colTitle = 'title';
  static const String colQuestionBody = 'question_body';
  static const String colAnswerBody = 'answer_body';
  static const String colStatus = 'status';
  static const String colOnlineStatus = 'online_status';
  static const String colCreatedByRole = 'created_by_role';
  static const String colSyncStatus = 'sync_status';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';
  static const String colLastSyncedAt = 'last_synced_at';
  static const String colVerifiedAt = 'verified_at';

  // ---------------------------------------------------------------------------
  // pending_submissions columns
  // ---------------------------------------------------------------------------

  static const String colCaseId = 'case_id';
  static const String colSubmittedByRole = 'submitted_by_role';
  static const String colAttemptCount = 'attempt_count';
  static const String colLastAttemptAt = 'last_attempt_at';
  static const String colLastError = 'last_error';

  // ---------------------------------------------------------------------------
  // pending_submission media columns
  // ---------------------------------------------------------------------------

  static const String colSubmissionId = 'submission_id';
  static const String colLocalPath = 'local_path';
  static const String colAddedAt = 'added_at';
  static const String colFileName = 'file_name';
  static const String colExtension = 'extension';
  static const String colUploadStatus = 'upload_status';
  static const String colUploadedAt = 'uploaded_at';

  // ---------------------------------------------------------------------------
  // Indexes
  // ---------------------------------------------------------------------------

  static const String idxCasesStatus = 'idx_cases_status';
  static const String idxCasesSyncStatus = 'idx_cases_sync_status';
  static const String idxCasesUpdatedAt = 'idx_cases_updated_at';
  static const String idxPendingSyncStatus = 'idx_pending_sync_status';
  static const String idxPendingCaseId = 'idx_pending_case_id';
  static const String idxPendingPhotoSubmissionId =
      'idx_pending_photo_submission_id';
  static const String idxPendingAttachmentSubmissionId =
      'idx_pending_attachment_submission_id';

  // ---------------------------------------------------------------------------
  // DDL
  // ---------------------------------------------------------------------------

  static const String createCasesTable = '''
CREATE TABLE $tableCases (
  $colId              TEXT    NOT NULL PRIMARY KEY,
  $colTitle           TEXT    NOT NULL,
  $colQuestionBody    TEXT    NOT NULL,
  $colAnswerBody      TEXT,
  $colStatus          TEXT    NOT NULL,
  $colOnlineStatus    TEXT,
  $colCreatedByRole    TEXT    NOT NULL,
  $colSyncStatus      TEXT    NOT NULL DEFAULT 'pending',
  $colCreatedAt       INTEGER NOT NULL,
  $colUpdatedAt       INTEGER NOT NULL,
  $colLastSyncedAt    INTEGER,
  $colVerifiedAt      INTEGER
)''';

  static const String createPendingSubmissionsTable = '''
CREATE TABLE $tablePendingSubmissions (
  $colId                TEXT    NOT NULL PRIMARY KEY,
  $colCaseId            TEXT,
  $colTitle             TEXT    NOT NULL,
  $colQuestionBody      TEXT    NOT NULL,
  $colSubmittedByRole   TEXT    NOT NULL,
  $colSyncStatus        TEXT    NOT NULL DEFAULT 'pending',
  $colAttemptCount      INTEGER NOT NULL DEFAULT 0,
  $colLastAttemptAt     INTEGER,
  $colLastError         TEXT,
  $colCreatedAt         INTEGER NOT NULL,
  FOREIGN KEY ($colCaseId) REFERENCES $tableCases($colId) ON DELETE SET NULL
)''';

  static const String createPendingSubmissionPhotosTable = '''
CREATE TABLE $tablePendingSubmissionPhotos (
  $colId              TEXT    NOT NULL PRIMARY KEY,
  $colSubmissionId    TEXT    NOT NULL,
  $colLocalPath       TEXT    NOT NULL,
  $colAddedAt         INTEGER NOT NULL,
  $colUploadStatus    TEXT    NOT NULL DEFAULT 'pending',
  $colUploadedAt      INTEGER,
  FOREIGN KEY ($colSubmissionId) REFERENCES $tablePendingSubmissions($colId)
    ON DELETE CASCADE
)''';

  static const String createPendingSubmissionAttachmentsTable = '''
CREATE TABLE $tablePendingSubmissionAttachments (
  $colId              TEXT    NOT NULL PRIMARY KEY,
  $colSubmissionId    TEXT    NOT NULL,
  $colLocalPath       TEXT    NOT NULL,
  $colFileName        TEXT    NOT NULL,
  $colExtension       TEXT    NOT NULL,
  $colAddedAt         INTEGER NOT NULL,
  $colUploadStatus    TEXT    NOT NULL DEFAULT 'pending',
  $colUploadedAt      INTEGER,
  FOREIGN KEY ($colSubmissionId) REFERENCES $tablePendingSubmissions($colId)
    ON DELETE CASCADE
)''';

  static const String createIndexCasesStatus =
      'CREATE INDEX $idxCasesStatus ON $tableCases($colStatus)';

  static const String createIndexCasesSyncStatus =
      'CREATE INDEX $idxCasesSyncStatus ON $tableCases($colSyncStatus)';

  static const String createIndexCasesUpdatedAt =
      'CREATE INDEX $idxCasesUpdatedAt ON $tableCases($colUpdatedAt DESC)';

  static const String createIndexPendingSyncStatus =
      'CREATE INDEX $idxPendingSyncStatus ON $tablePendingSubmissions($colSyncStatus, $colCreatedAt)';

  static const String createIndexPendingCaseId =
      'CREATE INDEX $idxPendingCaseId ON $tablePendingSubmissions($colCaseId)';

  static const String createIndexPendingPhotoSubmissionId =
      'CREATE INDEX $idxPendingPhotoSubmissionId '
      'ON $tablePendingSubmissionPhotos($colSubmissionId)';

  static const String createIndexPendingAttachmentSubmissionId =
      'CREATE INDEX $idxPendingAttachmentSubmissionId '
      'ON $tablePendingSubmissionAttachments($colSubmissionId)';

  /// Ordered DDL statements executed on first database creation.
  static const List<String> schemaV1Statements = [
    createCasesTable,
    createPendingSubmissionsTable,
    createPendingSubmissionPhotosTable,
    createPendingSubmissionAttachmentsTable,
    createIndexCasesStatus,
    createIndexCasesSyncStatus,
    createIndexCasesUpdatedAt,
    createIndexPendingSyncStatus,
    createIndexPendingCaseId,
    createIndexPendingPhotoSubmissionId,
    createIndexPendingAttachmentSubmissionId,
  ];

  /// DDL applied when upgrading existing databases to version 3.
  static const List<String> schemaV3MigrationStatements = [
    createPendingSubmissionPhotosTable,
    createPendingSubmissionAttachmentsTable,
    createIndexPendingPhotoSubmissionId,
    createIndexPendingAttachmentSubmissionId,
  ];

  static const String addPhotoUploadStatusColumn =
      'ALTER TABLE $tablePendingSubmissionPhotos '
      'ADD COLUMN $colUploadStatus TEXT NOT NULL DEFAULT \'pending\'';

  static const String addPhotoUploadedAtColumn =
      'ALTER TABLE $tablePendingSubmissionPhotos '
      'ADD COLUMN $colUploadedAt INTEGER';

  static const String addAttachmentUploadStatusColumn =
      'ALTER TABLE $tablePendingSubmissionAttachments '
      'ADD COLUMN $colUploadStatus TEXT NOT NULL DEFAULT \'pending\'';

  static const String addAttachmentUploadedAtColumn =
      'ALTER TABLE $tablePendingSubmissionAttachments '
      'ADD COLUMN $colUploadedAt INTEGER';

  /// DDL applied when upgrading existing databases to version 4.
  static const List<String> schemaV4MigrationStatements = [
    addPhotoUploadStatusColumn,
    addPhotoUploadedAtColumn,
    addAttachmentUploadStatusColumn,
    addAttachmentUploadedAtColumn,
  ];

  static const String enableForeignKeys = 'PRAGMA foreign_keys = ON';
}
