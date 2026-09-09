import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/progress_dashboard.dart';
import '../repositories/progress_repository.dart';

class GetProgressDashboard implements UseCase<ProgressDashboard, NoParams> {
  GetProgressDashboard(this._repository);

  final ProgressRepository _repository;

  @override
  Future<Either<Failure, ProgressDashboard>> call(NoParams params) {
    return _repository.getProgressDashboard();
  }
}
