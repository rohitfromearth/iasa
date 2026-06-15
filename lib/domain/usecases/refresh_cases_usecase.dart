import '../../core/usecases/usecase.dart';
import '../../core/utils/result.dart';
import '../entities/case_entity.dart';
import '../repositories/case_repository.dart';

class RefreshCasesUseCase implements UseCase<List<CaseEntity>, NoParams> {
  RefreshCasesUseCase(this._repository);

  final CaseRepository _repository;

  @override
  Future<Result<List<CaseEntity>>> call(NoParams params) {
    return _repository.refreshCases();
  }
}
