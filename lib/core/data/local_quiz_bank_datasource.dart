import 'dart:convert';

import 'package:flutter/services.dart';

import '../constants/app_constants.dart';
import '../constants/question_difficulty.dart';
import '../models/exam_section.dart';
import '../models/quiz_question.dart';

/// Loads curated questions from [assets/data/quiz_bank.json].
///
/// Used when Firestore is empty or still has stale items without passage/task
/// context (common until the user re-seeds).
class LocalQuizBankDataSource {
  LocalQuizBankDataSource();

  static const _assetPath = 'assets/data/quiz_bank.json';

  Map<String, dynamic>? _cache;

  Future<Map<String, dynamic>> _bank() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    _cache = jsonDecode(raw) as Map<String, dynamic>;
    return _cache!;
  }

  Future<List<QuizQuestion>> getQuestions({
    required ExamType examType,
    ExamSection? section,
    int amount = 10,
    String? difficulty,
  }) async {
    final bank = await _bank();
    final examKey = examType.name;
    final examData = bank[examKey];
    if (examData is! Map<String, dynamic>) return const [];

    final sections = section != null
        ? [section]
        : ExamSection.forExam(examType);

    final results = <QuizQuestion>[];
    for (final s in sections) {
      final raw = examData[s.id];
      results.addAll(_flattenSection(raw, examType: examType, section: s));
    }

    var filtered = results;
    if (difficulty != null) {
      final want = QuestionDifficulty.normalize(difficulty);
      filtered = results
          .where((q) => QuestionDifficulty.normalize(q.difficulty) == want)
          .toList();
      if (filtered.isEmpty) filtered = results;
    }

    filtered.shuffle();
    return filtered.take(amount.clamp(1, filtered.length)).toList();
  }

  Future<Map<String, List<QuizQuestion>>> getAdaptivePools({
    required ExamType examType,
    required ExamSection section,
    int perBucket = 12,
  }) async {
    final all = await getQuestions(
      examType: examType,
      section: section,
      amount: 50,
    );

    final pools = <String, List<QuizQuestion>>{
      QuestionDifficulty.easy: [],
      QuestionDifficulty.medium: [],
      QuestionDifficulty.hard: [],
    };

    for (final q in all) {
      final key = QuestionDifficulty.normalize(q.difficulty);
      pools[key] = [...pools[key]!, q];
    }

    for (final diff in QuestionDifficulty.all) {
      final list = pools[diff] ?? [];
      list.shuffle();
      pools[diff] = list.take(perBucket).toList();
    }
    return pools;
  }

  List<QuizQuestion> _flattenSection(
    dynamic sectionData, {
    required ExamType examType,
    required ExamSection section,
  }) {
    if (sectionData is! List) return const [];

    final out = <QuizQuestion>[];
    for (final item in sectionData) {
      if (item is! Map<String, dynamic>) continue;

      if (item['questions'] is List) {
        final setId = item['id']?.toString() ?? '';
        final title = item['title']?.toString();
        final passage = item['passage']?.toString();
        final transcript = item['transcript']?.toString();
        final contextBody = passage ?? transcript;
        final contextType = passage != null
            ? QuestionContextType.passage
            : (transcript != null
                ? QuestionContextType.transcript
                : QuestionContextType.none);

        for (final rawQ in item['questions'] as List) {
          if (rawQ is! Map<String, dynamic>) continue;
          final q = _mapQuestion(
            rawQ,
            examType: examType,
            section: section,
            contextType: contextType,
            contextTitle: title,
            contextBody: contextBody,
            contextSetId: setId.isEmpty ? null : setId,
          );
          if (q != null) out.add(q);
        }
      } else {
        final q = _mapQuestion(
          item,
          examType: examType,
          section: section,
        );
        if (q != null) out.add(q);
      }
    }
    return out;
  }

  QuizQuestion? _mapQuestion(
    Map<String, dynamic> raw, {
    required ExamType examType,
    required ExamSection section,
    QuestionContextType contextType = QuestionContextType.none,
    String? contextTitle,
    String? contextBody,
    String? contextSetId,
  }) {
    final id = raw['id']?.toString();
    final question = raw['question']?.toString();
    if (id == null || question == null) return null;

    final options = (raw['options'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    if (options.isEmpty) return null;

    final correctIndex = (raw['correctIndex'] as num?)?.toInt() ?? 0;
    final correct =
        options[correctIndex.clamp(0, options.length - 1)];
    final incorrect = options.where((o) => o != correct).toList();

    return QuizQuestion(
      id: id,
      question: question,
      correctAnswer: correct,
      incorrectAnswers: incorrect,
      category: raw['skillArea']?.toString() ?? section.label,
      difficulty: QuestionDifficulty.normalize(
        raw['difficulty']?.toString() ?? 'medium',
      ),
      explanation: raw['explanation']?.toString(),
      examType: examType.name,
      skillArea: raw['skillArea']?.toString(),
      contextType: contextType,
      contextTitle: contextTitle,
      contextBody: contextBody,
      contextSetId: contextSetId,
    );
  }
}
