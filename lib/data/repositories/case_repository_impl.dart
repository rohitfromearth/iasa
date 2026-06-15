import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../core/utils/result.dart';
import '../../core/utils/uuid_generator.dart';
import '../../domain/entities/case_entity.dart';
import '../../domain/entities/pending_submission.dart';
import '../../domain/enums/case_status.dart';
import '../../domain/enums/sync_status.dart';
import '../../domain/repositories/case_repository.dart';
import '../../domain/value_objects/submit_question_params.dart';
import '../../domain/value_objects/sync_result.dart';
import '../datasources/local/case_local_datasource.dart';
import '../datasources/remote/api_datasource.dart';
import '../models/case_model.dart';
import '../models/media_upload_item.dart';
import '../models/pending_submission_model.dart';

class CaseRepositoryImpl implements CaseRepository {
  CaseRepositoryImpl({
    required CaseLocalDataSource localDataSource,
    required ApiDataSource apiDataSource,
    required this._networkInfo,
    required this._uuidGenerator,
  })  : _local = localDataSource,
        _api = apiDataSource;

  final CaseLocalDataSource _local;
  final ApiDataSource _api;
  final NetworkInfo _networkInfo;
  final UuidGenerator _uuidGenerator;

  @override
  Future<Result<List<CaseEntity>>> getCases() async {
    try {
      final cases = await _local.getAllCases();
      return Success(cases.map((model) => model.toEntity()).toList());
    } on DatabaseException catch (e) {
      return Error(DatabaseFailure(e.message));
    } catch (e) {
      return Error(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<PendingSubmission>>> getPendingSubmissions() async {
    try {
      final submissions = await _local.getPendingSubmissions();
      return Success(submissions.map((model) => model.toEntity()).toList());
    } on DatabaseException catch (e) {
      return Error(DatabaseFailure(e.message));
    } catch (e) {
      return Error(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Result<PendingSubmission>> submitQuestion(
    SubmitQuestionParams params,
  ) async {
    try {
      final now = DateTime.now().toUtc();
      final submission = PendingSubmission(
        id: _uuidGenerator.generate(),
        caseId: params.caseId,
        title: params.title,
        questionBody: params.questionBody,
        submittedByRole: params.submittedByRole,
        syncStatus: SyncStatus.pending,
        attemptCount: 0,
        createdAt: now,
        photos: params.photos,
        attachments: params.attachments,
      );

      await _local.insertPendingSubmission(
        PendingSubmissionModel.fromEntity(submission),
      );

      return Success(submission);
    } on DatabaseException catch (e) {
      return Error(DatabaseFailure(e.message));
    } catch (e) {
      return Error(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Result<SyncResult>> syncPendingSubmissions() async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure('No network connection'));
    }

    try {
      await _local.resetStuckSyncingSubmissions();
      final submissions = await _local.getPendingSubmissions();

      var syncedCount = 0;
      var failedCount = 0;

      for (final submissionModel in submissions) {
        final submission = submissionModel.toEntity();
        final attemptAt = DateTime.now().toUtc();

        await _local.updatePendingSubmission(
          PendingSubmissionModel.fromEntity(
            submission.copyWith(syncStatus: SyncStatus.syncing),
          ),
        );

        try {
          final remoteCase = await _api.submitQuestion(
            idempotencyKey: submission.id,
            title: submission.title,
            questionBody: submission.questionBody,
            submittedByRole: submission.submittedByRole,
            caseId: submission.caseId,
          );

          final mediaItems = [
            ...submission.photos.map(MediaUploadItem.fromPhoto),
            ...submission.attachments.map(MediaUploadItem.fromAttachment),
          ];
          if (mediaItems.isNotEmpty) {
            await _api.uploadSubmissionMedia(
              submissionId: submission.id,
              items: mediaItems,
            );
            await _local.markSubmissionMediaUploaded(
              submissionId: submission.id,
              uploadedAt: attemptAt,
            );
          }

          final syncedCase = _mergeSyncedCase(remoteCase, attemptAt);
          await _local.upsertCase(syncedCase);

          await _local.updatePendingSubmission(
            PendingSubmissionModel.fromEntity(
              submission.copyWith(
                syncStatus: SyncStatus.synced,
                caseId: submission.caseId ?? remoteCase.id,
                attemptCount: submission.attemptCount + 1,
                lastAttemptAt: attemptAt,
                clearLastError: true,
              ),
            ),
          );
          syncedCount++;
        } on NetworkException catch (e) {
          await _markSubmissionFailed(submission, attemptAt, e.message);
          failedCount++;
        } catch (e) {
          await _markSubmissionFailed(submission, attemptAt, e.toString());
          failedCount++;
        }
      }

      return Success(
        SyncResult(syncedCount: syncedCount, failedCount: failedCount),
      );
    } on DatabaseException catch (e) {
      return Error(DatabaseFailure(e.message));
    } catch (e) {
      return Error(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<CaseEntity>>> refreshCases() async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure('No network connection'));
    }

    try {
      final remoteCases = await _api.fetchCases();
      final refreshedAt = DateTime.now().toUtc();

      for (final remoteCase in remoteCases) {
        final localCase = await _local.getCaseById(remoteCase.id);
        await _local.upsertCase(
          _mergeRemoteCase(
            remoteCase: remoteCase,
            localCase: localCase,
            refreshedAt: refreshedAt,
          ),
        );
      }

      final localCases = await _local.getAllCases();
      return Success(localCases.map((model) => model.toEntity()).toList());
    } on NetworkException catch (e) {
      return Error(NetworkFailure(e.message));
    } on DatabaseException catch (e) {
      return Error(DatabaseFailure(e.message));
    } catch (e) {
      return Error(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Result<CaseEntity>> updateLocalCaseStatus({
    required String caseId,
    required CaseStatus status,
  }) async {
    try {
      final existing = await _local.getCaseById(caseId);
      if (existing == null) {
        return const Error(UnexpectedFailure('Case not found'));
      }

      final now = DateTime.now().toUtc();
      final updated = CaseModel(
        id: existing.id,
        title: existing.title,
        questionBody: existing.questionBody,
        answerBody: existing.answerBody,
        status: status,
        onlineStatus: existing.onlineStatus ?? existing.status,
        createdByRole: existing.createdByRole,
        syncStatus: SyncStatus.pending,
        createdAt: existing.createdAt,
        updatedAt: now,
        lastSyncedAt: existing.lastSyncedAt,
        verifiedAt: existing.verifiedAt,
      );

      await _local.upsertCase(updated);
      return Success(updated.toEntity());
    } on DatabaseException catch (e) {
      return Error(DatabaseFailure(e.message));
    } catch (e) {
      return Error(UnexpectedFailure(e.toString()));
    }
  }

  CaseModel _mergeRemoteCase({
    required CaseModel remoteCase,
    required CaseModel? localCase,
    required DateTime refreshedAt,
  }) {
    final hasPendingLocalStatus =
        localCase != null && localCase.syncStatus == SyncStatus.pending;

    if (hasPendingLocalStatus) {
      return CaseModel(
        id: remoteCase.id,
        title: remoteCase.title,
        questionBody: remoteCase.questionBody,
        answerBody: remoteCase.answerBody ?? localCase.answerBody,
        status: localCase.status,
        onlineStatus: remoteCase.status,
        createdByRole: remoteCase.createdByRole,
        syncStatus: SyncStatus.pending,
        createdAt: remoteCase.createdAt,
        updatedAt: localCase.updatedAt,
        lastSyncedAt: refreshedAt,
        verifiedAt: remoteCase.verifiedAt ?? localCase.verifiedAt,
      );
    }

    return CaseModel(
      id: remoteCase.id,
      title: remoteCase.title,
      questionBody: remoteCase.questionBody,
      answerBody: remoteCase.answerBody,
      status: remoteCase.status,
      onlineStatus: remoteCase.status,
      createdByRole: remoteCase.createdByRole,
      syncStatus: SyncStatus.synced,
      createdAt: remoteCase.createdAt,
      updatedAt: remoteCase.updatedAt,
      lastSyncedAt: refreshedAt,
      verifiedAt: remoteCase.verifiedAt,
    );
  }

  CaseModel _mergeSyncedCase(CaseModel remoteCase, DateTime syncedAt) {
    return CaseModel(
      id: remoteCase.id,
      title: remoteCase.title,
      questionBody: remoteCase.questionBody,
      answerBody: remoteCase.answerBody,
      status: remoteCase.status,
      onlineStatus: remoteCase.status,
      createdByRole: remoteCase.createdByRole,
      syncStatus: SyncStatus.synced,
      createdAt: remoteCase.createdAt,
      updatedAt: syncedAt,
      lastSyncedAt: syncedAt,
      verifiedAt: remoteCase.verifiedAt,
    );
  }

  Future<void> _markSubmissionFailed(
    PendingSubmission submission,
    DateTime attemptAt,
    String error,
  ) async {
    await _local.updatePendingSubmission(
      PendingSubmissionModel.fromEntity(
        submission.copyWith(
          syncStatus: SyncStatus.failed,
          attemptCount: submission.attemptCount + 1,
          lastAttemptAt: attemptAt,
          lastError: error,
        ),
      ),
    );
  }
}
