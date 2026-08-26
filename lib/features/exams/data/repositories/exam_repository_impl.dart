import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/failure_mapper.dart';
import '../../domain/entities/mock_test.dart';
import '../../domain/repositories/exam_repository.dart';
import '../datasources/exam_local_datasource.dart';
import '../datasources/exam_remote_datasource.dart';

class ExamRepositoryImpl implements ExamRepository {
  ExamRepositoryImpl({
    required this.remote,
    required this.local,
    required this.networkInfo,
  });

  final ExamRemoteDataSource remote;
  final ExamLocalDataSource local;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, List<MockTest>>> getMockTests(
    ExamType examType,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        final remoteTests = await remote.getMockTests(examType);
        await local.cacheMockTests(examType, remoteTests);
        return Right(remoteTests.map((e) => e.toEntity()).toList());
      }

      final cached = await local.getCachedMockTests(examType);
      if (cached.isNotEmpty) {
        return Right(cached.map((e) => e.toEntity()).toList());
      }
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
