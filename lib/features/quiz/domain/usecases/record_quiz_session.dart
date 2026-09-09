import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/exam_section.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../progress/domain/entities/user_progress.dart';
import '../../../progress/domain/repositories/progress_repository.dart';
import '../entities/quiz_question_outcome.dart';
import '../entities/quiz_session_record.dart';
import '../repositories/quiz_session_repository.dart';

class RecordQuizSession
    implements UseCase<UserProgress, RecordQuizSessionParams> {
  RecordQuizSession({
    required this.sessionRepository,
    required this.progressRepository,
  });

  final QuizSessionRepository sessionRepository;
  final ProgressRepository progressRepository;

  @override
  Future<Either<Failure, UserProgress>> call(
    RecordQuizSessionParams params,
  ) async {
    final session = QuizSessionRecord(
      id: params.sessionId,
      title: params.title,
      examType: params.examType,
      section: params.section,
      mockTestId: params.mockTestId,
      score: params.score,
      totalQuestions: params.totalQuestions,
      completedAt: DateTime.now(),
      questionOutcomes: params.questionOutcomes,
    );

    final sessionResult = await sessionRepository.saveSession(session);
    return sessionResult.fold(
      Left.new,
      (_) => progressRepository.recordQuizCompletion(
        correctCount: params.score,
        totalCount: params.totalQuestions,
        skillDeltas: session.skillDeltas,
      ),
    );
  }
}

class RecordQuizSessionParams extends Equatable {
  const RecordQuizSessionParams({
    required this.sessionId,
    required this.title,
    required this.examType,
    this.section,
    this.mockTestId,
    required this.score,
    required this.totalQuestions,
    this.questionOutcomes = const [],
  });

  final String sessionId;
  final String title;
  final ExamType examType;
  final ExamSection? section;
  final String? mockTestId;
  final int score;
  final int totalQuestions;
  final List<QuizQuestionOutcome> questionOutcomes;

  @override
  List<Object?> get props => [
        sessionId,
        title,
        examType,
        section,
        mockTestId,
        score,
        totalQuestions,
        questionOutcomes,
      ];
}
