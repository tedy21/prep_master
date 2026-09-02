import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/models/exam_section.dart';
import '../../../../core/models/quiz_question.dart';
import '../models/practice_session_model.dart';

abstract class PracticeLocalDataSource {
  Future<PracticeSessionModel?> getCachedDailyPractice(
    ExamType examType,
    ExamSection section,
  );
  Future<void> cacheDailyPractice(PracticeSessionModel session);

  Future<List<QuizQuestion>?> getCachedQuizQuestions({
    required ExamType examType,
    ExamSection? section,
    String? mockTestId,
  });
  Future<void> cacheQuizQuestions({
    required ExamType examType,
    ExamSection? section,
    String? mockTestId,
    required List<QuizQuestion> questions,
  });
}

class PracticeLocalDataSourceImpl implements PracticeLocalDataSource {
  PracticeLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  static String _sessionKey(ExamType type, ExamSection section) =>
      'daily_practice_${type.name}_${section.id}';

  static String _quizKey(
    ExamType type,
    ExamSection? section,
    String? mockTestId,
  ) =>
      'quiz_cache_${type.name}_${section?.id ?? 'all'}_${mockTestId ?? 'daily'}';

  @override
  Future<PracticeSessionModel?> getCachedDailyPractice(
    ExamType examType,
    ExamSection section,
  ) async {
    try {
      final raw = _prefs.getString(_sessionKey(examType, section));
      if (raw == null) return null;
      return PracticeSessionModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      throw const CacheException();
    }
  }

  @override
  Future<void> cacheDailyPractice(PracticeSessionModel session) async {
    try {
      await _prefs.setString(
        _sessionKey(session.examType, session.section),
        jsonEncode(session.toJson()),
      );
    } catch (_) {
      throw const CacheException();
    }
  }

  @override
  Future<List<QuizQuestion>?> getCachedQuizQuestions({
    required ExamType examType,
    ExamSection? section,
    String? mockTestId,
  }) async {
    try {
      final raw = _prefs.getString(_quizKey(examType, section, mockTestId));
      if (raw == null) return null;
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cacheQuizQuestions({
    required ExamType examType,
    ExamSection? section,
    String? mockTestId,
    required List<QuizQuestion> questions,
  }) async {
    try {
      final encoded = jsonEncode(questions.map((q) => q.toJson()).toList());
      await _prefs.setString(
        _quizKey(examType, section, mockTestId),
        encoded,
      );
    } catch (_) {
      throw const CacheException();
    }
  }
}
