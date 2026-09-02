import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/exam_section.dart';

/// Arguments passed when opening a quiz session.
class QuizSessionArgs extends Equatable {
  const QuizSessionArgs({
    required this.title,
    required this.examType,
    this.section,
    this.questionCount = 10,
    this.mockTestId,
  });

  final String title;
  final ExamType examType;
  final ExamSection? section;
  final int questionCount;
  final String? mockTestId;

  @override
  List<Object?> get props =>
      [title, examType, section, questionCount, mockTestId];
}
