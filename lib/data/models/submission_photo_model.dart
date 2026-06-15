import '../../core/constants/database_constants.dart';
import '../../domain/entities/submission_photo.dart';
import '../../domain/enums/sync_status.dart';

class SubmissionPhotoModel {
  const SubmissionPhotoModel({
    required this.id,
    required this.submissionId,
    required this.localPath,
    required this.addedAt,
    required this.uploadStatus,
    this.uploadedAt,
  });

  final String id;
  final String submissionId;
  final String localPath;
  final DateTime addedAt;
  final SyncStatus uploadStatus;
  final DateTime? uploadedAt;

  factory SubmissionPhotoModel.fromEntity({
    required SubmissionPhoto entity,
    required String submissionId,
  }) {
    return SubmissionPhotoModel(
      id: entity.id,
      submissionId: submissionId,
      localPath: entity.localPath,
      addedAt: entity.addedAt,
      uploadStatus: entity.uploadStatus,
      uploadedAt: entity.uploadedAt,
    );
  }

  factory SubmissionPhotoModel.fromMap(Map<String, Object?> map) {
    return SubmissionPhotoModel(
      id: map[DatabaseConstants.colId]! as String,
      submissionId: map[DatabaseConstants.colSubmissionId]! as String,
      localPath: map[DatabaseConstants.colLocalPath]! as String,
      addedAt: DateTime.fromMillisecondsSinceEpoch(
        map[DatabaseConstants.colAddedAt]! as int,
        isUtc: true,
      ),
      uploadStatus: SyncStatus.values.byName(
        map[DatabaseConstants.colUploadStatus]! as String,
      ),
      uploadedAt: _dateFromMillis(map[DatabaseConstants.colUploadedAt] as int?),
    );
  }

  Map<String, Object?> toMap() {
    return {
      DatabaseConstants.colId: id,
      DatabaseConstants.colSubmissionId: submissionId,
      DatabaseConstants.colLocalPath: localPath,
      DatabaseConstants.colAddedAt: addedAt.millisecondsSinceEpoch,
      DatabaseConstants.colUploadStatus: uploadStatus.name,
      DatabaseConstants.colUploadedAt: uploadedAt?.millisecondsSinceEpoch,
    };
  }

  SubmissionPhoto toEntity() {
    return SubmissionPhoto(
      id: id,
      localPath: localPath,
      addedAt: addedAt,
      uploadStatus: uploadStatus,
      uploadedAt: uploadedAt,
    );
  }

  static DateTime? _dateFromMillis(int? millis) {
    if (millis == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }
}
