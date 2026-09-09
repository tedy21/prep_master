import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Thin accessors for Firebase SDKs registered in DI.
///
/// Storage is intentionally omitted — Firebase Storage requires the Blaze
/// (pay-as-you-go) plan. Quiz content lives in Firestore on the free Spark tier.
class FirebaseService {
  FirebaseService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance,
        functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final FirebaseFunctions functions;

  User? get currentUser => auth.currentUser;

  String? get uid => currentUser?.uid;

  bool get isSignedIn => currentUser != null;
}
