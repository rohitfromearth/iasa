import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:iasa/core/media/media_picker.dart';
import 'package:iasa/core/storage/submission_media_storage.dart';

void main() {
  test('savePickedFile stores bytes under submission_media directory', () async {
    final tempDir = await Directory.systemTemp.createTemp('iasa_media_test');
    final storage = SubmissionMediaStorage(
      documentsDirectoryProvider: () async => tempDir,
    );

    final copiedPath = await storage.savePickedFile(
      picked: PickedMediaFile(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'photo.jpg',
        extension: 'jpg',
      ),
      fileId: 'photo-123',
    );

    expect(await File(copiedPath).exists(), isTrue);
    expect(copiedPath, contains('submission_media'));
    expect(copiedPath, endsWith('photo-123.jpg'));

    await tempDir.delete(recursive: true);
  });

  test('isAllowedAttachmentExtension accepts supported types only', () {
    expect(SubmissionMediaStorage.isAllowedAttachmentExtension('pdf'), isTrue);
    expect(SubmissionMediaStorage.isAllowedAttachmentExtension('PNG'), isTrue);
    expect(SubmissionMediaStorage.isAllowedAttachmentExtension('docx'), isFalse);
  });

  test('isAllowedPhotoExtension accepts supported types only', () {
    expect(SubmissionMediaStorage.isAllowedPhotoExtension('jpg'), isTrue);
    expect(SubmissionMediaStorage.isAllowedPhotoExtension('gif'), isFalse);
  });
}
