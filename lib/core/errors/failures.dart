/// Domain-layer failure types returned by repositories and use cases.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local cache failure']);
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network failure']);
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Database failure']);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Unexpected error']);
}
