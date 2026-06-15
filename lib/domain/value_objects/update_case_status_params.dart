import '../entities/case_entity.dart';

import '../enums/case_status.dart';



class UpdateCaseStatusParams {

  const UpdateCaseStatusParams({

    required this.caseId,

    required this.status,

  });



  final String caseId;

  final CaseStatus status;

}


