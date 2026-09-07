import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/failures.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  bool get isAnonymous;
  String? get displayPhone;

  Future<Either<Failure, User>> signInAnonymously();
  Future<Either<Failure, User>> signInWithPhone({
    required String phone,
    required String password,
  });
  Future<Either<Failure, User>> registerWithPhone({
    required String phone,
    required String password,
  });
  Future<Either<Failure, void>> signOut();
}
