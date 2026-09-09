import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';
import '../constants/api_endpoints.dart';
import '../constants/question_difficulty.dart';
import '../firebase/firebase_service.dart';
import '../models/exam_section.dart';
import '../models/quiz_question.dart';

/// Fetches curated quiz content from Firestore (primary content source).
class FirestoreQuizDataSource {
  FirestoreQuizDataSource(this.firebase);

  final FirebaseService firebase;

  FirebaseFirestore get _db => firebase.firestore;

  /// Published catalog version — bump when seeding new content.
  Future<int> getContentVersion() async {
    try {
      final snap = await _db.doc(FirestorePaths.contentCatalog).get();
      if (!snap.exists) return 0;
      return snap.data()?['version'] as int? ?? 0;
    } on FirebaseException {
      return 0;
    }
  }

  Future<int> questionCount({
    required ExamType examType,
    required ExamSection section,
  }) async {
    try {
      final snap = await _db
          .collection(FirestorePaths.quizQuestions)
          .where('examType', isEqualTo: examType.name)
          .where('section', isEqualTo: section.id)
          .count()
          .get();
      return snap.count ?? 0;
    } on FirebaseException {
      return 0;
    }
  }

  Future<List<QuizQuestion>> getQuestions({
    required ExamType examType,
    ExamSection? section,
    int amount = 10,
    String? mockTestId,
    String? difficulty,
  }) async {
    if (mockTestId != null) {
      return _getMockTestQuestions(mockTestId, examType);
    }

    if (section == null) {
      return _getByExam(examType, amount, difficulty: difficulty);
    }

    return _getBySection(
      examType,
      section,
      amount,
      difficulty: difficulty,
    );
  }

  /// Prefetch easy/medium/hard pools for within-session adaptive practice.
  ///
  /// Prefer a single section query + client-side grouping so we do not depend
  /// on the examType+section+difficulty composite index (and so thin buckets
  /// like IELTS Listening without "hard" items still start successfully).
  Future<Map<String, List<QuizQuestion>>> getAdaptivePools({
    required ExamType examType,
    required ExamSection section,
    int perBucket = 12,
  }) async {
    final pools = <String, List<QuizQuestion>>{
      QuestionDifficulty.easy: [],
      QuestionDifficulty.medium: [],
      QuestionDifficulty.hard: [],
    };

    void addAll(Iterable<QuizQuestion> questions) {
      final seen = <String>{
        for (final list in pools.values)
          for (final q in list) q.id,
      };
      for (final q in questions) {
        if (seen.contains(q.id)) continue;
        seen.add(q.id);
        final key = QuestionDifficulty.normalize(q.difficulty);
        pools[key] = [...(pools[key] ?? []), q];
      }
    }

    // 1) Section pool (existing examType+section index).
    try {
      final sectionQs = await _getBySection(
        examType,
        section,
        ((perBucket * 3).clamp(12, 50)).toInt(),
      );
      addAll(sectionQs);
    } catch (_) {}

    // Reading/Listening must keep passage/transcript context.
    final needsContext = section == ExamSection.reading ||
        section == ExamSection.listening ||
        section == ExamSection.writing;
    if (needsContext) {
      for (final diff in QuestionDifficulty.all) {
        pools[diff] =
            (pools[diff] ?? []).where((q) => q.hasContext).toList();
      }
    }

    // 2) If a difficulty band is empty, try difficulty-filtered section queries.
    for (final diff in QuestionDifficulty.all) {
      if ((pools[diff] ?? []).isNotEmpty) continue;
      try {
        final bucket = await _getBySection(
          examType,
          section,
          perBucket,
          difficulty: diff,
        );
        addAll(
          needsContext ? bucket.where((q) => q.hasContext) : bucket,
        );
      } catch (_) {}
    }

    // 3) Still thin? Pad from same exam — but only same section's context items
    // for reading/listening (never mix writing/speaking stems without a passage).
    final total = pools.values.fold<int>(0, (n, list) => n + list.length);
    if (total < 3 && !needsContext) {
      try {
        final examQs = await _getByExam(examType, 40);
        addAll(examQs);
      } catch (_) {}
    }

    for (final diff in QuestionDifficulty.all) {
      final list = pools[diff] ?? [];
      list.shuffle();
      pools[diff] = list.take(perBucket.clamp(1, 50)).toList();
    }

    return pools;
  }

