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
      final model = QuizSessionRecordModel(
        id: session.id,
        title: session.title,
        examType: session.examType,
        section: session.section,
        mockTestId: session.mockTestId,
        score: session.score,
        totalQuestions: session.totalQuestions,
        completedAt: session.completedAt,
      );
      await remote.saveSession(model);
      return Right(session);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
