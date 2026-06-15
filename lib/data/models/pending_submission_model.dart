import '../../core/constants/database_constants.dart';

import '../../domain/entities/pending_submission.dart';

import '../../domain/entities/submission_attachment.dart';

import '../../domain/entities/submission_photo.dart';

import '../../domain/enums/sync_status.dart';

import '../../domain/enums/user_role.dart';



class PendingSubmissionModel {

  const PendingSubmissionModel({

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



  factory PendingSubmissionModel.fromEntity(PendingSubmission entity) {

    return PendingSubmissionModel(

      id: entity.id,

      caseId: entity.caseId,

      title: entity.title,

      questionBody: entity.questionBody,

      submittedByRole: entity.submittedByRole,

      syncStatus: entity.syncStatus,

      attemptCount: entity.attemptCount,

      lastAttemptAt: entity.lastAttemptAt,

      lastError: entity.lastError,

      createdAt: entity.createdAt,

      photos: entity.photos,

      attachments: entity.attachments,

    );

  }



  factory PendingSubmissionModel.fromMap(Map<String, Object?> map) {

    return PendingSubmissionModel(

      id: map[DatabaseConstants.colId]! as String,

      caseId: map[DatabaseConstants.colCaseId] as String?,

      title: map[DatabaseConstants.colTitle]! as String,

      questionBody: map[DatabaseConstants.colQuestionBody]! as String,

      submittedByRole: UserRole.values

          .byName(map[DatabaseConstants.colSubmittedByRole]! as String),

      syncStatus:

          SyncStatus.values.byName(map[DatabaseConstants.colSyncStatus]! as String),

      attemptCount: map[DatabaseConstants.colAttemptCount]! as int,

      lastAttemptAt: _dateFromMillis(map[DatabaseConstants.colLastAttemptAt] as int?),

      lastError: map[DatabaseConstants.colLastError] as String?,

      createdAt: DateTime.fromMillisecondsSinceEpoch(

        map[DatabaseConstants.colCreatedAt]! as int,

        isUtc: true,

      ),

    );

  }



  Map<String, Object?> toMap() {

    return {

      DatabaseConstants.colId: id,

      DatabaseConstants.colCaseId: caseId,

      DatabaseConstants.colTitle: title,

      DatabaseConstants.colQuestionBody: questionBody,

      DatabaseConstants.colSubmittedByRole: submittedByRole.name,

      DatabaseConstants.colSyncStatus: syncStatus.name,

      DatabaseConstants.colAttemptCount: attemptCount,

      DatabaseConstants.colLastAttemptAt: lastAttemptAt?.millisecondsSinceEpoch,

      DatabaseConstants.colLastError: lastError,

      DatabaseConstants.colCreatedAt: createdAt.millisecondsSinceEpoch,

    };

  }



  PendingSubmission toEntity() {

    return PendingSubmission(

      id: id,

      caseId: caseId,

      title: title,

      questionBody: questionBody,

      submittedByRole: submittedByRole,

      syncStatus: syncStatus,

      attemptCount: attemptCount,

      lastAttemptAt: lastAttemptAt,

      lastError: lastError,

      createdAt: createdAt,

      photos: photos,

      attachments: attachments,

    );

  }



  PendingSubmissionModel copyWithMedia({

    List<SubmissionPhoto>? photos,

    List<SubmissionAttachment>? attachments,

  }) {

    return PendingSubmissionModel(

      id: id,

      caseId: caseId,

      title: title,

      questionBody: questionBody,

      submittedByRole: submittedByRole,

      syncStatus: syncStatus,

      attemptCount: attemptCount,

      lastAttemptAt: lastAttemptAt,

      lastError: lastError,

      createdAt: createdAt,

      photos: photos ?? this.photos,

      attachments: attachments ?? this.attachments,

    );

  }



  static DateTime? _dateFromMillis(int? millis) {

    if (millis == null) {

      return null;

    }

    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);

  }

}


