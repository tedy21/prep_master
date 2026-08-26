import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../entities/college_guide.dart';

abstract class CollegeGuideRepository {
  Future<Either<Failure, List<CollegeGuide>>> getGuides({
    GuideCategory? category,
  });
}
