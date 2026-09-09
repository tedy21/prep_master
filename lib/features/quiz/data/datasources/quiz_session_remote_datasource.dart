import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/firebase/firebase_service.dart';
import '../models/quiz_session_record_model.dart';

abstract class QuizSessionRemoteDataSource {
  Future<void> saveSession(QuizSessionRecordModel session);

  Future<List<QuizSessionRecordModel>> getRecentSessions({int limit = 20});
}

class QuizSessionRemoteDataSourceImpl implements QuizSessionRemoteDataSource {
  QuizSessionRemoteDataSourceImpl(this.firebase);

  final FirebaseService firebase;

  @override
  Future<void> saveSession(QuizSessionRecordModel session) async {
    final uid = firebase.uid;
    if (uid == null) throw const AuthException('Not signed in');

    try {
      await firebase.firestore
          .doc(FirestorePaths.userSession(uid, session.id))
          .set({
        ...session.toFirestore(),
        'completedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Firestore error');
    }
  }

  @override
  Future<List<QuizSessionRecordModel>> getRecentSessions({
    int limit = 20,
  }) async {
    final uid = firebase.uid;
    if (uid == null) return const [];

    try {
      final snap = await firebase.firestore
          .collection(FirestorePaths.userSessions(uid))
          .orderBy('completedAt', descending: true)
          .limit(limit)
          .get();

      return snap.docs
          .map((d) => QuizSessionRecordModel.fromFirestore(d.id, d.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Firestore error');
    }
  }
}
