import '../../core/utils/result.dart';

import '../entities/case_entity.dart';

import '../entities/pending_submission.dart';

import '../enums/case_status.dart';

import '../value_objects/submit_question_params.dart';

import '../value_objects/sync_result.dart';



abstract interface class CaseRepository {

  Future<Result<List<CaseEntity>>> getCases();



  /// Queues a question locally. Success means persisted to outbox only.

  Future<Result<PendingSubmission>> submitQuestion(SubmitQuestionParams params);

  /// Returns outbox rows in `pending` or `failed` state for UI hydration.

  Future<Result<List<PendingSubmission>>> getPendingSubmissions();

  Future<Result<SyncResult>> syncPendingSubmissions();



  Future<Result<List<CaseEntity>>> refreshCases();



  /// Updates local workflow status while preserving last known online status.

  Future<Result<CaseEntity>> updateLocalCaseStatus({

    required String caseId,

    required CaseStatus status,

  });

}


