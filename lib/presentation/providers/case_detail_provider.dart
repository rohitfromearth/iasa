import 'package:flutter/foundation.dart';



import '../../core/errors/failures.dart';

import '../../core/state/ui_state.dart';

import '../../core/usecases/usecase.dart';

import '../../core/utils/result.dart';

import '../../domain/entities/case_entity.dart';

import '../../domain/enums/case_status.dart';

import '../../domain/usecases/get_cases_usecase.dart';

import '../../domain/usecases/update_case_status_usecase.dart';

import '../../domain/value_objects/update_case_status_params.dart';

import 'provider_state.dart';



class CaseDetailProvider extends ChangeNotifier {

  CaseDetailProvider({

    required GetCasesUseCase getCasesUseCase,

    required UpdateCaseStatusUseCase updateCaseStatusUseCase,

  })  : _getCasesUseCase = getCasesUseCase,

        _updateCaseStatusUseCase = updateCaseStatusUseCase;



  final GetCasesUseCase _getCasesUseCase;

  final UpdateCaseStatusUseCase _updateCaseStatusUseCase;



  UiState<CaseEntity> _state = const UiInitial();

  String? _loadedCaseId;

  bool _isUpdating = false;

  String? _updateError;



  UiState<CaseEntity> get state => _state;



  String? get loadedCaseId => _loadedCaseId;



  bool get isUpdating => _isUpdating;



  String? get updateError => _updateError;



  Future<void> loadCase(String id) async {

    if (_loadedCaseId == id && _state is UiSuccess<CaseEntity>) {

      return;

    }



    _loadedCaseId = id;

    _setState(const UiLoading());



    final result = await _getCasesUseCase(const NoParams());

    _setState(_mapCaseResult(id, result));

  }



  void _setState(UiState<CaseEntity> next) {

    if (uiStatesEqual(_state, next, dataEquals: (a, b) => a == b)) {

      return;

    }

    _state = next;

    notifyListeners();

  }



  UiState<CaseEntity> _mapCaseResult(String id, Result<List<CaseEntity>> result) {

    return switch (result) {

      Success(data: final cases) => () {

          final match = cases.where((item) => item.id == id).firstOrNull;

          if (match == null) {

            return UiError<CaseEntity>('Case not found');

          }

          return UiSuccess(match);

        }(),

      Error(failure: final failure) => UiError(

          _failureMessage(failure),

          cause: failure,

        ),

    };

  }



  String _failureMessage(Failure failure) => failure.message;



  /// Persists a local status update while preserving last known online status.

  Future<void> updateCaseStatus(CaseStatus newStatus) async {

    if (_state is! UiSuccess<CaseEntity>) {

      _updateError = 'Case must be loaded before updating status';

      notifyListeners();

      return;

    }



    final current = (_state as UiSuccess<CaseEntity>).data;



    _isUpdating = true;

    _updateError = null;

    notifyListeners();



    final result = await _updateCaseStatusUseCase(

      UpdateCaseStatusParams(caseId: current.id, status: newStatus),

    );



    _isUpdating = false;



    switch (result) {

      case Success(data: final updated):

        _updateError = null;

        _setState(UiSuccess(updated));

      case Error(failure: final failure):

        _updateError = failure.message;

        notifyListeners();

    }

  }

}


