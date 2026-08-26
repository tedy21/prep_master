import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
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
  Future<Either<Failure, PracticeSession>> getDailyPractice(
    ExamType examType,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        final remoteSession = await remote.getDailyPractice(examType);
        await local.cacheDailyPractice(remoteSession);
        return Right(remoteSession.toEntity());
      }

      final cached = await local.getCachedDailyPractice(examType);
      if (cached != null) return Right(cached.toEntity());
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
