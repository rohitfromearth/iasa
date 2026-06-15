import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../constants/app_constants.dart';

/// Cross-platform file selection with desktop-safe fallbacks.
class MediaPicker {
  MediaPicker._();

  static final _imagePicker = ImagePicker();

  static Future<PickedMediaFile?> pickPhoto() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      return _pickPhotoMobile();
    }
    return _pickPhotoDesktop(
      type: FileType.image,
      dialogTitle: 'Select a photo',
    );
  }

  static Future<PickedMediaFile?> pickAttachment() async {
    return _pickPhotoDesktop(
      type: FileType.custom,
      allowedExtensions: AppConstants.allowedAttachmentExtensions,
      dialogTitle: 'Select an attachment',
    );
  }

  static Future<PickedMediaFile?> _pickPhotoMobile() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) {
      return null;
    }

    final extension = _extensionFromPath(picked.path, fallback: 'jpg');
    return PickedMediaFile(
      path: picked.path,
      fileName: p.basename(picked.path),
      extension: extension,
    );
  }

  static Future<PickedMediaFile?> _pickPhotoDesktop({
    required FileType type,
    List<String>? allowedExtensions,
    required String dialogTitle,
  }) async {
    var result = await FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: allowedExtensions,
      allowMultiple: false,
      withData: false,
      lockParentWindow: true,
      dialogTitle: dialogTitle,
    );

    final firstPass = _fileFromResult(result);
    if (firstPass != null) {
      return firstPass;
    }

    result = await FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: allowedExtensions,
      allowMultiple: false,
      withData: true,
      lockParentWindow: true,
      dialogTitle: dialogTitle,
    );

    return _fileFromResult(result);
  }

  static PickedMediaFile? _fileFromResult(FilePickerResult? result) {
    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    final extension = _extensionFromPath(
      file.path ?? file.name,
      fallback: 'jpg',
    );

    if (file.path != null) {
      return PickedMediaFile(
        path: file.path,
        fileName: file.name,
        extension: extension,
      );
    }

    if (file.bytes != null) {
      return PickedMediaFile(
        bytes: file.bytes,
        fileName: file.name,
        extension: extension,
      );
    }

    return null;
  }

  static String _extensionFromPath(String? path, {required String fallback}) {
    if (path == null || path.isEmpty) {
      return fallback;
    }
    final ext = p.extension(path).replaceFirst('.', '').toLowerCase();
    return ext.isEmpty ? fallback : ext;
  }
}

class PickedMediaFile {
  const PickedMediaFile({
    required this.fileName,
    required this.extension,
    this.path,
    this.bytes,
  }) : assert(path != null || bytes != null);

  final String? path;
  final Uint8List? bytes;
  final String fileName;
  final String extension;
}
