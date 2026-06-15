import '../../core/constants/database_constants.dart';
import '../../domain/entities/submission_attachment.dart';
import '../../domain/enums/sync_status.dart';

class SubmissionAttachmentModel {
  const SubmissionAttachmentModel({
    required this.id,
    required this.submissionId,
    required this.localPath,
    required this.fileName,
    required this.extension,
    required this.addedAt,
    required this.uploadStatus,
    this.uploadedAt,
  });

  final String id;
  final String submissionId;
  final String localPath;
  final String fileName;
  final String extension;
  final DateTime addedAt;
  final SyncStatus uploadStatus;
  final DateTime? uploadedAt;

  factory SubmissionAttachmentModel.fromEntity({
    required SubmissionAttachment entity,
    required String submissionId,
  }) {
    return SubmissionAttachmentModel(
      id: entity.id,
      submissionId: submissionId,
      localPath: entity.localPath,
      fileName: entity.fileName,
      extension: entity.extension,
      addedAt: entity.addedAt,
      uploadStatus: entity.uploadStatus,
      uploadedAt: entity.uploadedAt,
    );
  }

  factory SubmissionAttachmentModel.fromMap(Map<String, Object?> map) {
    return SubmissionAttachmentModel(
      id: map[DatabaseConstants.colId]! as String,
      submissionId: map[DatabaseConstants.colSubmissionId]! as String,
      localPath: map[DatabaseConstants.colLocalPath]! as String,
      fileName: map[DatabaseConstants.colFileName]! as String,
      extension: map[DatabaseConstants.colExtension]! as String,
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
      DatabaseConstants.colFileName: fileName,
      DatabaseConstants.colExtension: extension,
      DatabaseConstants.colAddedAt: addedAt.millisecondsSinceEpoch,
      DatabaseConstants.colUploadStatus: uploadStatus.name,
      DatabaseConstants.colUploadedAt: uploadedAt?.millisecondsSinceEpoch,
    };
  }

  SubmissionAttachment toEntity() {
    return SubmissionAttachment(
      id: id,
      localPath: localPath,
      fileName: fileName,
      extension: extension,
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
