import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/exam_section.dart';
import '../../domain/entities/practice_session.dart';

class PracticeSessionModel extends PracticeSession {
  const PracticeSessionModel({
    required super.id,
    required super.title,
    required super.examType,
    required super.section,
    required super.estimatedMinutes,
    required super.questionCount,
  });

  factory PracticeSessionModel.fromJson(Map<String, dynamic> json) {
    final sectionId = json['section'] as String? ?? json['skill'] as String?;
    return PracticeSessionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      examType: ExamType.values.byName(json['examType'] as String),
      section: ExamSection.tryParse(sectionId) ??
          ExamSection.defaultFor(
            ExamType.values.byName(json['examType'] as String),
          ),
      estimatedMinutes: json['estimatedMinutes'] as int,
      questionCount: json['questionCount'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'examType': examType.name,
        'section': section.id,
        'estimatedMinutes': estimatedMinutes,
        'questionCount': questionCount,
      };

  PracticeSession toEntity() => this;
}
