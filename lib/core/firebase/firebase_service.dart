import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Thin accessors for Firebase SDKs registered in DI.
///
/// Storage is intentionally omitted — Firebase Storage requires the Blaze
/// (pay-as-you-go) plan. Quiz content lives in Firestore on the free Spark tier.
class FirebaseService {
  FirebaseService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  User? get currentUser => auth.currentUser;

  String? get uid => currentUser?.uid;

  bool get isSignedIn => currentUser != null;
}
