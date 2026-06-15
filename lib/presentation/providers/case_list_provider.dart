import 'package:flutter/foundation.dart';

import '../../core/errors/failures.dart';
import '../../core/state/ui_state.dart';
import '../../core/usecases/usecase.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/case_entity.dart';
import '../../domain/enums/case_status.dart';
import '../../domain/usecases/get_cases_usecase.dart';
import '../../domain/usecases/refresh_cases_usecase.dart';
import 'provider_state.dart';

class CaseListProvider extends ChangeNotifier {
  CaseListProvider({
    required this._getCasesUseCase,
    required this._refreshCasesUseCase,
  });

  final GetCasesUseCase _getCasesUseCase;
  final RefreshCasesUseCase _refreshCasesUseCase;

  UiState<List<CaseEntity>> _state = const UiInitial();
  bool _isRefreshing = false;

  UiState<List<CaseEntity>> get state => _state;

  bool get isRefreshing => _isRefreshing;

  UiState<List<CaseEntity>> get moderatorQueueState => _filterNonClosed(_state);

  Future<void> loadCases() async {
    _setState(const UiLoading());

    final result = await _getCasesUseCase(const NoParams());
    _setState(_mapCasesResult(result));
  }

  Future<void> refreshCases() async {
    if (_isRefreshing) {
      return;
    }
    _isRefreshing = true;
    notifyListeners();

    final result = await _refreshCasesUseCase(const NoParams());
    _isRefreshing = false;

    final next = _mapCasesResult(result);
    if (!uiStatesEqual(
      _state,
      next,
      dataEquals: (a, b) => listsEqualById(a, b, (item) => item.id),
    )) {
      _state = next;
    }
    notifyListeners();
  }

  void _setState(UiState<List<CaseEntity>> next) {
    if (uiStatesEqual(
      _state,
      next,
      dataEquals: (a, b) => listsEqualById(a, b, (item) => item.id),
    )) {
      return;
    }
    _state = next;
    notifyListeners();
  }

  UiState<List<CaseEntity>> _mapCasesResult(Result<List<CaseEntity>> result) {
    return switch (result) {
      Success(data: final cases) when cases.isEmpty => const UiEmpty(
          message: 'No cases available',
        ),
      Success(data: final cases) => UiSuccess(cases),
      Error(failure: final failure) => UiError(
          _failureMessage(failure),
          cause: failure,
        ),
    };
  }

  String _failureMessage(Failure failure) => failure.message;

  UiState<List<CaseEntity>> _filterNonClosed(UiState<List<CaseEntity>> source) {
    switch (source) {
      case UiInitial():
        return const UiInitial();
      case UiLoading():
        return const UiLoading();
      case UiError(message: final message, cause: final cause):
        return UiError(message, cause: cause);
      case UiEmpty():
        return const UiEmpty(message: 'No open cases in queue');
      case UiSuccess(data: final cases):
        final filtered = cases
            .where((item) => item.status != CaseStatus.closed)
            .toList();
        if (filtered.isEmpty) {
          return const UiEmpty(message: 'No open cases in queue');
        }
        return UiSuccess(filtered);
    }
  }
}
