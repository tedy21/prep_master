import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

class CollegeGuide extends Equatable {
  const CollegeGuide({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.readMinutes,
    required this.checklistItems,
  });

  final String id;
  final String title;
  final String summary;
  final GuideCategory category;
  final int readMinutes;
  final List<String> checklistItems;

  @override
  List<Object?> get props =>
      [id, title, summary, category, readMinutes, checklistItems];
}
