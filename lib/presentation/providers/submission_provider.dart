import 'package:flutter/foundation.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/pending_submission.dart';
import '../../domain/entities/submission_attachment.dart';
import '../../domain/entities/submission_photo.dart';
import '../../domain/enums/sync_status.dart';
import '../../domain/enums/user_role.dart';
import '../../domain/usecases/get_pending_submissions_usecase.dart';
import '../../domain/usecases/submit_question_usecase.dart';
import '../../domain/usecases/sync_pending_submissions_usecase.dart';
import '../../domain/value_objects/submit_question_params.dart';
import '../../domain/value_objects/sync_result.dart';

class SubmissionProvider extends ChangeNotifier {
  SubmissionProvider({
    required this._submitQuestionUseCase,
    required this._syncPendingSubmissionsUseCase,
    required this._getPendingSubmissionsUseCase,
    UserRole Function()? roleResolver,
  }) : _roleResolver = roleResolver ?? (() => UserRole.warrior);

  final SubmitQuestionUseCase _submitQuestionUseCase;
  final SyncPendingSubmissionsUseCase _syncPendingSubmissionsUseCase;
  final GetPendingSubmissionsUseCase _getPendingSubmissionsUseCase;
  final UserRole Function() _roleResolver;

  final List<PendingSubmission> _submissions = [];

  bool _isSubmitting = false;
  bool _isSyncing = false;
  String? _lastError;

  List<PendingSubmission> get submissions => List.unmodifiable(_submissions);

  bool get isSubmitting => _isSubmitting;

  bool get isSyncing => _isSyncing;

  String? get lastError => _lastError;

  int get pendingSubmissionCount => queuedCount + failedCount;

  int get queuedCount =>
      _submissions.where((s) => s.syncStatus == SyncStatus.pending).length;

  int get syncingCount =>
      _submissions.where((s) => s.syncStatus == SyncStatus.syncing).length;

  int get failedCount =>
      _submissions.where((s) => s.syncStatus == SyncStatus.failed).length;

  int get syncedCount =>
      _submissions.where((s) => s.syncStatus == SyncStatus.synced).length;

  /// Loads persisted outbox rows so queue counts survive process death.
  Future<void> hydratePendingSubmissions() async {
    final result = await _getPendingSubmissionsUseCase(const NoParams());

    switch (result) {
      case Success(data: final persisted):
        _submissions
          ..clear()
          ..addAll(persisted);
        _lastError = null;
      case Error(failure: final failure):
        _lastError = failure.message;
    }

    notifyListeners();
  }

  Future<Result<PendingSubmission>> submitQuestion({
    required String title,
    required String questionBody,
    String? caseId,
    List<SubmissionPhoto> photos = const [],
    List<SubmissionAttachment> attachments = const [],
  }) async {
    if (_isSubmitting) {
      return const Error(UnexpectedFailure('Submission already in progress'));
    }

    _isSubmitting = true;
    _lastError = null;
    notifyListeners();

    final result = await _submitQuestionUseCase(
      SubmitQuestionParams(
        title: title,
        questionBody: questionBody,
        caseId: caseId,
        submittedByRole: _roleResolver(),
        photos: photos,
        attachments: attachments,
      ),
    );

    _isSubmitting = false;

    switch (result) {
      case Success(data: final submission):
        _upsertSubmission(submission);
        _lastError = null;
      case Error(failure: final failure):
        _lastError = failure.message;
    }

    notifyListeners();
    return result;
  }

  Future<Result<SyncResult>> syncPendingSubmissions() async {
    if (_isSyncing) {
      return const Error(UnexpectedFailure('Synchronization already in progress'));
    }

    _isSyncing = true;
    _markSyncing();
    _lastError = null;
    notifyListeners();

    final result = await _syncPendingSubmissionsUseCase(const NoParams());

    switch (result) {
      case Success(data: final syncResult):
        _applySyncResult(syncResult);
        _lastError = null;
      case Error(failure: final failure):
        _revertSyncingToPending();
        _lastError = failure.message;
    }

    _isSyncing = false;
    notifyListeners();
    return result;
  }

  void _markSyncing() {
    var changed = false;
    for (var i = 0; i < _submissions.length; i++) {
      final submission = _submissions[i];
      if (submission.syncStatus == SyncStatus.pending ||
          submission.syncStatus == SyncStatus.failed) {
        _submissions[i] = submission.copyWith(syncStatus: SyncStatus.syncing);
        changed = true;
      }
    }
    if (changed && !_isSyncing) {
      notifyListeners();
    }
  }

  void _applySyncResult(SyncResult syncResult) {
    final syncing = _submissions
        .where((s) => s.syncStatus == SyncStatus.syncing)
        .toList(growable: false);

    var syncedApplied = 0;
    var failedApplied = 0;

    for (final submission in syncing) {
      final index = _submissions.indexWhere((s) => s.id == submission.id);
      if (index == -1) {
        continue;
      }

      if (syncedApplied < syncResult.syncedCount) {
        _submissions[index] = submission.copyWith(
          syncStatus: SyncStatus.synced,
          clearLastError: true,
        );
        syncedApplied++;
      } else if (failedApplied < syncResult.failedCount) {
        _submissions[index] = submission.copyWith(
          syncStatus: SyncStatus.failed,
          lastError: _lastError ?? 'Synchronization failed',
        );
        failedApplied++;
      } else {
        _submissions[index] = submission.copyWith(syncStatus: SyncStatus.pending);
      }
    }
  }

  void _revertSyncingToPending() {
    for (var i = 0; i < _submissions.length; i++) {
      if (_submissions[i].syncStatus == SyncStatus.syncing) {
        _submissions[i] =
            _submissions[i].copyWith(syncStatus: SyncStatus.pending);
      }
    }
  }

  void _upsertSubmission(PendingSubmission submission) {
    final index = _submissions.indexWhere((s) => s.id == submission.id);
    if (index == -1) {
      _submissions.add(submission);
      return;
    }
    _submissions[index] = submission;
  }
}
