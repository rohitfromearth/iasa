import '../enums/user_role.dart';
import '../entities/submission_attachment.dart';
import '../entities/submission_photo.dart';

class SubmitQuestionParams {
  const SubmitQuestionParams({
    required this.title,
    required this.questionBody,
    this.caseId,
    this.submittedByRole = UserRole.warrior,
    this.photos = const [],
    this.attachments = const [],
  });

  final String title;
  final String questionBody;
  final String? caseId;
  final UserRole submittedByRole;
  final List<SubmissionPhoto> photos;
  final List<SubmissionAttachment> attachments;
}
