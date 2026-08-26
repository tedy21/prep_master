import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

class MockTest extends Equatable {
  const MockTest({
    required this.id,
    required this.title,
    required this.examType,
    required this.durationMinutes,
    required this.sectionCount,
    required this.isTimed,
  });

  final String id;
  final String title;
  final ExamType examType;
  final int durationMinutes;
  final int sectionCount;
  final bool isTimed;

  @override
  List<Object?> get props =>
      [id, title, examType, durationMinutes, sectionCount, isTimed];
}
