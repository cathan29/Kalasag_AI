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

  testWidgets('guest account access is always visible and triggers callback', (
    tester,
  ) async {
    var guestUsed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: KalasagTheme.light(),
        home: LoginScreen(
          continueAsGuest: () async {
            guestUsed = true;
          },
          navigateAfterGuestSignIn: false,
        ),
      ),
    );

    final guestButton = find.widgetWithText(
      OutlinedButton,
      'Continue as Guest',
    );
    expect(guestButton, findsOneWidget);
    await tester.ensureVisible(guestButton);
    await tester.tap(guestButton);
    await tester.pump();
    expect(guestUsed, isTrue);
  });

  testWidgets(
    'toggling create account on phone screen does not overflow and keeps guest access',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(app());

      final guestButton = find.widgetWithText(
        OutlinedButton,
        'Continue as Guest',
      );
      expect(guestButton, findsOneWidget);

      final createToggle = find.text('New here? Create an account');
      await tester.ensureVisible(createToggle);
      await tester.tap(createToggle);
      await tester.pumpAndSettle();

      expect(find.text('Create your account'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(
        find.widgetWithText(OutlinedButton, 'Continue as Guest'),
        findsOneWidget,
      );

      // Form submission validation triggers without layout overflow
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);

      // Switch back
      final signinToggle = find.text('Already have an account? Sign in');
      await tester.ensureVisible(signinToggle);
      await tester.tap(signinToggle);
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
    },
  );

  testWidgets(
    'login and signup maintain identical header, mascot, and panel geometry',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(app());

      // 1. Check Login geometry
      final mascotFinder = find.byType(Image);
      expect(mascotFinder, findsOneWidget);
      final loginMascotRect = tester.getRect(mascotFinder);

      final formFinder = find.byType(Form);
      final loginFormRect = tester.getRect(formFinder);

      // Header copy is present
      expect(find.text('Be prepared.'), findsOneWidget);
      expect(find.text('Stay safe.'), findsOneWidget);
      expect(
        find.text('Your trusted disaster readiness companion.'),
        findsOneWidget,
      );

      // 2. Switch to Sign Up
      final createToggle = find.text('New here? Create an account');
      await tester.tap(createToggle);
      await tester.pumpAndSettle();

      // 3. Verify Sign Up geometry is exactly identical
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Be prepared.'), findsOneWidget);
      expect(find.text('Stay safe.'), findsOneWidget);
      expect(
        find.text('Your trusted disaster readiness companion.'),
        findsOneWidget,
      );

      final signUpMascotRect = tester.getRect(mascotFinder);
      expect(signUpMascotRect.top, equals(loginMascotRect.top));
      expect(signUpMascotRect.left, equals(loginMascotRect.left));
      expect(signUpMascotRect.width, equals(loginMascotRect.width));
      expect(signUpMascotRect.height, equals(loginMascotRect.height));

      final signUpFormRect = tester.getRect(formFinder);
      expect(signUpFormRect.top, equals(loginFormRect.top));
      expect(signUpFormRect.left, equals(loginFormRect.left));
      expect(signUpFormRect.width, equals(loginFormRect.width));
    },
  );
}
