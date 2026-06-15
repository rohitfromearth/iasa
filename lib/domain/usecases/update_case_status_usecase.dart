import '../../core/utils/result.dart';

import '../entities/case_entity.dart';

import '../repositories/case_repository.dart';

import '../value_objects/update_case_status_params.dart';



class UpdateCaseStatusUseCase {

  const UpdateCaseStatusUseCase(this._repository);



  final CaseRepository _repository;



  Future<Result<CaseEntity>> call(UpdateCaseStatusParams params) {

    return _repository.updateLocalCaseStatus(

      caseId: params.caseId,

      status: params.status,

    );

  }

}


