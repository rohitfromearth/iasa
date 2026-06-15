import 'package:flutter_test/flutter_test.dart';
import 'package:iasa/core/state/ui_state.dart';
import 'package:iasa/core/utils/result.dart';
import 'package:iasa/domain/usecases/update_case_status_usecase.dart';
import 'package:iasa/presentation/providers/case_detail_provider.dart';

import 'provider_test_helpers.dart';

void main() {
  test('CaseDetailProvider loadCase resolves matching case', () async {
    final provider = CaseDetailProvider(
      getCasesUseCase: StubGetCasesUseCase(
        Success([buildCase(id: 'case-1'), buildCase(id: 'case-2')]),
      ),
      updateCaseStatusUseCase: StubUpdateCaseStatusUseCase(
        Success(buildCase(id: 'case-1')),
      ),
    );

    await provider.loadCase('case-2');

    expect(provider.state, isA<UiSuccess>());
    expect((provider.state as UiSuccess).data.id, 'case-2');
  });

  test('CaseDetailProvider loadCase returns error when case is missing',
      () async {
    final provider = CaseDetailProvider(
      getCasesUseCase: StubGetCasesUseCase(Success([buildCase(id: 'case-1')])),
      updateCaseStatusUseCase: StubUpdateCaseStatusUseCase(
        Success(buildCase(id: 'case-1')),
      ),
    );

    await provider.loadCase('missing');

    expect(provider.state, isA<UiError>());
  });
}
