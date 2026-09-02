import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';
import '../constants/api_endpoints.dart';
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
      final snap = await _db
          .doc(FirestorePaths.contentCatalog)
          .get();
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
  }) async {
    if (mockTestId != null) {
      return _getMockTestQuestions(mockTestId, examType);
    }

    if (section == null) {
      return _getByExam(examType, amount);
    }

    return _getBySection(examType, section, amount);
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
    int amount,
  ) async {
    final snap = await _db
        .collection(FirestorePaths.quizQuestions)
        .where('examType', isEqualTo: examType.name)
        .where('section', isEqualTo: section.id)
        .limit(amount.clamp(1, 50))
        .get();

    final questions = snap.docs.map(_mapDoc).toList()..shuffle();
    return questions
        .take(amount)
        .map((q) => q.copyWith(examType: examType.name))
        .toList();
  }

  Future<List<QuizQuestion>> _getByExam(ExamType examType, int amount) async {
    final snap = await _db
        .collection(FirestorePaths.quizQuestions)
        .where('examType', isEqualTo: examType.name)
        .limit(amount.clamp(1, 50))
        .get();

    final questions = snap.docs.map(_mapDoc).toList()..shuffle();
    return questions
        .take(amount)
        .map((q) => q.copyWith(examType: examType.name))
        .toList();
  }

  Future<List<QuizQuestion>> _fetchByIds(List<String> ids) async {
    final results = <QuizQuestion>[];
    // Firestore whereIn supports up to 30 ids per query.
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
      difficulty: d['difficulty'] as String? ?? 'medium',
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
