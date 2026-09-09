import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/failure_mapper.dart';
import '../../../quiz/domain/repositories/quiz_session_repository.dart';
import '../../domain/entities/ai_insight.dart';
import '../../domain/entities/progress_dashboard.dart';
import '../../domain/entities/user_progress.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/services/fallback_coach.dart';
import '../datasources/progress_ai_remote_datasource.dart';
import '../datasources/progress_local_datasource.dart';
import '../datasources/progress_remote_datasource.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl({
    required this.remote,
    required this.local,
    required this.networkInfo,
    required this.sessionRepository,
    required this.aiRemote,
  });

  final ProgressRemoteDataSource remote;
  final ProgressLocalDataSource local;
  final NetworkInfo networkInfo;
  final QuizSessionRepository sessionRepository;
  final ProgressAiRemoteDataSource aiRemote;

  @override
  Future<Either<Failure, UserProgress>> getUserProgress() async {
    try {
      if (await networkInfo.isConnected) {
        final remoteProgress = await remote.getUserProgress();
        await local.cacheProgress(remoteProgress);
        return Right(remoteProgress.toEntity());
      }

      final cached = await local.getCachedProgress();
      if (cached != null) return Right(cached.toEntity());
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, ProgressDashboard>> getProgressDashboard() async {
    try {
      if (!await networkInfo.isConnected) {
        final cached = await local.getCachedProgress();
        if (cached == null) return const Left(NetworkFailure());
        final dashboard = ProgressDashboard(
          progress: cached.toEntity(),
          skillStats: const [],
          recentSessions: const [],
          aiInsight: FallbackCoach.build(
            ProgressDashboard(
              progress: cached.toEntity(),
              skillStats: const [],
              recentSessions: const [],
            ),
          ),
        );
        return Right(dashboard);
      }

      final summary = await remote.getProgressSummary();
      await local.cacheProgress(summary.progress);

      final sessionsResult =
          await sessionRepository.getRecentSessions(limit: 20);
      final sessions = sessionsResult.getOrElse(() => const []);
      final cachedInsight = await remote.getAiInsights();

      var dashboard = ProgressDashboard(
        progress: summary.progress.toEntity(),
        skillStats: summary.skillStats,
        recentSessions: sessions,
        aiInsight: cachedInsight,
      );

      if (cachedInsight == null || cachedInsight.isStale) {
        dashboard = dashboard.copyWith(
          aiInsight: FallbackCoach.build(dashboard),
        );
      }

      return Right(dashboard);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UserProgress>> recordQuizCompletion({
    required int correctCount,
    required int totalCount,
    Map<String, ({int correct, int total})>? skillDeltas,
  }) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure());
      }
      final updated = await remote.recordQuizCompletion(
        correctCount: correctCount,
        totalCount: totalCount,
        skillDeltas: skillDeltas,
      );
      await local.cacheProgress(updated);
      return Right(updated.toEntity());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, AiInsight>> refreshAiInsights({
    required ProgressDashboard dashboard,
    bool force = false,
  }) async {
    try {
      if (!await networkInfo.isConnected) {
        return Right(FallbackCoach.build(dashboard));
      }

      if (!force &&
          dashboard.aiInsight != null &&
          !dashboard.aiInsight!.isStale &&
          !dashboard.aiInsight!.isFallback) {
        return Right(dashboard.aiInsight!);
      }

      final insight = await aiRemote.generateInsights(
        dashboard: dashboard,
        force: force,
      );
      return Right(insight);
    } catch (_) {
      return Right(FallbackCoach.build(dashboard));
    }
  }
}
