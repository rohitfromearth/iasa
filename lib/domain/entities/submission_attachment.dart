import '../enums/sync_status.dart';

/// Locally stored file attachment on a pending submission.
class SubmissionAttachment {
  const SubmissionAttachment({
    required this.id,
    required this.localPath,
    required this.fileName,
    required this.extension,
    required this.addedAt,
    this.uploadStatus = SyncStatus.pending,
    this.uploadedAt,
  });

  final String id;
  final String localPath;
  final String fileName;
  final String extension;
  final DateTime addedAt;
  final SyncStatus uploadStatus;
  final DateTime? uploadedAt;

  bool get isUploaded => uploadStatus == SyncStatus.synced;

  SubmissionAttachment copyWith({
    String? id,
    String? localPath,
    String? fileName,
    String? extension,
    DateTime? addedAt,
    SyncStatus? uploadStatus,
    DateTime? uploadedAt,
    bool clearUploadedAt = false,
  }) {
    return SubmissionAttachment(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      fileName: fileName ?? this.fileName,
      extension: extension ?? this.extension,
      addedAt: addedAt ?? this.addedAt,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadedAt: clearUploadedAt ? null : (uploadedAt ?? this.uploadedAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubmissionAttachment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          localPath == other.localPath &&
          fileName == other.fileName &&
          extension == other.extension &&
          addedAt == other.addedAt &&
          uploadStatus == other.uploadStatus &&
          uploadedAt == other.uploadedAt;

  @override
  int get hashCode => Object.hash(
        id,
        localPath,
        fileName,
        extension,
        addedAt,
        uploadStatus,
        uploadedAt,
      );
}
