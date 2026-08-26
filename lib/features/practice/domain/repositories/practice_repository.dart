import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../entities/practice_session.dart';

abstract class PracticeRepository {
  Future<Either<Failure, PracticeSession>> getDailyPractice(ExamType examType);
}
