import 'package:iasa/core/errors/exceptions.dart';
import 'package:iasa/core/network/network_info.dart';
import 'package:iasa/core/utils/uuid_generator.dart';
import 'package:iasa/data/datasources/remote/api_datasource.dart';
import 'package:iasa/data/models/case_model.dart';
import 'package:iasa/data/models/media_upload_item.dart';
import 'package:iasa/domain/enums/case_status.dart';
import 'package:iasa/domain/enums/sync_status.dart';
import 'package:iasa/domain/enums/user_role.dart';

class FakeNetworkInfo implements NetworkInfo {
  FakeNetworkInfo({this.connected = true});

  bool connected;

  @override
  Future<bool> get isConnected async => connected;
}

class FakeUuidGenerator implements UuidGenerator {
  FakeUuidGenerator(this._ids);

  final List<String> _ids;
  var _index = 0;

  @override
  String generate() => _ids[_index++];
}

class TestApiDataSource implements ApiDataSource {
  TestApiDataSource({this.failSubmissions = false, this.failFetch = false});

  bool failSubmissions;
  bool failFetch;
  final List<String> submittedKeys = [];
  final Map<String, CaseModel> _cases = {};

  @override
  Future<List<CaseModel>> fetchCases() async {
    if (failFetch) {
      throw const NetworkException('fetch failed');
    }
    return _cases.values.toList();
  }

  @override
  Future<CaseModel> submitQuestion({
    required String idempotencyKey,
    required String title,
    required String questionBody,
    required UserRole submittedByRole,
    String? caseId,
  }) async {
    submittedKeys.add(idempotencyKey);

    final existing = _cases[idempotencyKey];
    if (existing != null) {
      return existing;
    }

    if (failSubmissions) {
      throw const NetworkException('submit failed');
    }

    final now = DateTime.utc(2026, 6, 1);
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
    _cases[idempotencyKey] = caseModel;
    return caseModel;
  }

  @override
  Future<void> uploadSubmissionMedia({
    required String submissionId,
    required List<MediaUploadItem> items,
  }) async {
    // No-op in tests unless overridden.
  }

  void seedCase(CaseModel caseModel) {
    _cases[caseModel.id] = caseModel;
  }
}
