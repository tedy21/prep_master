import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/practice_session.dart';

class PracticeSessionModel extends PracticeSession {
  const PracticeSessionModel({
    required super.id,
    required super.title,
    required super.examType,
    required super.skill,
    required super.estimatedMinutes,
    required super.questionCount,
  });

  factory PracticeSessionModel.fromJson(Map<String, dynamic> json) {
    return PracticeSessionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      examType: ExamType.values.byName(json['examType'] as String),
      skill: json['skill'] as String,
      estimatedMinutes: json['estimatedMinutes'] as int,
      questionCount: json['questionCount'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'examType': examType.name,
        'skill': skill,
        'estimatedMinutes': estimatedMinutes,
        'questionCount': questionCount,
      };

  PracticeSession toEntity() => this;
}
