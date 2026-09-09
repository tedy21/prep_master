import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/firebase/firebase_service.dart';
import '../../domain/entities/ai_insight.dart';
import '../../domain/entities/skill_stat.dart';
import '../models/ai_insight_model.dart';
import '../models/user_progress_model.dart';

abstract class ProgressRemoteDataSource {
  Future<UserProgressModel> getUserProgress();
  Future<({UserProgressModel progress, List<SkillStat> skillStats})>
      getProgressSummary();
  Future<AiInsight?> getAiInsights();
  Future<void> saveUserProgress(UserProgressModel progress);
  Future<UserProgressModel> recordQuizCompletion({
    required int correctCount,
    required int totalCount,
    Map<String, ({int correct, int total})>? skillDeltas,
  });
}

class ProgressRemoteDataSourceImpl implements ProgressRemoteDataSource {
  ProgressRemoteDataSourceImpl(this.firebase);

  final FirebaseService firebase;

  @override
  Future<UserProgressModel> getUserProgress() async {
    try {
      final uid = firebase.uid;
      if (uid == null) {
        return const UserProgressModel(
          streakDays: 0,
          xpPoints: 0,
          level: 1,
          sessionsCompleted: 0,
          accuracyPercent: 0,
        );
      }

      final doc = await firebase.firestore
          .doc(FirestorePaths.userProgress(uid))
          .get();

      if (!doc.exists || doc.data() == null) {
        return const UserProgressModel(
          streakDays: 0,
          xpPoints: 0,
          level: 1,
          sessionsCompleted: 0,
          accuracyPercent: 0,
        );
      }

      final d = doc.data()!;
      return UserProgressModel(
        streakDays: d['streakDays'] as int? ?? 0,
        xpPoints: d['totalXP'] as int? ?? d['xpPoints'] as int? ?? 0,
        level: d['currentLevel'] as int? ?? d['level'] as int? ?? 1,
        sessionsCompleted: d['sessionsCompleted'] as int? ?? 0,
        accuracyPercent: _accuracy(d),
      );
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Firestore error');
    }
  }

  @override
  Future<({UserProgressModel progress, List<SkillStat> skillStats})>
      getProgressSummary() async {
    try {
      final uid = firebase.uid;
      if (uid == null) {
        return (
          progress: const UserProgressModel(
            streakDays: 0,
            xpPoints: 0,
            level: 1,
            sessionsCompleted: 0,
            accuracyPercent: 0,
          ),
          skillStats: const <SkillStat>[],
        );
      }

      final doc = await firebase.firestore
          .doc(FirestorePaths.userProgress(uid))
          .get();

      if (!doc.exists || doc.data() == null) {
        return (
          progress: const UserProgressModel(
            streakDays: 0,
            xpPoints: 0,
            level: 1,
            sessionsCompleted: 0,
            accuracyPercent: 0,
          ),
          skillStats: const <SkillStat>[],
        );
      }

      final d = doc.data()!;
      final progress = UserProgressModel(
        streakDays: d['streakDays'] as int? ?? 0,
        xpPoints: d['totalXP'] as int? ?? d['xpPoints'] as int? ?? 0,
        level: d['currentLevel'] as int? ?? d['level'] as int? ?? 1,
        sessionsCompleted: d['sessionsCompleted'] as int? ?? 0,
        accuracyPercent: _accuracy(d),
      );
      return (progress: progress, skillStats: _parseSkillStats(d['skillStats']));
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Firestore error');
    }
  }

  List<SkillStat> _parseSkillStats(dynamic raw) {
    if (raw is! Map) return const [];
    final stats = <SkillStat>[];
    raw.forEach((key, value) {
      if (value is! Map) return;
      final correct = (value['correct'] as num?)?.toInt() ?? 0;
      final total = (value['total'] as num?)?.toInt() ?? 0;
      if (total <= 0) return;
      stats.add(SkillStat(
        skillArea: key.toString(),
        correct: correct,
        total: total,
      ));
    });
    stats.sort((a, b) => a.accuracyPercent.compareTo(b.accuracyPercent));
    return stats;
  }

  @override
  Future<AiInsight?> getAiInsights() async {
    final uid = firebase.uid;
    if (uid == null) return null;

    try {
      final doc = await firebase.firestore
          .doc(FirestorePaths.userAiInsights(uid))
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return AiInsightModel.fromFirestore(doc.data()!);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Firestore error');
    }
  }

