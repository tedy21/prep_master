import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/firebase/firebase_service.dart';
import '../../../../core/utils/phone_auth_mapper.dart';

/// Auth operations backed by Firebase Authentication.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._firebase);

  final FirebaseService _firebase;

  Stream<User?> get authStateChanges => _firebase.auth.authStateChanges();

  User? get currentUser => _firebase.currentUser;

  String? get displayPhone =>
      PhoneAuthMapper.fromAuthEmail(currentUser?.email);

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

  Future<User> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    final email = PhoneAuthMapper.toAuthEmail(phone);
    try {
      final cred = await _firebase.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) throw const AuthException('Sign-in failed');
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e));
    }
  }

  Future<User> registerWithPhone({
    required String phone,
    required String password,
  }) async {
    final email = PhoneAuthMapper.toAuthEmail(phone);
    final credential =
        EmailAuthProvider.credential(email: email, password: password);

    try {
      final existing = _firebase.currentUser;
      final UserCredential cred;

      if (existing != null && existing.isAnonymous) {
        cred = await existing.linkWithCredential(credential);
      } else {
        cred = await _firebase.auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      final user = cred.user;
      if (user == null) throw const AuthException('Registration failed');

      await _savePhoneProfile(user.uid, phone);
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e));
    }
  }

  Future<void> _savePhoneProfile(String uid, String phone) async {
    final normalized = PhoneAuthMapper.normalize(phone);
    final display = PhoneAuthMapper.toDisplayPhone(phone);
    await _firebase.firestore.doc(FirestorePaths.user(uid)).set({
      'phoneNumber': normalized,
      'displayPhone': display,
      'authProvider': 'phone',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _friendlyMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This phone number is already registered. Sign in instead.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect phone number or password.';
      case 'user-not-found':
        return 'No account found for this phone number.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'credential-already-in-use':
        return 'This phone number is linked to another account.';
      default:
        return e.message ?? 'Auth error';
    }
  }

  Future<void> signOut() => _firebase.auth.signOut();
}
