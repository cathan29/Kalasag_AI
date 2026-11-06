import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  bool _isInitialized = false;

  Future<UserCredential> signIn() async {
    if (!_isInitialized) {
      await _googleSignIn.initialize();
      _isInitialized = true;
    }

    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google did not return an ID token.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _firebaseAuth.signInWithCredential(credential);
  }
}