  double _accuracy(Map<String, dynamic> d) {
    final total = d['totalQuestions'] as int? ?? 0;
    final correct = d['correctAnswers'] as int? ?? 0;
    if (total <= 0) {
      return (d['accuracyPercent'] as num?)?.toDouble() ?? 0;
    }
    return (correct / total) * 100;
  }

  @override
  Future<void> saveUserProgress(UserProgressModel progress) async {
    final uid = firebase.uid;
    if (uid == null) throw const AuthException('Not signed in');

    try {
      await firebase.firestore.doc(FirestorePaths.userProgress(uid)).set({
        'streakDays': progress.streakDays,
        'totalXP': progress.xpPoints,
        'currentLevel': progress.level,
        'sessionsCompleted': progress.sessionsCompleted,
        'accuracyPercent': progress.accuracyPercent,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Firestore error');
    }
  }

  @override
  Future<UserProgressModel> recordQuizCompletion({
    required int correctCount,
    required int totalCount,
    Map<String, ({int correct, int total})>? skillDeltas,
  }) async {
    final uid = firebase.uid;
    if (uid == null) throw const AuthException('Not signed in');

    try {
      final ref = firebase.firestore.doc(FirestorePaths.userProgress(uid));
      final doc = await ref.get();
      final d = doc.data() ?? {};

      final prevStreak = d['streakDays'] as int? ?? 0;
      final prevXp = d['totalXP'] as int? ?? d['xpPoints'] as int? ?? 0;
      final prevSessions = d['sessionsCompleted'] as int? ?? 0;
      final prevTotalQ = d['totalQuestions'] as int? ?? 0;
      final prevCorrect = d['correctAnswers'] as int? ?? 0;

      final today = _dateKey(DateTime.now());
      final lastDay = d['lastPracticeDate'] as String?;
      final newStreak = _nextStreak(prevStreak, lastDay, today);

      final earnedXp = 20 + correctCount * 10;
      final newXp = prevXp + earnedXp;
      final newLevel = (newXp ~/ 100) + 1;

      final newTotalQ = prevTotalQ + totalCount;
      final newCorrect = prevCorrect + correctCount;
      final accuracy =
          newTotalQ > 0 ? (newCorrect / newTotalQ) * 100 : 0.0;

      final updated = UserProgressModel(
        streakDays: newStreak,
        xpPoints: newXp,
        level: newLevel,
        sessionsCompleted: prevSessions + 1,
        accuracyPercent: accuracy,
      );

      final payload = <String, dynamic>{
        'streakDays': updated.streakDays,
        'totalXP': updated.xpPoints,
        'currentLevel': updated.level,
        'sessionsCompleted': updated.sessionsCompleted,
        'accuracyPercent': updated.accuracyPercent,
        'totalQuestions': newTotalQ,
        'correctAnswers': newCorrect,
        'lastPracticeDate': today,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (skillDeltas != null && skillDeltas.isNotEmpty) {
        final existing = Map<String, dynamic>.from(
          (d['skillStats'] as Map?)?.map(
                (k, v) => MapEntry(k.toString(), v),
              ) ??
              {},
        );
        for (final entry in skillDeltas.entries) {
          final prev = existing[entry.key];
          var prevCorrect = 0;
          var prevTotal = 0;
          if (prev is Map) {
            prevCorrect = (prev['correct'] as num?)?.toInt() ?? 0;
            prevTotal = (prev['total'] as num?)?.toInt() ?? 0;
          }
          existing[entry.key] = {
            'correct': prevCorrect + entry.value.correct,
            'total': prevTotal + entry.value.total,
          };
        }
        payload['skillStats'] = existing;
      }

      await ref.set(payload, SetOptions(merge: true));

      return updated;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Firestore error');
    }
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  int _nextStreak(int prev, String? lastDay, String today) {
    if (lastDay == today) return prev == 0 ? 1 : prev;
    if (lastDay == null) return 1;
    final last = DateTime.parse(lastDay);
    final now = DateTime.parse(today);
    final diff = now.difference(last).inDays;
    if (diff == 1) return prev + 1;
    return 1;
  }
}
