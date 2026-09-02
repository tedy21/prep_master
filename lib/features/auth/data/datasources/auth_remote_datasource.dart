import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/firebase/firebase_service.dart';

/// Auth operations backed by Firebase Authentication.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._firebase);

  final FirebaseService _firebase;

  Stream<User?> get authStateChanges => _firebase.auth.authStateChanges();

  User? get currentUser => _firebase.currentUser;

  Future<User> signInAnonymously() async {
    try {
      final cred = await _firebase.auth.signInAnonymously();
      final user = cred.user;
      if (user == null) throw const AuthException('Anonymous sign-in failed');
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Auth error');
    }
  }

  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _firebase.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) throw const AuthException('Sign-in failed');
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Auth error');
    }
  }

  Future<User> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _firebase.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) throw const AuthException('Registration failed');
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Auth error');
    }
  }

  Future<void> signOut() => _firebase.auth.signOut();
}
