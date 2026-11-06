import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalasag/login_screen.dart';
import 'package:kalasag/theme.dart';

void main() {
  Widget app() =>
      MaterialApp(theme: KalasagTheme.light(), home: const LoginScreen());

  testWidgets('login form shows validation messages', (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });

  testWidgets('Google sign-in uses the provided authentication callback', (
    tester,
  ) async {
    var signedIn = false;
    await tester.pumpWidget(app());

    final googleButton = find.widgetWithText(OutlinedButton, 'Google');
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pump();
    expect(
      find.text(
        'Google sign-in is not configured yet. Add the Firebase app configuration and try again.',
      ),
      findsOneWidget,
    );

    final configuredApp = MaterialApp(
      theme: KalasagTheme.light(),
      home: LoginScreen(
        googleSignIn: () async {
          signedIn = true;
        },
        navigateAfterGoogleSignIn: false,
      ),
    );
    await tester.pumpWidget(configuredApp);
    final configuredGoogle = find.widgetWithText(OutlinedButton, 'Google');
    await tester.ensureVisible(configuredGoogle);
    await tester.tap(configuredGoogle);
    await tester.pumpAndSettle();
    expect(signedIn, isTrue);

    final facebookButton = find.widgetWithText(
      OutlinedButton,
      'Facebook · Coming soon',
    );
    await tester.ensureVisible(facebookButton);
    expect(tester.widget<OutlinedButton>(facebookButton).onPressed, isNull);
  });

  testWidgets('signup validates confirmation and sends verification', (
    tester,
  ) async {
    var createdEmail = '';
    await tester.pumpWidget(
      MaterialApp(
        theme: KalasagTheme.light(),
        home: LoginScreen(
          createAccount: (email, password) async {
            createdEmail = email;
          },
          navigateAfterGoogleSignIn: false,
        ),
      ),
    );

    final createToggle = find.text('New here? Create an account');
    await tester.ensureVisible(createToggle);
    await tester.tap(createToggle);
    await tester.pump();
    final passwordFields = find.byType(TextFormField);
    await tester.enterText(passwordFields.at(0), 'prepared@example.com');
    await tester.enterText(passwordFields.at(1), 'prepared123');
    await tester.enterText(passwordFields.at(2), 'prepared123');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(createdEmail, 'prepared@example.com');
    expect(
      find.text(
        'Account created. Check your email and tap the verification link.',
      ),
      findsOneWidget,
    );
  });
}
