import '../../core/usecases/usecase.dart';
import '../../core/utils/result.dart';
import '../entities/case_entity.dart';
import '../repositories/case_repository.dart';

class GetCasesUseCase implements UseCase<List<CaseEntity>, NoParams> {
  GetCasesUseCase(this._repository);

  final CaseRepository _repository;

  @override
  Future<Result<List<CaseEntity>>> call(NoParams params) {
    return _repository.getCases();
  }
}
