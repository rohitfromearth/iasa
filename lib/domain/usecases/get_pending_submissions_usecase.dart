import '../../core/usecases/usecase.dart';
import '../../core/utils/result.dart';
import '../entities/pending_submission.dart';
import '../repositories/case_repository.dart';

class GetPendingSubmissionsUseCase
    implements UseCase<List<PendingSubmission>, NoParams> {
  GetPendingSubmissionsUseCase(this._repository);

  final CaseRepository _repository;

  @override
  Future<Result<List<PendingSubmission>>> call(NoParams params) {
    return _repository.getPendingSubmissions();
  }
}
