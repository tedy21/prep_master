import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/firebase/firebase_service.dart';
import '../models/user_progress_model.dart';

abstract class ProgressRemoteDataSource {
  Future<UserProgressModel> getUserProgress();
  Future<void> saveUserProgress(UserProgressModel progress);
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
}
