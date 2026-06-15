/// Data-layer exceptions thrown before mapping to [Failure]s.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class CacheException extends AppException {
  const CacheException([super.message = 'Local cache error']);
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error']);
}

final class DatabaseException extends AppException {
  const DatabaseException([super.message = 'Database error']);
}
