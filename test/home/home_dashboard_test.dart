import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalasag/home/home_dashboard.dart';
import 'package:kalasag/home/home_insight.dart';
import 'package:kalasag/models.dart';
import 'package:kalasag/theme.dart';

void main() {
  testWidgets('renders approved hierarchy with real brand and mascot assets', (
    tester,
  ) async {
    await pumpDashboard(tester);

    expect(find.byKey(const Key('home-brand-logo')), findsOneWidget);
    expect(find.byKey(const Key('home-mascot-happy')), findsOneWidget);
    expect(find.text('Hazard Status'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Are You Ready?'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Are You Ready?'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Hourly Weather Pulse'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Hourly Weather Pulse'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Official Advisory'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Official Advisory'), findsOneWidget);
    expect(find.text('Weather map'), findsNothing);
    expect(find.text('Emergency'), findsNothing);
  });

  testWidgets('supports dark theme without decorative gradients', (
    tester,
  ) async {
    await pumpDashboard(tester, dark: true);

    expect(tester.takeException(), isNull);
    final decorated = tester.widgetList<DecoratedBox>(
      find.byType(DecoratedBox),
    );
    expect(
      decorated.where(
        (widget) =>
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).gradient != null,
      ),
      isEmpty,
    );
  });

  testWidgets('fits narrow large-text layout without overflow', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpDashboard(tester, textScale: 1.6);
    expect(
      find.bySemanticsLabel(RegExp('Refresh weather and advisories')),
      findsOneWidget,
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1600));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

Future<void> pumpDashboard(
  WidgetTester tester, {
  bool dark = false,
  double textScale = 1,
}) => tester.pumpWidget(
  MaterialApp(
    theme: KalasagTheme.light(),
    darkTheme: KalasagTheme.dark(),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: HomeDashboard(
          model: fixture(),
          isRefreshing: false,
          onRefresh: () async {},
          onOpenAdvisory: () {},
        ),
      ),
    ),
  ),
);

HomePresentation fixture() => HomePresentation(
  mascotMood: HomeMascotMood.happy,
  briefingTitle: 'Your daily readiness check',
  briefingBody:
      'Keep your go-bag and family plan ready. Continue monitoring official updates.',
  hazards: const [
    HomeHazardItem(
      label: 'Official alerts',
      value: 'Monitoring official updates',
      detail: 'No verified current advisory matched to this location',
      tone: HomeHazardTone.neutral,
    ),
    HomeHazardItem(
      label: 'Estimated heat index',
      value: 'Caution',
      detail: '31.5 \u00b0C',
      tone: HomeHazardTone.caution,
      isEstimated: true,
    ),
  ],
  advisory: HomeAdvisorySummary(
    alert: AlertItem(
      id: 'fixture',
      title: 'Yellow Rainfall Advisory',
      description: 'Fixture',
      publishedAt: DateTime.utc(2026, 11, 7, 1),
      severity: 'Medium',
      source: 'PAGASA',
      category: 'rain',
      verificationStatus: 'official',
    ),
    title: 'Yellow Rainfall Advisory',
    source: 'PAGASA',
    severity: 'Medium',
    languageLabel: 'English',
    updatedAt: DateTime.utc(2026, 11, 7, 1),
    isStale: false,
    isDemo: false,
    isLocal: true,
  ),
  readiness: const HomeReadinessSummary(
    goBagPercent: 75,
    completedKitItems: 6,
    totalKitItems: 8,
    familyPlanReady: true,
    emergencyContactCount: 3,
  ),
  weatherUpdated: DateTime.utc(2026, 11, 7, 2),
  alertsUpdated: DateTime.utc(2026, 11, 7, 2),
  weatherIsStale: false,
  monitoringOfficialUpdates: true,
  locationLabel: 'Quezon City, Metro Manila',
  currentTemperatureCelsius: 31.5,
  currentCondition: 'Partly cloudy',
  hourlyPulse: [
    HomeHourlyPoint(
      time: DateTime.utc(2026, 11, 7, 9),
      temperatureCelsius: 31,
      rainProbability: 10,
      weatherCode: 1,
    ),
    HomeHourlyPoint(
      time: DateTime.utc(2026, 11, 7, 10),
      temperatureCelsius: 32,
      rainProbability: 40,
      weatherCode: 61,
    ),
  ],
);
