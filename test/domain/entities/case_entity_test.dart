import 'package:flutter_test/flutter_test.dart';
import 'package:iasa/domain/entities/case_entity.dart';
import 'package:iasa/domain/enums/case_status.dart';
import 'package:iasa/domain/enums/sync_status.dart';
import 'package:iasa/domain/enums/user_role.dart';

void main() {
  final createdAt = DateTime.utc(2026, 1, 1);
  final updatedAt = DateTime.utc(2026, 1, 2);

  CaseEntity buildEntity() => CaseEntity(
        id: 'case-uuid-1',
        title: 'Headache',
        questionBody: 'Persistent headache for 3 days.',
        status: CaseStatus.submitted,
        createdByRole: UserRole.warrior,
        syncStatus: SyncStatus.pending,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  test('copyWith updates selected fields immutably', () {
    final original = buildEntity();
    final updated = original.copyWith(
      status: CaseStatus.answered,
      onlineStatus: CaseStatus.submitted,
      answerBody: 'Rest and hydrate.',
      syncStatus: SyncStatus.synced,
      verifiedAt: DateTime.utc(2026, 1, 3),
    );

    expect(original.status, CaseStatus.submitted);
    expect(updated.status, CaseStatus.answered);
    expect(updated.onlineStatus, CaseStatus.submitted);
    expect(updated.hasUnsyncedStatusChange, isTrue);
    expect(updated.answerBody, 'Rest and hydrate.');
    expect(updated.verifiedAt, DateTime.utc(2026, 1, 3));
  });

  test('equality is value-based', () {
    expect(buildEntity(), equals(buildEntity()));
  });
}
