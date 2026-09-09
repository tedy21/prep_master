import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/failure_mapper.dart';
import '../../domain/entities/quiz_session_record.dart';
import '../../domain/repositories/quiz_session_repository.dart';
import '../datasources/quiz_session_remote_datasource.dart';
import '../models/quiz_session_record_model.dart';

class QuizSessionRepositoryImpl implements QuizSessionRepository {
  QuizSessionRepositoryImpl({required this.remote});

  final QuizSessionRemoteDataSource remote;

  @override
  Future<Either<Failure, QuizSessionRecord>> saveSession(
    QuizSessionRecord session,
  ) async {
    try {
      await remote.saveSession(QuizSessionRecordModel.fromEntity(session));
      return Right(session);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<QuizSessionRecord>>> getRecentSessions({
    int limit = 20,
  }) async {
    try {
      final models = await remote.getRecentSessions(limit: limit);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
