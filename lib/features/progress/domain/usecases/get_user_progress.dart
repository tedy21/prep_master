import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_progress.dart';
import '../repositories/progress_repository.dart';

class GetUserProgress implements UseCase<UserProgress, NoParams> {
  GetUserProgress(this._repository);

  final ProgressRepository _repository;

  @override
  Future<Either<Failure, UserProgress>> call(NoParams params) {
    return _repository.getUserProgress();
  }
}
