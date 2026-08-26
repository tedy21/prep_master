/// Exceptions thrown by data sources; mapped to [Failure] in repositories.
class ServerException implements Exception {
  const ServerException([this.message = 'Server error occurred']);

  final String message;

  @override
  String toString() => 'ServerException: $message';
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'No internet connection']);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  const CacheException([this.message = 'Cache error occurred']);

  final String message;

  @override
  String toString() => 'CacheException: $message';
}

class AuthException implements Exception {
  const AuthException([this.message = 'Authentication failed']);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}
