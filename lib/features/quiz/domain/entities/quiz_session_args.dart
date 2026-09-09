import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/question_difficulty.dart';
import '../../../../core/models/exam_section.dart';

class QuizSessionArgs extends Equatable {
  const QuizSessionArgs({
    required this.title,
    required this.examType,
    this.section,
    this.questionCount = 10,
    this.mockTestId,
    this.adaptive = false,
    this.initialDifficulty = QuestionDifficulty.medium,
    this.timeLimitMinutes,
  });

  final String title;
  final ExamType examType;
  final ExamSection? section;
  final int questionCount;
  final String? mockTestId;
  final bool adaptive;
  final String initialDifficulty;
  final int? timeLimitMinutes;

  bool get isTimed => timeLimitMinutes != null && timeLimitMinutes! > 0;

  @override
  List<Object?> get props => [
        title,
        examType,
        section,
        questionCount,
        mockTestId,
        adaptive,
        initialDifficulty,
        timeLimitMinutes,
      ];
}
