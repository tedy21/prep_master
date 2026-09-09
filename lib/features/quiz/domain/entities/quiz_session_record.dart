import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/exam_section.dart';
import 'quiz_question_outcome.dart';

class QuizSessionRecord extends Equatable {
  const QuizSessionRecord({
    required this.id,
    required this.title,
    required this.examType,
    this.section,
    this.mockTestId,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
    this.questionOutcomes = const [],
  });

  final String id;
  final String title;
  final ExamType examType;
  final ExamSection? section;
  final String? mockTestId;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;
  final List<QuizQuestionOutcome> questionOutcomes;

  double get percent =>
      totalQuestions == 0 ? 0 : score / totalQuestions * 100;

  Map<String, ({int correct, int total})> get skillDeltas {
    final map = <String, ({int correct, int total})>{};
    for (final o in questionOutcomes) {
      final skill = (o.skillArea ?? 'General').trim();
      if (skill.isEmpty) continue;
      final prev = map[skill] ?? (correct: 0, total: 0);
      map[skill] = (
        correct: prev.correct + (o.isCorrect ? 1 : 0),
        total: prev.total + 1,
      );
    }
    return map;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        examType,
        section,
        mockTestId,
        score,
        totalQuestions,
        completedAt,
        questionOutcomes,
      ];
}
