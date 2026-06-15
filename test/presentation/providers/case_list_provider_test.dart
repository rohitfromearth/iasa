import 'package:flutter_test/flutter_test.dart';
import 'package:iasa/core/state/ui_state.dart';
import 'package:iasa/core/utils/result.dart';
import 'package:iasa/presentation/providers/case_list_provider.dart';

import 'provider_test_helpers.dart';

void main() {
  test('CaseListProvider loadCases maps success and empty states', () async {
    final provider = CaseListProvider(
      getCasesUseCase: StubGetCasesUseCase(Success([buildCase()])),
      refreshCasesUseCase: StubRefreshCasesUseCase(Success([buildCase()])),
    );

    await provider.loadCases();

    expect(provider.state, isA<UiSuccess>());
    expect((provider.state as UiSuccess).data, hasLength(1));
  });

  test('CaseListProvider refreshCases updates without redundant reload state',
      () async {
    final provider = CaseListProvider(
      getCasesUseCase: StubGetCasesUseCase(Success([buildCase()])),
      refreshCasesUseCase: StubRefreshCasesUseCase(const Success([])),
    );

    await provider.loadCases();
    await provider.refreshCases();

    expect(provider.isRefreshing, isFalse);
    expect(provider.state, isA<UiEmpty>());
  });
}
