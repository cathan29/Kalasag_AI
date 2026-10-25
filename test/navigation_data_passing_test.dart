import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalasag/app_state.dart';
import 'package:kalasag/models.dart';
import 'package:kalasag/screens.dart';
import 'package:kalasag/theme.dart';
import 'package:provider/provider.dart';

void main() {
  late AppState state;

  setUp(() {
    state = AppState();
    state.alerts = [
      AlertItem(
        id: 'navigation-test-alert',
        title: 'Heavy Rainfall Warning for Pangasinan',
        description:
            'Residents in low-lying areas should monitor official updates.',
        publishedAt: DateTime(2026, 9, 15, 19, 30),
        severity: 'High',
        source: 'PAGASA',
        category: 'weather',
        affectedAreas: const ['Pangasinan'],
      ),
    ];
  });

  Widget buildAlertsApp() => ChangeNotifierProvider.value(
    value: state,
    child: MaterialApp(
      theme: KalasagTheme.light(),
      home: const Scaffold(body: AlertsScreen()),
    ),
  );

  testWidgets('passes an AlertItem to details and pops back to alerts', (
    tester,
  ) async {
    await tester.pumpWidget(buildAlertsApp());

    final alertTitle = find.text('Heavy Rainfall Warning for Pangasinan');
    await tester.ensureVisible(alertTitle);
    await tester.tap(alertTitle);
    await tester.pumpAndSettle();

    expect(find.text('Advisory details'), findsOneWidget);
    expect(alertTitle, findsOneWidget);
    expect(find.text('High • PAGASA'), findsOneWidget);
    expect(find.text('Pangasinan'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to alerts'));
    await tester.pumpAndSettle();

    expect(find.text('Alerts'), findsOneWidget);
    expect(alertTitle, findsOneWidget);
  });

  testWidgets('opens notification settings and pops back to alerts', (
    tester,
  ) async {
    await tester.pumpWidget(buildAlertsApp());

    await tester.tap(find.byIcon(Icons.notifications_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Alert notifications'), findsOneWidget);
    expect(find.text('Nearby critical alerts'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to alerts'));
    await tester.pumpAndSettle();

    expect(find.text('Alerts'), findsOneWidget);
  });
}
