import 'dart:io';
import 'dart:math';

import '../../../core/errors/exceptions.dart';
import '../../../domain/enums/case_status.dart';
import '../../../domain/enums/sync_status.dart';
import '../../../domain/enums/user_role.dart';
import '../../models/case_model.dart';
import '../../models/media_upload_item.dart';
import 'api_datasource.dart';

class MockApiDataSource implements ApiDataSource {
  MockApiDataSource({
    this.failureRate = 0.125,
    this.minLatency = const Duration(seconds: 1),
    this.maxLatency = const Duration(seconds: 2),
    Random? random,
  }) : _random = random ?? Random();

  final double failureRate;
  final Duration minLatency;
  final Duration maxLatency;
  final Random _random;

  final Map<String, CaseModel> _casesByIdempotencyKey = {};
  final Map<String, List<MediaUploadItem>> _uploadedMediaBySubmissionId = {};

  Map<String, List<MediaUploadItem>> get uploadedMediaBySubmissionId =>
      Map.unmodifiable(_uploadedMediaBySubmissionId);

  @override
  Future<List<CaseModel>> fetchCases() async {
    await _simulateLatency();
    if (_shouldFail()) {
      throw const NetworkException('Simulated fetch failure');
    }
    return _casesByIdempotencyKey.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<CaseModel> submitQuestion({
    required String idempotencyKey,
    required String title,
    required String questionBody,
    required UserRole submittedByRole,
    String? caseId,
  }) async {
    await _simulateLatency();

    final existing = _casesByIdempotencyKey[idempotencyKey];
    if (existing != null) {
      return existing;
    }

    if (_shouldFail()) {
      throw const NetworkException('Simulated submission failure');
    }

    final now = DateTime.now().toUtc();
    final caseModel = CaseModel(
      id: idempotencyKey,
      title: title,
      questionBody: questionBody,
      status: CaseStatus.submitted,
      createdByRole: submittedByRole,
      syncStatus: SyncStatus.synced,
      createdAt: now,
      updatedAt: now,
      lastSyncedAt: now,
    );

    _casesByIdempotencyKey[idempotencyKey] = caseModel;

    if (caseId != null && _casesByIdempotencyKey.containsKey(caseId)) {
      final parent = _casesByIdempotencyKey[caseId]!;
      _casesByIdempotencyKey[caseId] = CaseModel(
        id: parent.id,
        title: parent.title,
        questionBody: '$questionBody\n\n[Follow-up on ${parent.title}]',
        answerBody: parent.answerBody,
        status: parent.status,
        createdByRole: parent.createdByRole,
        syncStatus: SyncStatus.synced,
        createdAt: parent.createdAt,
        updatedAt: now,
        lastSyncedAt: now,
        verifiedAt: parent.verifiedAt,
      );
    }

    return caseModel;
  }

  @override
  Future<void> uploadSubmissionMedia({
    required String submissionId,
    required List<MediaUploadItem> items,
  }) async {
    await _simulateLatency();

    if (_shouldFail()) {
      throw const NetworkException('Simulated media upload failure');
    }

    final uploaded = <MediaUploadItem>[];
    for (final item in items) {
      final file = File(item.localPath);
      if (!await file.exists()) {
        throw NetworkException('Local file missing: ${item.fileName}');
      }
      uploaded.add(item);
    }

    _uploadedMediaBySubmissionId[submissionId] = uploaded;
  }

  Future<void> _simulateLatency() async {
    final minMs = minLatency.inMilliseconds;
    final maxMs = maxLatency.inMilliseconds;
    final delayMs = minMs + _random.nextInt(maxMs - minMs + 1);
    await Future<void>.delayed(Duration(milliseconds: delayMs));
  }

  bool _shouldFail() => _random.nextDouble() < failureRate;
}
