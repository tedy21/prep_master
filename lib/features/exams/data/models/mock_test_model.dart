import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/exam_section.dart';
import '../../domain/entities/mock_test.dart';

class MockTestModel extends MockTest {
  const MockTestModel({
    required super.id,
    required super.title,
    required super.examType,
    required super.durationMinutes,
    required super.sectionCount,
    required super.isTimed,
    super.section,
  });

  factory MockTestModel.fromJson(Map<String, dynamic> json) {
    return MockTestModel(
      id: json['id'] as String,
      title: json['title'] as String,
      examType: ExamType.values.byName(json['examType'] as String),
      durationMinutes: json['durationMinutes'] as int,
      sectionCount: json['sectionCount'] as int,
      isTimed: json['isTimed'] as bool,
      section: ExamSection.tryParse(json['section'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'examType': examType.name,
        'durationMinutes': durationMinutes,
        'sectionCount': sectionCount,
        'isTimed': isTimed,
        if (section != null) 'section': section!.id,
      };

  MockTest toEntity() => this;
}
