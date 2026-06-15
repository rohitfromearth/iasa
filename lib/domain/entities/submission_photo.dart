import '../enums/sync_status.dart';

/// Locally stored photo attached to a pending submission.
class SubmissionPhoto {
  const SubmissionPhoto({
    required this.id,
    required this.localPath,
    required this.addedAt,
    this.uploadStatus = SyncStatus.pending,
    this.uploadedAt,
  });

  final String id;
  final String localPath;
  final DateTime addedAt;
  final SyncStatus uploadStatus;
  final DateTime? uploadedAt;

  bool get isUploaded => uploadStatus == SyncStatus.synced;

  SubmissionPhoto copyWith({
    String? id,
    String? localPath,
    DateTime? addedAt,
    SyncStatus? uploadStatus,
    DateTime? uploadedAt,
    bool clearUploadedAt = false,
  }) {
    return SubmissionPhoto(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      addedAt: addedAt ?? this.addedAt,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadedAt: clearUploadedAt ? null : (uploadedAt ?? this.uploadedAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubmissionPhoto &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          localPath == other.localPath &&
          addedAt == other.addedAt &&
          uploadStatus == other.uploadStatus &&
          uploadedAt == other.uploadedAt;

  @override
  int get hashCode =>
      Object.hash(id, localPath, addedAt, uploadStatus, uploadedAt);
}