  Future<List<QuizQuestion>> _getMockTestQuestions(
    String mockTestId,
    ExamType examType,
  ) async {
    final testSnap =
        await _db.collection(FirestorePaths.mockTests).doc(mockTestId).get();
    if (!testSnap.exists) return [];

    final data = testSnap.data()!;
    final ids = (data['questionIds'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    if (ids.isEmpty) return [];

    final questions = await _fetchByIds(ids);
    questions.sort(
      (a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)),
    );
    return questions
        .map((q) => q.copyWith(examType: examType.name))
        .toList();
  }

  Future<List<QuizQuestion>> _getBySection(
    ExamType examType,
    ExamSection section,
    int amount, {
    String? difficulty,
  }) async {
    Query<Map<String, dynamic>> query = _db
        .collection(FirestorePaths.quizQuestions)
        .where('examType', isEqualTo: examType.name)
        .where('section', isEqualTo: section.id);

    if (difficulty != null) {
      query = query.where(
        'difficulty',
        isEqualTo: QuestionDifficulty.normalize(difficulty),
      );
    }

    final snap = await query.limit(amount.clamp(1, 50)).get();
    final questions = snap.docs.map(_mapDoc).toList();
    // Prefer passage/transcript-backed items for Reading & Listening.
    if (section == ExamSection.reading ||
        section == ExamSection.listening ||
        section == ExamSection.writing) {
      questions.sort((a, b) {
        final ac = a.hasContext ? 0 : 1;
        final bc = b.hasContext ? 0 : 1;
        return ac.compareTo(bc);
      });
      final withContext = questions.where((q) => q.hasContext).toList();
      final pool = withContext.isNotEmpty ? withContext : questions;
      pool.shuffle();
      return pool
          .take(amount)
          .map((q) => q.copyWith(examType: examType.name))
          .toList();
    }

    questions.shuffle();
    return questions
        .take(amount)
        .map((q) => q.copyWith(examType: examType.name))
        .toList();
  }

  Future<List<QuizQuestion>> _getByExam(
    ExamType examType,
    int amount, {
    String? difficulty,
  }) async {
    Query<Map<String, dynamic>> query = _db
        .collection(FirestorePaths.quizQuestions)
        .where('examType', isEqualTo: examType.name);

    if (difficulty != null) {
      query = query.where(
        'difficulty',
        isEqualTo: QuestionDifficulty.normalize(difficulty),
      );
    }

    final snap = await query.limit(amount.clamp(1, 50)).get();
    final questions = snap.docs.map(_mapDoc).toList()..shuffle();
    return questions
        .take(amount)
        .map((q) => q.copyWith(examType: examType.name))
        .toList();
  }

  Future<List<QuizQuestion>> _fetchByIds(List<String> ids) async {
    final results = <QuizQuestion>[];
    for (var i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
      final snap = await _db
          .collection(FirestorePaths.quizQuestions)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(snap.docs.map(_mapDoc));
    }
    return results;
  }

  QuizQuestion _mapDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final options = (d['options'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final correctIndex = d['correctIndex'] as int? ?? 0;
    final correct = options.isNotEmpty
        ? options[correctIndex.clamp(0, options.length - 1)]
        : d['correctAnswer']?.toString() ?? '';
    final incorrect = options.where((o) => o != correct).toList();

    return QuizQuestion(
      id: doc.id,
      question: d['question'] as String? ?? '',
      correctAnswer: correct,
      incorrectAnswers: incorrect,
      category: d['skillArea'] as String? ?? 'General',
      difficulty: QuestionDifficulty.normalize(
        d['difficulty'] as String? ?? 'medium',
      ),
      explanation: d['explanation'] as String?,
      examType: d['examType'] as String?,
      skillArea: d['skillArea'] as String?,
      contextType:
          QuestionContextType.fromString(d['contextType'] as String?),
      contextTitle: d['contextTitle'] as String?,
      contextBody: d['contextBody'] as String?,
      contextSetId: d['contextSetId'] as String?,
    );
  }
}
