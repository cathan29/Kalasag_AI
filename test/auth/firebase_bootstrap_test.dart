import 'package:flutter_test/flutter_test.dart';
import 'package:kalasag/auth/firebase_bootstrap.dart';

void main() {
  group('FirebaseBootstrap', () {
    test(
      'reports missing configuration without a configured initializer',
      () async {
        final bootstrap = FirebaseBootstrap();

        expect(
          await bootstrap.initialize(),
          FirebaseBootstrapResult.missingConfiguration,
        );
      },
    );

    test('reports ready after Firebase initialization succeeds', () async {
      var initialized = false;
      final bootstrap = FirebaseBootstrap(
        initializeFirebase: () async {
          initialized = true;
        },
      );

      expect(await bootstrap.initialize(), FirebaseBootstrapResult.ready);
      expect(initialized, isTrue);
    });

    test(
      'maps asynchronous initialization failures to a controlled result',
      () async {
        final bootstrap = FirebaseBootstrap(
          initializeFirebase: () async {
            throw StateError('Firebase is unavailable');
          },
        );

        expect(await bootstrap.initialize(), FirebaseBootstrapResult.failed);
      },
    );

    test(
      'maps synchronous initialization failures to a controlled result',
      () async {
        final bootstrap = FirebaseBootstrap(
          initializeFirebase: () {
            throw StateError('Platform configuration is unavailable');
          },
        );

        expect(await bootstrap.initialize(), FirebaseBootstrapResult.failed);
      },
    );
  });
}
