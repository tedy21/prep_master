import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/quiz_session_record.dart';

abstract class QuizSessionRepository {
  Future<Either<Failure, QuizSessionRecord>> saveSession(
    QuizSessionRecord session,
  );

  Future<Either<Failure, List<QuizSessionRecord>>> getRecentSessions({
    int limit = 20,
  });
}
