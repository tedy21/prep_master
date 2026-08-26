import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_progress.dart';

abstract class ProgressRepository {
  Future<Either<Failure, UserProgress>> getUserProgress();
}
