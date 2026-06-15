import 'package:flutter_test/flutter_test.dart';
import 'package:iasa/data/datasources/remote/mock_api_datasource.dart';
import 'package:iasa/domain/enums/user_role.dart';

void main() {
  group('MockApiDataSource idempotency', () {
    test('duplicate submission with same UUID returns the same case', () async {
      final api = MockApiDataSource(
        failureRate: 0,
        minLatency: Duration.zero,
        maxLatency: Duration.zero,
      );

      const idempotencyKey = 'submission-uuid-1';

      final first = await api.submitQuestion(
        idempotencyKey: idempotencyKey,
        title: 'Headache',
        questionBody: 'Pain for 3 days',
        submittedByRole: UserRole.warrior,
      );

      final second = await api.submitQuestion(
        idempotencyKey: idempotencyKey,
        title: 'Different title',
        questionBody: 'Different body',
        submittedByRole: UserRole.warrior,
      );

      expect(second.id, first.id);
      expect(second.id, idempotencyKey);
      expect(second.title, first.title);
      expect(second.questionBody, first.questionBody);
    });
  });
}
