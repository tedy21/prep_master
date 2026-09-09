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
    String? difficulty,
  }) async {
    try {
      // PracticeRemote also reads bundled quiz_bank.json (works offline).
      final questions = await remote.getQuizQuestions(
        examType: examType,
        section: section,
        amount: amount,
        mockTestId: mockTestId,
        difficulty: difficulty ?? 'medium',
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

      return _loadOffline(
        examType: examType,
        section: section,
        amount: amount,
        mockTestId: mockTestId,
      );
    } catch (e) {
      final offline = await _loadOffline(
        examType: examType,
        section: section,
        amount: amount,
        mockTestId: mockTestId,
      );
      if (offline.isRight()) return offline;
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Map<String, List<QuizQuestion>>>> getAdaptivePools({
    required ExamType examType,
    required ExamSection section,
    int perBucket = 12,
  }) async {
    try {
      final pools = await remote.getAdaptivePools(
        examType: examType,
        section: section,
        perBucket: perBucket,
      );
      var total = pools.values.fold<int>(0, (n, list) => n + list.length);
      if (total > 0) return Right(pools);

      // Offline / empty remote: rebuild pools from any cached section questions.
      final cached = await local.getCachedQuizQuestions(
        examType: examType,
        section: section,
      );
      if (cached != null && cached.isNotEmpty) {
        final grouped = <String, List<QuizQuestion>>{
          'easy': [],
          'medium': [],
          'hard': [],
        };
        for (final q in cached) {
          final key = (q.difficulty).trim().toLowerCase();
          final bucket = key == 'easy' || key == 'hard' ? key : 'medium';
          grouped[bucket] = [...grouped[bucket]!, q];
        }
        total = grouped.values.fold<int>(0, (n, list) => n + list.length);
        if (total > 0) return Right(grouped);
      }

      return const Left(
        CacheFailure('No adaptive questions available for this section yet.'),
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
