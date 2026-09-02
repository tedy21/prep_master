import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/exam_section.dart';
import '../../../../core/models/quiz_question.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/failure_mapper.dart';
import '../../domain/entities/practice_session.dart';
import '../../domain/repositories/practice_repository.dart';
import '../datasources/practice_local_datasource.dart';
import '../datasources/practice_remote_datasource.dart';

class PracticeRepositoryImpl implements PracticeRepository {
  PracticeRepositoryImpl({
    required this.remote,
    required this.local,
    required this.networkInfo,
  });

  final PracticeRemoteDataSource remote;
  final PracticeLocalDataSource local;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, PracticeSession>> getDailyPractice({
    required ExamType examType,
    required ExamSection section,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final remoteSession = await remote.getDailyPractice(
          examType: examType,
          section: section,
        );
        await local.cacheDailyPractice(remoteSession);
        return Right(remoteSession.toEntity());
      }

      final cached = await local.getCachedDailyPractice(examType, section);
      if (cached != null) return Right(cached.toEntity());

      final offlineSession = await remote.getDailyPractice(
        examType: examType,
        section: section,
      );
      return Right(offlineSession.toEntity());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<QuizQuestion>>> getQuizQuestions({
    required ExamType examType,
    ExamSection? section,
    int amount = 10,
    String? mockTestId,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final questions = await remote.getQuizQuestions(
            examType: examType,
            section: section,
            amount: amount,
            mockTestId: mockTestId,
          );
          if (questions.isNotEmpty) {
            await local.cacheQuizQuestions(
              examType: examType,
              section: section,
              mockTestId: mockTestId,
              questions: questions,
            );
            return Right(questions);
          }
        } catch (_) {
          return _loadOffline(
            examType: examType,
            section: section,
            amount: amount,
            mockTestId: mockTestId,
          );
        }
      }

      return _loadOffline(
        examType: examType,
        section: section,
        amount: amount,
        mockTestId: mockTestId,
      );
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  Future<Either<Failure, List<QuizQuestion>>> _loadOffline({
    required ExamType examType,
    ExamSection? section,
    required int amount,
    String? mockTestId,
  }) async {
    final cached = await local.getCachedQuizQuestions(
      examType: examType,
      section: section,
      mockTestId: mockTestId,
    );
    if (cached != null && cached.isNotEmpty) {
      return Right(cached.take(amount).toList());
    }

    final offline = await remote.getQuizQuestions(
      examType: examType,
      section: section,
      amount: amount,
      mockTestId: mockTestId,
    );
    if (offline.isEmpty) {
      return const Left(CacheFailure('No offline questions available'));
    }
    return Right(offline);
  }
}
