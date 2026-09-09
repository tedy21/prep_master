import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/exam_section.dart';
import '../../domain/entities/quiz_question_outcome.dart';
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
    super.questionOutcomes,
  });

  factory QuizSessionRecordModel.fromEntity(QuizSessionRecord session) {
    return QuizSessionRecordModel(
      id: session.id,
      title: session.title,
      examType: session.examType,
      section: session.section,
      mockTestId: session.mockTestId,
      score: session.score,
      totalQuestions: session.totalQuestions,
      completedAt: session.completedAt,
      questionOutcomes: session.questionOutcomes,
    );
  }

  factory QuizSessionRecordModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final rawOutcomes = data['questionOutcomes'] as List<dynamic>? ?? const [];
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
      questionOutcomes: rawOutcomes
          .whereType<Map<String, dynamic>>()
          .map(QuizQuestionOutcome.fromMap)
          .toList(),
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
        if (questionOutcomes.isNotEmpty)
          'questionOutcomes':
              questionOutcomes.map((o) => o.toMap()).toList(),
      };

  QuizSessionRecord toEntity() => this;
}
