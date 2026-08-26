import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/mock_test.dart';

class MockTestModel extends MockTest {
  const MockTestModel({
    required super.id,
    required super.title,
    required super.examType,
    required super.durationMinutes,
    required super.sectionCount,
    required super.isTimed,
  });

  factory MockTestModel.fromJson(Map<String, dynamic> json) {
    return MockTestModel(
      id: json['id'] as String,
      title: json['title'] as String,
      examType: ExamType.values.byName(json['examType'] as String),
      durationMinutes: json['durationMinutes'] as int,
      sectionCount: json['sectionCount'] as int,
      isTimed: json['isTimed'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'examType': examType.name,
        'durationMinutes': durationMinutes,
        'sectionCount': sectionCount,
        'isTimed': isTimed,
      };

  MockTest toEntity() => this;
}
