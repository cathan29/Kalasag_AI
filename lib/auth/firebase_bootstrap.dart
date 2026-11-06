import 'package:firebase_core/firebase_core.dart';

enum FirebaseBootstrapResult { ready, missingConfiguration, failed }

/// Keeps unavailable Firebase setup from blocking local emergency access.
///
/// Supply an initializer that awaits Firebase initialization with the real
/// platform options once configuration has been generated. Leave it absent
/// while the app is unconfigured; no native Firebase calls are made in that case.
class FirebaseBootstrap {
  FirebaseBootstrap({Future<void> Function()? initializeFirebase})
    : _initializeFirebase = initializeFirebase;

  final Future<void> Function()? _initializeFirebase;

  factory FirebaseBootstrap.native() {
    return FirebaseBootstrap(initializeFirebase: Firebase.initializeApp);
  }

  Future<FirebaseBootstrapResult> initialize() async {
    final initializeFirebase = _initializeFirebase;
    if (initializeFirebase == null) {
      return FirebaseBootstrapResult.missingConfiguration;
    }

    try {
      await initializeFirebase();
      return FirebaseBootstrapResult.ready;
    } catch (_) {
      return FirebaseBootstrapResult.failed;
    }
  }
}
