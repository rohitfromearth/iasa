import 'package:iasa/core/errors/failures.dart';
import 'package:iasa/core/usecases/usecase.dart';
import 'package:iasa/core/utils/result.dart';
import 'package:iasa/domain/entities/case_entity.dart';
import 'package:iasa/domain/entities/pending_submission.dart';
import 'package:iasa/domain/enums/case_status.dart';
import 'package:iasa/domain/enums/sync_status.dart';
import 'package:iasa/domain/enums/user_role.dart';
import 'package:iasa/domain/usecases/get_pending_submissions_usecase.dart';
import 'package:iasa/domain/usecases/get_cases_usecase.dart';
import 'package:iasa/domain/usecases/refresh_cases_usecase.dart';
import 'package:iasa/domain/usecases/submit_question_usecase.dart';
import 'package:iasa/domain/usecases/sync_pending_submissions_usecase.dart';
import 'package:iasa/domain/usecases/update_case_status_usecase.dart';
import 'package:iasa/domain/value_objects/submit_question_params.dart';
import 'package:iasa/domain/value_objects/update_case_status_params.dart';
import 'package:iasa/domain/value_objects/sync_result.dart';

class StubGetCasesUseCase implements GetCasesUseCase {
  StubGetCasesUseCase(this.result);

  Result<List<CaseEntity>> result;

  @override
  Future<Result<List<CaseEntity>>> call(NoParams params) async => result;
}

class StubRefreshCasesUseCase implements RefreshCasesUseCase {
  StubRefreshCasesUseCase(this.result);

  Result<List<CaseEntity>> result;

  @override
  Future<Result<List<CaseEntity>>> call(NoParams params) async => result;
}

class StubSubmitQuestionUseCase implements SubmitQuestionUseCase {
  StubSubmitQuestionUseCase(this.result);

  Result<PendingSubmission> result;

  @override
  Future<Result<PendingSubmission>> call(SubmitQuestionParams params) async =>
      result;
}

class StubSyncPendingSubmissionsUseCase
    implements SyncPendingSubmissionsUseCase {
  StubSyncPendingSubmissionsUseCase(this.result);

  Result<SyncResult> result;

  @override
  Future<Result<SyncResult>> call(NoParams params) async => result;
}

class StubGetPendingSubmissionsUseCase
    implements GetPendingSubmissionsUseCase {
  StubGetPendingSubmissionsUseCase(this.result);

  Result<List<PendingSubmission>> result;

  @override
  Future<Result<List<PendingSubmission>>> call(NoParams params) async =>
      result;
}

class StubUpdateCaseStatusUseCase implements UpdateCaseStatusUseCase {
  StubUpdateCaseStatusUseCase(this.result);

  Result<CaseEntity> result;

  @override
  Future<Result<CaseEntity>> call(UpdateCaseStatusParams params) async =>
      result;
}

CaseEntity buildCase({String id = 'case-1'}) => CaseEntity(
      id: id,
      title: 'Headache',
      questionBody: 'Pain for 3 days',
      status: CaseStatus.submitted,
      createdByRole: UserRole.warrior,
      syncStatus: SyncStatus.synced,
      createdAt: DateTime.utc(2026, 6, 1),
      updatedAt: DateTime.utc(2026, 6, 1),
    );

PendingSubmission buildPending({String id = 'pending-1'}) => PendingSubmission(
      id: id,
      title: 'Headache',
      questionBody: 'Pain for 3 days',
      submittedByRole: UserRole.warrior,
      syncStatus: SyncStatus.pending,
      attemptCount: 0,
      createdAt: DateTime.utc(2026, 6, 1),
    );

const networkError = Error<List<CaseEntity>>(NetworkFailure('offline'));
