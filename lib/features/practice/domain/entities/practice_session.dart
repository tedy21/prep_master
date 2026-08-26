import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

class PracticeSession extends Equatable {
  const PracticeSession({
    required this.id,
    required this.title,
    required this.examType,
    required this.skill,
    required this.estimatedMinutes,
    required this.questionCount,
  });

  final String id;
  final String title;
  final ExamType examType;
  final String skill;
  final int estimatedMinutes;
  final int questionCount;

  @override
  List<Object?> get props =>
      [id, title, examType, skill, estimatedMinutes, questionCount];
}
