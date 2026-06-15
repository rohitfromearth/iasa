import '../../domain/entities/submission_attachment.dart';
import '../../domain/entities/submission_photo.dart';

class MediaUploadItem {
  const MediaUploadItem({
    required this.id,
    required this.localPath,
    required this.fileName,
    required this.extension,
  });

  factory MediaUploadItem.fromPhoto(SubmissionPhoto photo) {
    final fileName = photo.localPath.split(RegExp(r'[\\/]')).last;
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';

    return MediaUploadItem(
      id: photo.id,
      localPath: photo.localPath,
      fileName: fileName,
      extension: extension,
    );
  }

  factory MediaUploadItem.fromAttachment(SubmissionAttachment attachment) {
    return MediaUploadItem(
      id: attachment.id,
      localPath: attachment.localPath,
      fileName: attachment.fileName,
      extension: attachment.extension,
    );
  }

  final String id;
  final String localPath;
  final String fileName;
  final String extension;
}
