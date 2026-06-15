import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/storage/submission_media_storage.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/uuid_generator.dart';
import '../../../domain/entities/submission_attachment.dart';
import '../../../domain/entities/submission_photo.dart';
import '../../providers/submission_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/sync_queue_helper.dart';
import '../../widgets/attachment_picker_section.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/form_section.dart';
import '../../widgets/local_media_notice.dart';
import '../../widgets/photo_picker_section.dart';
import '../../widgets/submission_queued_banner.dart';

class SubmitQuestionScreen extends StatefulWidget {
  const SubmitQuestionScreen({super.key, this.caseId});

  final String? caseId;

  @override
  State<SubmitQuestionScreen> createState() => _SubmitQuestionScreenState();
}

class _SubmitQuestionScreenState extends State<SubmitQuestionScreen> {
  final _titleController = TextEditingController();
  final _questionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _mediaStorage = SubmissionMediaStorage();

  _SubmitPhase _phase = _SubmitPhase.initial;
  String? _validationError;
  List<SubmissionPhoto> _photos = [];
  List<SubmissionAttachment> _attachments = [];

  @override
  void dispose() {
    _titleController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  void _showPickerError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _phase = _SubmitPhase.error;
        _validationError = 'Enter a title and question';
      });
      return;
    }

    setState(() {
      _phase = _SubmitPhase.loading;
      _validationError = null;
    });

    final result = await context.read<SubmissionProvider>().submitQuestion(
          title: _titleController.text.trim(),
          questionBody: _questionController.text.trim(),
          caseId: widget.caseId,
          photos: _photos,
          attachments: _attachments,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _phase = switch (result) {
        Success() => _SubmitPhase.queued,
        Error() => _SubmitPhase.error,
      };
      _validationError = null;
    });
  }

  void _viewCases() {
    Navigator.of(context).pop();
  }

  Future<void> _syncNow() async {
    final synced = await syncQueueAndReload(context);
    if (!mounted) {
      return;
    }
    if (synced) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Queue synchronized. Cases updated.'),
        ),
      );
    } else {
      final error = context.read<SubmissionProvider>().lastError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Synchronization could not complete'),
        ),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isQueued = _phase == _SubmitPhase.queued;
    final isLoading = _phase == _SubmitPhase.loading;
    final isEditable = !isQueued && !isLoading;
    final providerError = _phase == _SubmitPhase.error
        ? context.read<SubmissionProvider>().lastError
        : null;
    final errorMessage = _validationError ?? providerError;
    final uuidGenerator = context.read<UuidGenerator>();

    return AppScaffold(
      title: 'Submit Question',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (isQueued) const SubmissionQueuedBanner(),
            if (_phase == _SubmitPhase.error && errorMessage != null) ...[
              _SubmitErrorBanner(message: errorMessage),
              const SizedBox(height: AppSpacing.md),
            ],
            const LocalMediaNotice(),
            const SizedBox(height: AppSpacing.md),
            FormSection(
              title: 'Question',
              helperText: 'Short label and detailed description',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Title',
                    controller: _titleController,
                    enabled: isEditable,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Question',
                    controller: _questionController,
                    enabled: isEditable,
                    minLines: 4,
                    maxLines: 8,
                    textInputAction: TextInputAction.newline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Question is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PhotoPickerSection(
              photos: _photos,
              enabled: isEditable,
              mediaStorage: _mediaStorage,
              uuidGenerator: uuidGenerator,
              onPhotosChanged: (photos) => setState(() => _photos = photos),
              onError: _showPickerError,
            ),
            const SizedBox(height: AppSpacing.md),
            AttachmentPickerSection(
              attachments: _attachments,
              enabled: isEditable,
              mediaStorage: _mediaStorage,
              uuidGenerator: uuidGenerator,
              onAttachmentsChanged: (attachments) =>
                  setState(() => _attachments = attachments),
              onError: _showPickerError,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: isQueued ? 'Queued' : 'Queue Submission',
              onPressed: isQueued ? null : _submit,
              isLoading: isLoading,
            ),
            if (isQueued) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _viewCases,
                      child: const Text('View Cases'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: _syncNow,
                      child: const Text('Sync Now'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _SubmitPhase { initial, loading, error, queued }

class _SubmitErrorBanner extends StatelessWidget {
  const _SubmitErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorRedLight,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.errorRed,
            size: AppSpacing.lg,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption.copyWith(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}
