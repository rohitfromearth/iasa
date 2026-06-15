import '../utils/result.dart';

/// Base contract for domain use cases.
abstract interface class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

/// Use when a use case requires no input parameters.
class NoParams {
  const NoParams();
}
