import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/failure_mapper.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Stream<User?> get authStateChanges => _remote.authStateChanges;

  @override
  User? get currentUser => _remote.currentUser;

  @override
  bool get isAnonymous => _remote.currentUser?.isAnonymous ?? true;

  @override
  String? get displayPhone => _remote.displayPhone;

  @override
  Future<Either<Failure, User>> signInAnonymously() async {
    try {
      return Right(await _remote.signInAnonymously());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      return Right(
        await _remote.signInWithPhone(phone: phone, password: password),
      );
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, User>> registerWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      return Right(
        await _remote.registerWithPhone(phone: phone, password: password),
      );
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _remote.signOut();
      return const Right(null);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
