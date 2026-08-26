import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/college_guide.dart';

class CollegeGuideModel extends CollegeGuide {
  const CollegeGuideModel({
    required super.id,
    required super.title,
    required super.summary,
    required super.category,
    required super.readMinutes,
    required super.checklistItems,
  });

  factory CollegeGuideModel.fromJson(Map<String, dynamic> json) {
    return CollegeGuideModel(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      category: GuideCategory.values.byName(json['category'] as String),
      readMinutes: json['readMinutes'] as int,
      checklistItems: (json['checklistItems'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'category': category.name,
        'readMinutes': readMinutes,
        'checklistItems': checklistItems,
      };

  CollegeGuide toEntity() => this;
}
