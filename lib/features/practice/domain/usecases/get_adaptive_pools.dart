import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/exam_section.dart';
import '../../../../core/models/quiz_question.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/practice_repository.dart';

class GetAdaptivePools
    implements
        UseCase<Map<String, List<QuizQuestion>>, GetAdaptivePoolsParams> {
  GetAdaptivePools(this._repository);

  final PracticeRepository _repository;

  @override
  Future<Either<Failure, Map<String, List<QuizQuestion>>>> call(
    GetAdaptivePoolsParams params,
  ) {
    return _repository.getAdaptivePools(
      examType: params.examType,
      section: params.section,
      perBucket: params.perBucket,
    );
  }
}

class GetAdaptivePoolsParams extends Equatable {
  const GetAdaptivePoolsParams({
    required this.examType,
    required this.section,
    this.perBucket = 12,
  });

  final ExamType examType;
  final ExamSection section;
  final int perBucket;

  @override
  List<Object?> get props => [examType, section, perBucket];
}
