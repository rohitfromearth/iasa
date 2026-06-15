import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';
import '../media/media_picker.dart';

/// Copies picked media into the app documents sandbox.
class SubmissionMediaStorage {
  SubmissionMediaStorage({Future<Directory> Function()? documentsDirectoryProvider})
      : _documentsDirectoryProvider =
            documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _documentsDirectoryProvider;

  static bool isAllowedAttachmentExtension(String extension) {
    return AppConstants.allowedAttachmentExtensions
        .contains(extension.toLowerCase());
  }

  static bool isAllowedPhotoExtension(String extension) {
    return AppConstants.allowedPhotoExtensions
        .contains(extension.toLowerCase());
  }

  Future<String> savePickedFile({
    required PickedMediaFile picked,
    required String fileId,
  }) async {
    final extension = picked.extension.toLowerCase();
    final destinationPath = await _destinationPath(fileId, extension);

    if (picked.path != null) {
      await File(picked.path!).copy(destinationPath);
      return destinationPath;
    }

    if (picked.bytes != null) {
      await File(destinationPath).writeAsBytes(picked.bytes!, flush: true);
      return destinationPath;
    }

    throw StateError('Picked file has no path or bytes');
  }

  Future<String> copyToSandbox({
    required String sourcePath,
    required String fileId,
    required String extension,
  }) async {
    final normalizedExtension = extension.toLowerCase();
    final destinationPath = await _destinationPath(fileId, normalizedExtension);
    await File(sourcePath).copy(destinationPath);
    return destinationPath;
  }

  Future<void> deleteIfExists(String localPath) async {
    final file = File(localPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String> _destinationPath(String fileId, String extension) async {
    final mediaDir = await _mediaDirectory();
    return p.join(mediaDir.path, '$fileId.${extension.toLowerCase()}');
  }

  Future<Directory> _mediaDirectory() async {
    final documents = await _documentsDirectoryProvider();
    final mediaDir = Directory(
      p.join(documents.path, AppConstants.submissionMediaDir),
    );
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir;
  }
}
