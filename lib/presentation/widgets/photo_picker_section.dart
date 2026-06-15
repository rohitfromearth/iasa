import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/media/media_picker.dart';
import '../../core/storage/submission_media_storage.dart';
import '../../core/utils/uuid_generator.dart';
import '../../domain/entities/submission_photo.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'form_section.dart';
import 'media_upload_status_label.dart';

class PhotoPickerSection extends StatefulWidget {
  const PhotoPickerSection({
    super.key,
    required this.photos,
    required this.enabled,
    required this.onPhotosChanged,
    required this.mediaStorage,
    required this.uuidGenerator,
    this.onError,
  });

  final List<SubmissionPhoto> photos;
  final bool enabled;
  final ValueChanged<List<SubmissionPhoto>> onPhotosChanged;
  final SubmissionMediaStorage mediaStorage;
  final UuidGenerator uuidGenerator;
  final ValueChanged<String>? onError;

  @override
  State<PhotoPickerSection> createState() => _PhotoPickerSectionState();
}

class _PhotoPickerSectionState extends State<PhotoPickerSection> {
  bool _isPicking = false;

  Future<void> _addPhoto() async {
    if (_isPicking || !widget.enabled) {
      return;
    }

    if (widget.photos.length >= AppConstants.maxSubmissionPhotos) {
      widget.onError?.call(
        'You can add up to ${AppConstants.maxSubmissionPhotos} photos.',
      );
      return;
    }

    setState(() => _isPicking = true);

    try {
      final picked = await MediaPicker.pickPhoto();
      if (picked == null) {
        return;
      }

      if (!SubmissionMediaStorage.isAllowedPhotoExtension(picked.extension)) {
        widget.onError?.call('Only JPG, JPEG, and PNG photos are supported.');
        return;
      }

      final photoId = widget.uuidGenerator.generate();
      final localPath = await widget.mediaStorage.savePickedFile(
        picked: picked,
        fileId: photoId,
      );

      widget.onPhotosChanged([
        ...widget.photos,
        SubmissionPhoto(
          id: photoId,
          localPath: localPath,
          addedAt: DateTime.now().toUtc(),
        ),
      ]);
    } catch (e) {
      widget.onError?.call('Could not add photo: $e');
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _removePhoto(SubmissionPhoto photo) async {
    await widget.mediaStorage.deleteIfExists(photo.localPath);
    widget.onPhotosChanged(
      widget.photos.where((item) => item.id != photo.id).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final atLimit = widget.photos.length >= AppConstants.maxSubmissionPhotos;

    return FormSection(
      title: 'Photos (Optional)',
      helperText:
          'Add up to ${AppConstants.maxSubmissionPhotos} photos. Saved locally immediately; demo upload runs on sync.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.photos.isEmpty)
            Text(
              'No photos added.',
              style: AppTypography.small.copyWith(color: AppColors.gray600),
            ),
          if (widget.photos.isNotEmpty) ...[
            SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final photo = widget.photos[index];
                  return SizedBox(
                    width: 112,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.sm),
                                child: Image.file(
                                  File(photo.localPath),
                                  width: 112,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.gray200,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                              ),
                              if (widget.enabled)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Material(
                                    color:
                                        AppColors.black.withValues(alpha: 0.55),
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () => _removePhoto(photo),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.close_rounded,
                                          color: AppColors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        MediaUploadStatusLabel(
                          uploadStatus: photo.uploadStatus,
                          uploadedAt: photo.uploadedAt,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          OutlinedButton.icon(
            onPressed: widget.enabled && !atLimit && !_isPicking
                ? _addPhoto
                : null,
            icon: _isPicking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.photo_library_outlined),
            label: Text(
              _isPicking
                  ? 'Opening picker…'
                  : atLimit
                      ? 'Photo limit reached'
                      : 'Add Photo',
            ),
          ),
        ],
      ),
    );
  }
}
