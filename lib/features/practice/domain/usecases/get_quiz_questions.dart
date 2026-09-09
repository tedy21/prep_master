import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/exam_section.dart';
import '../../../../core/models/quiz_question.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/practice_repository.dart';

class GetQuizQuestions
    implements UseCase<List<QuizQuestion>, GetQuizQuestionsParams> {
  GetQuizQuestions(this._repository);

  final PracticeRepository _repository;

  @override
  Future<Either<Failure, List<QuizQuestion>>> call(
    GetQuizQuestionsParams params,
  ) {
    return _repository.getQuizQuestions(
      examType: params.examType,
      section: params.section,
      amount: params.amount,
      mockTestId: params.mockTestId,
      difficulty: params.difficulty,
    );
  }
}

class GetQuizQuestionsParams extends Equatable {
  const GetQuizQuestionsParams({
    required this.examType,
    this.section,
    this.amount = 10,
    this.mockTestId,
    this.difficulty,
  });

  final ExamType examType;
  final ExamSection? section;
  final int amount;
  final String? mockTestId;
  final String? difficulty;

  @override
  List<Object?> get props =>
      [examType, section, amount, mockTestId, difficulty];
}
