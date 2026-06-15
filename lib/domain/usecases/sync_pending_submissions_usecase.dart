import '../../core/usecases/usecase.dart';
import '../../core/utils/result.dart';
import '../repositories/case_repository.dart';
import '../value_objects/sync_result.dart';

class SyncPendingSubmissionsUseCase implements UseCase<SyncResult, NoParams> {
  SyncPendingSubmissionsUseCase(this._repository);

  final CaseRepository _repository;

  @override
  Future<Result<SyncResult>> call(NoParams params) {
    return _repository.syncPendingSubmissions();
  }
}
