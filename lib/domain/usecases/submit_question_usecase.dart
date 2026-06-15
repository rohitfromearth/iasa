import '../../core/usecases/usecase.dart';
import '../../core/utils/result.dart';
import '../entities/pending_submission.dart';
import '../repositories/case_repository.dart';
import '../value_objects/submit_question_params.dart';

class SubmitQuestionUseCase
    implements UseCase<PendingSubmission, SubmitQuestionParams> {
  SubmitQuestionUseCase(this._repository);

  final CaseRepository _repository;

  @override
  Future<Result<PendingSubmission>> call(SubmitQuestionParams params) {
    return _repository.submitQuestion(params);
  }
}
