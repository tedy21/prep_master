import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/exam_section.dart';

/// Summary of a completed quiz, stored in Firestore session history.
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
  });

  final String id;
  final String title;
  final ExamType examType;
  final ExamSection? section;
  final String? mockTestId;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;

  double get percent =>
      totalQuestions == 0 ? 0 : score / totalQuestions * 100;

  @override
  List<Object?> get props =>
      [id, title, examType, section, mockTestId, score, totalQuestions, completedAt];
}
