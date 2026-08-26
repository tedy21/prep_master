import '../error/exceptions.dart';
import '../error/failures.dart';

/// Maps low-level exceptions to domain [Failure]s.
Failure mapExceptionToFailure(Object error) {
  if (error is ServerException) return ServerFailure(error.message);
  if (error is NetworkException) return NetworkFailure(error.message);
  if (error is CacheException) return CacheFailure(error.message);
  if (error is AuthException) return AuthFailure(error.message);
  return UnexpectedFailure(error.toString());
}
