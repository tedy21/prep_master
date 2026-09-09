import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/data/firestore_quiz_datasource.dart';
import '../../../../core/data/local_quiz_bank_datasource.dart';
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

  Future<Map<String, List<QuizQuestion>>> getAdaptivePools({
    required ExamType examType,
    required ExamSection section,
    int perBucket = 12,
  });
}

class PracticeRemoteDataSourceImpl implements PracticeRemoteDataSource {
  PracticeRemoteDataSourceImpl({
    required this.firebase,
    required this.firestoreQuiz,
    required this.localQuizBank,
    required this.openTrivia,
    required this.triviaApi,
  });

  final FirebaseService firebase;
  final FirestoreQuizDataSource firestoreQuiz;
  final LocalQuizBankDataSource localQuizBank;
  final OpenTriviaClient openTrivia;
  final TriviaApiClient triviaApi;

  bool _needsRichContext(ExamSection? section) =>
      section == ExamSection.reading ||
      section == ExamSection.listening ||
      section == ExamSection.writing;

  bool _hasEnoughContext(List<QuizQuestion> questions) {
    if (questions.isEmpty) return false;
    final withContext = questions.where((q) => q.hasContext).length;
    return withContext >= (questions.length / 2).ceil();
  }

  @override
  Future<PracticeSessionModel> getDailyPractice({
    required ExamType examType,
    required ExamSection section,
  }) async {
    var count = await firestoreQuiz.questionCount(
      examType: examType,
      section: section,
    );
    if (count <= 0 || _needsRichContext(section)) {
      final local = await localQuizBank.getQuestions(
        examType: examType,
        section: section,
        amount: 50,
      );
      if (local.isNotEmpty) count = local.length;
    }

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
    // Mocks stay on Firestore IDs when available.
    if (mockTestId != null) {
      try {
        final firestore = await firestoreQuiz.getQuestions(
          examType: examType,
          section: section,
          amount: amount,
          mockTestId: mockTestId,
        );
        if (firestore.isNotEmpty &&
            (!_needsRichContext(section) || _hasEnoughContext(firestore))) {
          return firestore;
        }
      } on FirebaseException {
        // Fall through.
      }
    }

    // Prefer bundled quiz bank for Reading / Listening / Writing so users
    // always see passages and Academic Writing prompts — even if Firestore
    // still has stale MCQs without context.
    if (_needsRichContext(section)) {
      final local = await localQuizBank.getQuestions(
        examType: examType,
        section: section,
        amount: amount,
        difficulty: difficulty,
      );
      if (local.isNotEmpty) return local;
    }

    try {
      final firestore = await firestoreQuiz.getQuestions(
        examType: examType,
        section: section,
        amount: amount,
        mockTestId: mockTestId,
        difficulty: mockTestId == null ? difficulty : null,
      );
      if (firestore.isNotEmpty) {
        if (_needsRichContext(section) && !_hasEnoughContext(firestore)) {
          final local = await localQuizBank.getQuestions(
            examType: examType,
            section: section,
            amount: amount,
          );
          if (local.isNotEmpty) return local;
        }
        return firestore;
      }
    } on FirebaseException {
      // Fall through.
    }

    final local = await localQuizBank.getQuestions(
      examType: examType,
      section: section,
      amount: amount,
      difficulty: difficulty,
    );
    if (local.isNotEmpty) return local;

    return _fetchFromTriviaApi(
      examType: examType,
      amount: amount,
      difficulty: difficulty,
    );
  }

  @override
  Future<Map<String, List<QuizQuestion>>> getAdaptivePools({
    required ExamType examType,
    required ExamSection section,
    int perBucket = 12,
  }) async {
    Map<String, List<QuizQuestion>> pools = {
      'easy': [],
      'medium': [],
      'hard': [],
    };

    final needsContext = _needsRichContext(section);

    if (needsContext) {
      pools = await localQuizBank.getAdaptivePools(
        examType: examType,
        section: section,
        perBucket: perBucket,
      );
      final total = pools.values.fold<int>(0, (n, list) => n + list.length);
      if (total > 0) {
        for (final diff in pools.keys.toList()) {
          pools[diff] =
              (pools[diff] ?? []).where((q) => q.hasContext).toList();
        }
        final kept = pools.values.fold<int>(0, (n, list) => n + list.length);
        if (kept > 0) return pools;
      }
    }

    try {
      pools = await firestoreQuiz.getAdaptivePools(
        examType: examType,
        section: section,
        perBucket: perBucket,
      );
    } on FirebaseException {
      // Fall through.
    }

    if (!needsContext) {
      for (final diff in ['easy', 'medium', 'hard']) {
        final bucket = pools[diff] ?? [];
        if (bucket.isNotEmpty) continue;
        try {
          final extras = await _fetchFromTriviaApi(
            examType: examType,
            amount: perBucket,
            difficulty: diff,
          );
          pools[diff] = extras;
        } catch (_) {
          pools[diff] = bucket;
        }
      }
    } else {
      for (final diff in pools.keys.toList()) {
        pools[diff] =
            (pools[diff] ?? []).where((q) => q.hasContext).toList();
      }
      final total = pools.values.fold<int>(0, (n, list) => n + list.length);
      if (total == 0) {
        pools = await localQuizBank.getAdaptivePools(
          examType: examType,
          section: section,
          perBucket: perBucket,
        );
      }
    }

    return pools;
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
