import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../entities/mock_test.dart';

abstract class ExamRepository {
  Future<Either<Failure, List<MockTest>>> getMockTests(ExamType examType);
}
