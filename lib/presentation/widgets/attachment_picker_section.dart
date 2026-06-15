import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../core/constants/app_constants.dart';
import '../../core/media/media_picker.dart';
import '../../core/storage/submission_media_storage.dart';
import '../../core/utils/uuid_generator.dart';
import '../../domain/entities/submission_attachment.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'form_section.dart';
import 'media_upload_status_label.dart';

class AttachmentPickerSection extends StatefulWidget {
  const AttachmentPickerSection({
    super.key,
    required this.attachments,
    required this.enabled,
    required this.onAttachmentsChanged,
    required this.mediaStorage,
    required this.uuidGenerator,
    this.onError,
  });

  final List<SubmissionAttachment> attachments;
  final bool enabled;
  final ValueChanged<List<SubmissionAttachment>> onAttachmentsChanged;
  final SubmissionMediaStorage mediaStorage;
  final UuidGenerator uuidGenerator;
  final ValueChanged<String>? onError;

  @override
  State<AttachmentPickerSection> createState() =>
      _AttachmentPickerSectionState();
}

class _AttachmentPickerSectionState extends State<AttachmentPickerSection> {
  bool _isPicking = false;

  Future<void> _addAttachment() async {
    if (_isPicking || !widget.enabled) {
      return;
    }

    if (widget.attachments.length >= AppConstants.maxSubmissionAttachments) {
      widget.onError?.call(
        'You can add up to ${AppConstants.maxSubmissionAttachments} attachments.',
      );
      return;
    }

    setState(() => _isPicking = true);

    try {
      final picked = await MediaPicker.pickAttachment();
      if (picked == null) {
        return;
      }

      if (!SubmissionMediaStorage.isAllowedAttachmentExtension(picked.extension)) {
        widget.onError?.call('Only PDF, JPG, JPEG, and PNG files are supported.');
        return;
      }

      final attachmentId = widget.uuidGenerator.generate();
      final localPath = await widget.mediaStorage.savePickedFile(
        picked: picked,
        fileId: attachmentId,
      );

      widget.onAttachmentsChanged([
        ...widget.attachments,
        SubmissionAttachment(
          id: attachmentId,
          localPath: localPath,
          fileName: picked.fileName.isNotEmpty
              ? picked.fileName
              : p.basename(localPath),
          extension: picked.extension,
          addedAt: DateTime.now().toUtc(),
        ),
      ]);
    } catch (e) {
      widget.onError?.call('Could not add attachment: $e');
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _removeAttachment(SubmissionAttachment attachment) async {
    await widget.mediaStorage.deleteIfExists(attachment.localPath);
    widget.onAttachmentsChanged(
      widget.attachments.where((item) => item.id != attachment.id).toList(),
    );
  }

  IconData _iconForExtension(String extension) {
    return switch (extension.toLowerCase()) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'jpg' || 'jpeg' || 'png' => Icons.image_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final atLimit =
        widget.attachments.length >= AppConstants.maxSubmissionAttachments;

    return FormSection(
      title: 'Attachments (Optional)',
      helperText:
          'Add up to ${AppConstants.maxSubmissionAttachments} files (PDF, JPG, JPEG, PNG).',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.attachments.isEmpty)
            Text(
              'No attachments added.',
              style: AppTypography.small.copyWith(color: AppColors.gray600),
            ),
          if (widget.attachments.isNotEmpty) ...[
            ...widget.attachments.map(
              (attachment) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _iconForExtension(attachment.extension),
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            attachment.fileName,
                            style: AppTypography.body.copyWith(
                              color: AppColors.gray900,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.enabled)
                          IconButton(
                            tooltip: 'Remove attachment',
                            onPressed: () => _removeAttachment(attachment),
                            icon: const Icon(Icons.close_rounded),
                          ),
                      ],
                    ),
                    MediaUploadStatusLabel(
                      uploadStatus: attachment.uploadStatus,
                      uploadedAt: attachment.uploadedAt,
                    ),
                  ],
                ),
              ),
            ),
          ],
          OutlinedButton.icon(
            onPressed: widget.enabled && !atLimit && !_isPicking
                ? _addAttachment
                : null,
            icon: _isPicking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.attach_file_rounded),
            label: Text(
              _isPicking
                  ? 'Opening picker…'
                  : atLimit
                      ? 'Attachment limit reached'
                      : 'Add Attachment',
            ),
          ),
        ],
      ),
    );
  }
}
