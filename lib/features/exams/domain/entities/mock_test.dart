import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/exam_section.dart';

class MockTest extends Equatable {
  const MockTest({
    required this.id,
    required this.title,
    required this.examType,
    required this.durationMinutes,
    required this.sectionCount,
    required this.isTimed,
    this.section,
  });

  final String id;
  final String title;
  final ExamType examType;
  final int durationMinutes;
  final int sectionCount;
  final bool isTimed;

  /// `null` = full mock spanning multiple sections/skills.
  final ExamSection? section;

  bool get isFullMock => section == null;

  @override
  List<Object?> get props =>
      [id, title, examType, durationMinutes, sectionCount, isTimed, section];
}
