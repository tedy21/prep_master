import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/firebase/firebase_service.dart';
import '../models/quiz_session_record_model.dart';

abstract class QuizSessionRemoteDataSource {
  Future<void> saveSession(QuizSessionRecordModel session);
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
}
