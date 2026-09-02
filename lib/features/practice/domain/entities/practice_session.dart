import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/exam_section.dart';

class PracticeSession extends Equatable {
  const PracticeSession({
    required this.id,
    required this.title,
    required this.examType,
    required this.section,
    required this.estimatedMinutes,
    required this.questionCount,
  });

  final String id;
  final String title;
  final ExamType examType;
  final ExamSection section;
  final int estimatedMinutes;
  final int questionCount;

  @override
  List<Object?> get props =>
      [id, title, examType, section, estimatedMinutes, questionCount];
}
