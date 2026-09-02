import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/data/firestore_quiz_datasource.dart';
import '../../../../core/firebase/firebase_service.dart';
import '../../../../core/models/exam_section.dart';
import '../../../../core/models/quiz_question.dart';
import '../../../../core/network/open_trivia_client.dart';
import '../../../../core/network/trivia_api_client.dart';
import '../models/practice_session_model.dart';

abstract class PracticeRemoteDataSource {
  Future<PracticeSessionModel> getDailyPractice({
    required ExamType examType,
    required ExamSection section,
  });

  Future<List<QuizQuestion>> getQuizQuestions({
    required ExamType examType,
    ExamSection? section,
    int amount = 10,
    String difficulty = 'medium',
    String? mockTestId,
  });
}

class PracticeRemoteDataSourceImpl implements PracticeRemoteDataSource {
  PracticeRemoteDataSourceImpl({
    required this.firebase,
    required this.firestoreQuiz,
    required this.openTrivia,
    required this.triviaApi,
  });

  final FirebaseService firebase;
  final FirestoreQuizDataSource firestoreQuiz;
  final OpenTriviaClient openTrivia;
  final TriviaApiClient triviaApi;

  @override
  Future<PracticeSessionModel> getDailyPractice({
    required ExamType examType,
    required ExamSection section,
  }) async {
    final count = await firestoreQuiz.questionCount(
      examType: examType,
      section: section,
    );

    return PracticeSessionModel(
      id: 'daily-${examType.name}-${section.id}-${DateTime.now().day}',
      title: section.practiceTitle(examType),
      examType: examType,
      section: section,
      estimatedMinutes: section.estimatedMinutes,
      questionCount: count > 0
          ? count.clamp(3, section.defaultQuestionCount)
          : section.defaultQuestionCount,
    );
  }

  @override
  Future<List<QuizQuestion>> getQuizQuestions({
    required ExamType examType,
    ExamSection? section,
    int amount = 10,
    String difficulty = 'medium',
    String? mockTestId,
  }) async {
    // 1) Firestore — primary content source (update without app release)
    try {
      final firestore = await firestoreQuiz.getQuestions(
        examType: examType,
        section: section,
        amount: amount,
        mockTestId: mockTestId,
      );
      if (firestore.isNotEmpty) {
        return firestore;
      }
    } on FirebaseException {
      // Fall through to API fallback when Firestore is empty/unavailable.
    }

    // 2) Free trivia APIs — last resort only when Firestore has no content
    return _fetchFromTriviaApi(
      examType: examType,
      amount: amount,
      difficulty: difficulty,
    );
  }

  Future<List<QuizQuestion>> _fetchFromTriviaApi({
    required ExamType examType,
    required int amount,
    required String difficulty,
  }) async {
    if (examType == ExamType.ielts) {
      final api = await openTrivia.fetchQuestions(
        amount: amount,
        category: 10,
        difficulty: difficulty,
      );
      return api.map((q) => q.copyWith(examType: examType.name)).toList();
    }
    if (examType == ExamType.sat) {
      try {
        final api = await triviaApi.fetchQuestions(
          limit: amount,
          difficulties: difficulty,
          categories: 'science',
        );
        return api.map((q) => q.copyWith(examType: examType.name)).toList();
      } catch (_) {
        final api = await openTrivia.fetchQuestions(
          amount: amount,
          category: 17,
          difficulty: difficulty,
        );
        return api.map((q) => q.copyWith(examType: examType.name)).toList();
      }
    }
    final api = await openTrivia.fetchQuestions(
      amount: amount,
      category: 9,
      difficulty: difficulty,
    );
    return api.map((q) => q.copyWith(examType: examType.name)).toList();
  }
}
