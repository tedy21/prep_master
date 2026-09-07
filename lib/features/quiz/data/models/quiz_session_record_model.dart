import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/exam_section.dart';
import '../../domain/entities/quiz_session_record.dart';

class QuizSessionRecordModel extends QuizSessionRecord {
  const QuizSessionRecordModel({
    required super.id,
    required super.title,
    required super.examType,
    super.section,
    super.mockTestId,
    required super.score,
    required super.totalQuestions,
    required super.completedAt,
  });

  factory QuizSessionRecordModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return QuizSessionRecordModel(
      id: id,
      title: data['title'] as String? ?? 'Quiz',
      examType: ExamType.values.byName(
        data['examType'] as String? ?? ExamType.general.name,
      ),
      section: ExamSection.tryParse(data['section'] as String?),
      mockTestId: data['mockTestId'] as String?,
      score: data['score'] as int? ?? 0,
      totalQuestions: data['totalQuestions'] as int? ?? 0,
      completedAt: (data['completedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'examType': examType.name,
        if (section != null) 'section': section!.firestoreKey,
        if (mockTestId != null) 'mockTestId': mockTestId,
        'score': score,
        'totalQuestions': totalQuestions,
        'percent': percent,
      };

  QuizSessionRecord toEntity() => this;
}
