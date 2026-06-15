/// Generic UI state for screens that must support loading, empty, error, and success.
sealed class UiState<T> {
  const UiState();
}

final class UiInitial<T> extends UiState<T> {
  const UiInitial();
}

final class UiLoading<T> extends UiState<T> {
  const UiLoading();
}

final class UiEmpty<T> extends UiState<T> {
  const UiEmpty({this.message});

  final String? message;
}

final class UiSuccess<T> extends UiState<T> {
  const UiSuccess(this.data);

  final T data;
}

final class UiError<T> extends UiState<T> {
  const UiError(this.message, {this.cause});

  final String message;
  final Object? cause;
}
