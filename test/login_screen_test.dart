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

  testWidgets('social sign-in buttons show coming soon messages', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    final googleButton = find.widgetWithText(OutlinedButton, 'Google');
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pump();
    expect(find.text('Google sign-in is coming soon.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));

    final facebookButton = find.widgetWithText(OutlinedButton, 'Facebook');
    await tester.ensureVisible(facebookButton);
    await tester.pumpAndSettle();
    await tester.tap(facebookButton);
    await tester.pumpAndSettle();
    expect(find.text('Facebook sign-in is coming soon.'), findsOneWidget);
  });
}
