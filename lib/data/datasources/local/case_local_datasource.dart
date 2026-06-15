import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../../core/constants/database_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/errors/exceptions.dart';
import '../../../domain/enums/sync_status.dart';
import '../../../domain/entities/submission_attachment.dart';
import '../../../domain/entities/submission_photo.dart';
import '../../models/case_model.dart';
import '../../models/pending_submission_model.dart';
import '../../models/submission_attachment_model.dart';
import '../../models/submission_photo_model.dart';

class CaseLocalDataSource {
  CaseLocalDataSource(this._databaseProvider);

  final Future<Database> Function() _databaseProvider;

  factory CaseLocalDataSource.fromHelper([DatabaseHelper? helper]) {
    final databaseHelper = helper ?? DatabaseHelper.instance;
    return CaseLocalDataSource(() => databaseHelper.database);
  }

  Future<CaseModel?> getCaseById(String id) async {
    try {
      final db = await _databaseProvider();
      final rows = await db.query(
        DatabaseConstants.tableCases,
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        return null;
      }
      return CaseModel.fromMap(rows.first);
    } catch (e) {
      throw DatabaseException('Failed to read case: $e');
    }
  }

  Future<List<CaseModel>> getAllCases() async {
    try {
      final db = await _databaseProvider();
      final rows = await db.query(
        DatabaseConstants.tableCases,
        orderBy: '${DatabaseConstants.colUpdatedAt} DESC',
      );
      return rows.map(CaseModel.fromMap).toList();
    } catch (e) {
      throw DatabaseException('Failed to read cases: $e');
    }
  }

  Future<void> upsertCase(CaseModel caseModel) async {
    try {
      final db = await _databaseProvider();
      await db.insert(
        DatabaseConstants.tableCases,
        caseModel.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Failed to upsert case: $e');
    }
  }

  Future<void> insertPendingSubmission(PendingSubmissionModel submission) async {
    try {
      final db = await _databaseProvider();
      await db.transaction((txn) async {
        await txn.insert(
          DatabaseConstants.tablePendingSubmissions,
          submission.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        for (final photo in submission.photos) {
          await txn.insert(
            DatabaseConstants.tablePendingSubmissionPhotos,
            SubmissionPhotoModel.fromEntity(
              entity: photo,
              submissionId: submission.id,
            ).toMap(),
          );
        }

        for (final attachment in submission.attachments) {
          await txn.insert(
            DatabaseConstants.tablePendingSubmissionAttachments,
            SubmissionAttachmentModel.fromEntity(
              entity: attachment,
              submissionId: submission.id,
            ).toMap(),
          );
        }
      });
    } catch (e) {
      throw DatabaseException('Failed to insert pending submission: $e');
    }
  }

  Future<List<PendingSubmissionModel>> getPendingSubmissions() async {
    try {
      final db = await _databaseProvider();
      final rows = await db.query(
        DatabaseConstants.tablePendingSubmissions,
        where: '${DatabaseConstants.colSyncStatus} IN (?, ?)',
        whereArgs: [SyncStatus.pending.name, SyncStatus.failed.name],
        orderBy: DatabaseConstants.colCreatedAt,
      );

      if (rows.isEmpty) {
        return const [];
      }

      final submissions =
          rows.map(PendingSubmissionModel.fromMap).toList(growable: false);
      final submissionIds = submissions.map((submission) => submission.id).toList();
      final placeholders = List.filled(submissionIds.length, '?').join(',');

      final photoRows = await db.query(
        DatabaseConstants.tablePendingSubmissionPhotos,
        where: '${DatabaseConstants.colSubmissionId} IN ($placeholders)',
        whereArgs: submissionIds,
        orderBy: DatabaseConstants.colAddedAt,
      );
      final attachmentRows = await db.query(
        DatabaseConstants.tablePendingSubmissionAttachments,
        where: '${DatabaseConstants.colSubmissionId} IN ($placeholders)',
        whereArgs: submissionIds,
        orderBy: DatabaseConstants.colAddedAt,
      );

      final photosBySubmission = _groupPhotos(photoRows);
      final attachmentsBySubmission = _groupAttachments(attachmentRows);

      return submissions
          .map(
            (submission) => submission.copyWithMedia(
              photos: photosBySubmission[submission.id] ?? const [],
              attachments: attachmentsBySubmission[submission.id] ?? const [],
            ),
          )
          .toList(growable: false);
    } catch (e) {
      throw DatabaseException('Failed to read pending submissions: $e');
    }
  }

  Future<void> updatePendingSubmission(PendingSubmissionModel submission) async {
    try {
      final db = await _databaseProvider();
      final updated = await db.update(
        DatabaseConstants.tablePendingSubmissions,
        submission.toMap(),
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [submission.id],
      );
      if (updated == 0) {
        throw DatabaseException('Pending submission not found: ${submission.id}');
      }
    } on DatabaseException {
      rethrow;
    } catch (e) {
      throw DatabaseException('Failed to update pending submission: $e');
    }
  }

  Future<void> resetStuckSyncingSubmissions() async {
    try {
      final db = await _databaseProvider();
      await db.update(
        DatabaseConstants.tablePendingSubmissions,
        {DatabaseConstants.colSyncStatus: SyncStatus.pending.name},
        where: '${DatabaseConstants.colSyncStatus} = ?',
        whereArgs: [SyncStatus.syncing.name],
      );
    } catch (e) {
      throw DatabaseException('Failed to reset stuck submissions: $e');
    }
  }

  Future<void> markSubmissionMediaUploaded({
    required String submissionId,
    required DateTime uploadedAt,
  }) async {
    try {
      final db = await _databaseProvider();
      final values = {
        DatabaseConstants.colUploadStatus: SyncStatus.synced.name,
        DatabaseConstants.colUploadedAt: uploadedAt.millisecondsSinceEpoch,
      };

      await db.update(
        DatabaseConstants.tablePendingSubmissionPhotos,
        values,
        where: '${DatabaseConstants.colSubmissionId} = ?',
        whereArgs: [submissionId],
      );
      await db.update(
        DatabaseConstants.tablePendingSubmissionAttachments,
        values,
        where: '${DatabaseConstants.colSubmissionId} = ?',
        whereArgs: [submissionId],
      );
    } catch (e) {
      throw DatabaseException('Failed to update media upload status: $e');
    }
  }

  Map<String, List<SubmissionPhoto>> _groupPhotos(
    List<Map<String, Object?>> rows,
  ) {
    final grouped = <String, List<SubmissionPhoto>>{};
    for (final row in rows) {
      final model = SubmissionPhotoModel.fromMap(row);
      grouped.putIfAbsent(model.submissionId, () => []).add(model.toEntity());
    }
    return grouped;
  }

  Map<String, List<SubmissionAttachment>> _groupAttachments(
    List<Map<String, Object?>> rows,
  ) {
    final grouped = <String, List<SubmissionAttachment>>{};
    for (final row in rows) {
      final model = SubmissionAttachmentModel.fromMap(row);
      grouped
          .putIfAbsent(model.submissionId, () => [])
          .add(model.toEntity());
    }
    return grouped;
  }
}
