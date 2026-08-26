import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/college_guide_model.dart';

abstract class CollegeGuideRemoteDataSource {
  Future<List<CollegeGuideModel>> getGuides({GuideCategory? category});
}

class CollegeGuideRemoteDataSourceImpl implements CollegeGuideRemoteDataSource {
  CollegeGuideRemoteDataSourceImpl(this.client);

  // ignore: unused_field
  final DioClient client;

  static const _seed = <CollegeGuideModel>[
    CollegeGuideModel(
      id: 'essay-personal-statement',
      title: 'Writing a Strong Personal Statement',
      summary:
          'Structure, voice, and common pitfalls for Common App / Coalition essays.',
      category: GuideCategory.essays,
      readMinutes: 12,
      checklistItems: [
        'Brainstorm 3 personal stories',
        'Draft hook + body + reflection',
        'Get 2 peer reviews',
      ],
    ),
    CollegeGuideModel(
      id: 'recs-ask-teachers',
      title: 'How to Ask for Recommendation Letters',
      summary: 'Who to ask, when to ask, and what materials to provide.',
      category: GuideCategory.recommendations,
      readMinutes: 8,
      checklistItems: [
        'Identify 2 academic recommenders',
        'Send brag sheet 4 weeks early',
        'Send thank-you note',
      ],
    ),
    CollegeGuideModel(
      id: 'deadlines-timeline',
      title: 'Application Timeline & Deadlines',
      summary: 'EA/ED/RD calendars, testing dates, and scholarship cutoffs.',
      category: GuideCategory.deadlines,
      readMinutes: 10,
      checklistItems: [
        'List target schools + deadlines',
        'Mark testing dates',
        'Set monthly checklist reminders',
      ],
    ),
    CollegeGuideModel(
      id: 'finaid-fafsa',
      title: 'Financial Aid & Scholarships 101',
      summary: 'FAFSA, CSS Profile, merit aid, and need-based packages.',
      category: GuideCategory.financialAid,
      readMinutes: 15,
      checklistItems: [
        'Create FSA ID',
        'Gather tax documents',
        'Search 5 external scholarships',
      ],
    ),
    CollegeGuideModel(
      id: 'interview-prep',
      title: 'Alumni Interview Prep',
      summary: 'Typical questions, storytelling tips, and follow-up etiquette.',
      category: GuideCategory.interviews,
      readMinutes: 9,
      checklistItems: [
        'Practice 5 common questions',
        'Prepare 3 questions for interviewer',
        'Send thank-you email within 24h',
      ],
    ),
  ];

  @override
  Future<List<CollegeGuideModel>> getGuides({GuideCategory? category}) async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (category == null) return _seed;
      return _seed.where((g) => g.category == category).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
