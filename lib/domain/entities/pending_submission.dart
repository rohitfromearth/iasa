import '../enums/sync_status.dart';
import '../enums/user_role.dart';
import 'submission_attachment.dart';
import 'submission_photo.dart';

/// Warrior submission queued locally, not yet server-confirmed.
///
/// [id] is a client-generated UUID used as the idempotency key.
class PendingSubmission {
  const PendingSubmission({
    required this.id,
    required this.title,
    required this.questionBody,
    required this.submittedByRole,
    required this.syncStatus,
    required this.attemptCount,
    required this.createdAt,
    this.caseId,
    this.lastAttemptAt,
    this.lastError,
    this.photos = const [],
    this.attachments = const [],
  });

  final String id;
  final String? caseId;
  final String title;
  final String questionBody;
  final UserRole submittedByRole;
  final SyncStatus syncStatus;
  final int attemptCount;
  final DateTime? lastAttemptAt;
  final String? lastError;
  final DateTime createdAt;
  final List<SubmissionPhoto> photos;
  final List<SubmissionAttachment> attachments;

  PendingSubmission copyWith({
    String? id,
    String? caseId,
    bool clearCaseId = false,
    String? title,
    String? questionBody,
    UserRole? submittedByRole,
    SyncStatus? syncStatus,
    int? attemptCount,
    DateTime? lastAttemptAt,
    bool clearLastAttemptAt = false,
    String? lastError,
    bool clearLastError = false,
    DateTime? createdAt,
    List<SubmissionPhoto>? photos,
    List<SubmissionAttachment>? attachments,
  }) {
    return PendingSubmission(
      id: id ?? this.id,
      caseId: clearCaseId ? null : (caseId ?? this.caseId),
      title: title ?? this.title,
      questionBody: questionBody ?? this.questionBody,
      submittedByRole: submittedByRole ?? this.submittedByRole,
      syncStatus: syncStatus ?? this.syncStatus,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt:
          clearLastAttemptAt ? null : (lastAttemptAt ?? this.lastAttemptAt),
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      createdAt: createdAt ?? this.createdAt,
      photos: photos ?? this.photos,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingSubmission &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          caseId == other.caseId &&
          title == other.title &&
          questionBody == other.questionBody &&
          submittedByRole == other.submittedByRole &&
          syncStatus == other.syncStatus &&
          attemptCount == other.attemptCount &&
          lastAttemptAt == other.lastAttemptAt &&
          lastError == other.lastError &&
          createdAt == other.createdAt &&
          _listEquals(photos, other.photos) &&
          _listEquals(attachments, other.attachments);

  @override
  int get hashCode => Object.hash(
        id,
        caseId,
        title,
        questionBody,
        submittedByRole,
        syncStatus,
        attemptCount,
        lastAttemptAt,
        lastError,
        createdAt,
        Object.hashAll(photos),
        Object.hashAll(attachments),
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
