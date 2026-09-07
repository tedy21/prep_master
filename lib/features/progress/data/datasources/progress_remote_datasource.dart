import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/firebase/firebase_service.dart';
import '../models/user_progress_model.dart';

abstract class ProgressRemoteDataSource {
  Future<UserProgressModel> getUserProgress();
  Future<void> saveUserProgress(UserProgressModel progress);
  Future<UserProgressModel> recordQuizCompletion({
    required int correctCount,
    required int totalCount,
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

      await ref.set({
        'streakDays': updated.streakDays,
        'totalXP': updated.xpPoints,
        'currentLevel': updated.level,
        'sessionsCompleted': updated.sessionsCompleted,
        'accuracyPercent': updated.accuracyPercent,
        'totalQuestions': newTotalQ,
        'correctAnswers': newCorrect,
        'lastPracticeDate': today,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

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
