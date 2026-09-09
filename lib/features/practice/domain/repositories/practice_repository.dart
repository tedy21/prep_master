import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/exam_section.dart';
import '../../../../core/models/quiz_question.dart';
import '../entities/practice_session.dart';

abstract class PracticeRepository {
  Future<Either<Failure, PracticeSession>> getDailyPractice({
    required ExamType examType,
    required ExamSection section,
  });

  Future<Either<Failure, List<QuizQuestion>>> getQuizQuestions({
    required ExamType examType,
    ExamSection? section,
    int amount,
    String? mockTestId,
    String? difficulty,
  });

  Future<Either<Failure, Map<String, List<QuizQuestion>>>> getAdaptivePools({
    required ExamType examType,
    required ExamSection section,
    int perBucket,
  });
}
