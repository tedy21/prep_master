import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/practice_session.dart';
import '../repositories/practice_repository.dart';

class GetDailyPractice
    implements UseCase<PracticeSession, GetDailyPracticeParams> {
  GetDailyPractice(this._repository);

  final PracticeRepository _repository;

  @override
  Future<Either<Failure, PracticeSession>> call(
    GetDailyPracticeParams params,
  ) {
    return _repository.getDailyPractice(params.examType);
  }
}

class GetDailyPracticeParams extends Equatable {
  const GetDailyPracticeParams({required this.examType});

  final ExamType examType;

  @override
  List<Object?> get props => [examType];
}
