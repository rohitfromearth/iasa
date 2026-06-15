import '../../../domain/enums/user_role.dart';
import '../../models/case_model.dart';
import '../../models/media_upload_item.dart';

abstract interface class ApiDataSource {
  Future<CaseModel> submitQuestion({
    required String idempotencyKey,
    required String title,
    required String questionBody,
    required UserRole submittedByRole,
    String? caseId,
  });

  /// Demo-only mock upload. Confirms local files reached the server simulator.
  Future<void> uploadSubmissionMedia({
    required String submissionId,
    required List<MediaUploadItem> items,
  });

  Future<List<CaseModel>> fetchCases();
}
