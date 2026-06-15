import '../../core/state/ui_state.dart';

bool uiStatesEqual<T>(
  UiState<T> current,
  UiState<T> next, {
  bool Function(T a, T b)? dataEquals,
}) {
  if (current.runtimeType != next.runtimeType) {
    return false;
  }

  return switch ((current, next)) {
    (UiInitial<T>(), UiInitial<T>()) => true,
    (UiLoading<T>(), UiLoading<T>()) => true,
    (UiEmpty<T> a, UiEmpty<T> b) => a.message == b.message,
    (UiSuccess<T> a, UiSuccess<T> b) =>
      dataEquals != null ? dataEquals(a.data, b.data) : a.data == b.data,
    (UiError<T> a, UiError<T> b) =>
      a.message == b.message && a.cause == b.cause,
    _ => false,
  };
}

bool listsEqualById<T>(List<T> a, List<T> b, String Function(T item) id) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (id(a[i]) != id(b[i])) {
      return false;
    }
  }
  return true;
}
