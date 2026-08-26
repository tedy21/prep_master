import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/failure_mapper.dart';
import '../../domain/entities/college_guide.dart';
import '../../domain/repositories/college_guide_repository.dart';
import '../datasources/college_guide_local_datasource.dart';
import '../datasources/college_guide_remote_datasource.dart';

class CollegeGuideRepositoryImpl implements CollegeGuideRepository {
  CollegeGuideRepositoryImpl({
    required this.remote,
    required this.local,
    required this.networkInfo,
  });

  final CollegeGuideRemoteDataSource remote;
  final CollegeGuideLocalDataSource local;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, List<CollegeGuide>>> getGuides({
    GuideCategory? category,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final remoteGuides = await remote.getGuides(category: category);
        if (category == null) {
          await local.cacheGuides(remoteGuides);
        }
        return Right(remoteGuides.map((e) => e.toEntity()).toList());
      }

      var cached = await local.getCachedGuides();
      if (category != null) {
        cached = cached.where((g) => g.category == category).toList();
      }
      if (cached.isNotEmpty) {
        return Right(cached.map((e) => e.toEntity()).toList());
      }
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
