import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/failure_mapper.dart';
import '../../domain/entities/user_progress.dart';
import '../../domain/repositories/progress_repository.dart';
import '../datasources/progress_local_datasource.dart';
import '../datasources/progress_remote_datasource.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl({
    required this.remote,
    required this.local,
    required this.networkInfo,
  });

  final ProgressRemoteDataSource remote;
  final ProgressLocalDataSource local;
  final NetworkInfo networkInfo;

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
  Future<Either<Failure, UserProgress>> recordQuizCompletion({
    required int correctCount,
    required int totalCount,
  }) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure());
      }
      final updated = await remote.recordQuizCompletion(
        correctCount: correctCount,
        totalCount: totalCount,
      );
      await local.cacheProgress(updated);
      return Right(updated.toEntity());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
