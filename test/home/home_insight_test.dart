import 'package:flutter_test/flutter_test.dart';
import 'package:kalasag/home/home_insight.dart';
import 'package:kalasag/models.dart';

void main() {
  group('heat index', () {
    test('returns null when temperature or humidity is unavailable', () {
      expect(
        calculateHeatIndexCelsius(
          temperatureCelsius: null,
          relativeHumidity: 70,
        ),
        isNull,
      );
      expect(
        calculateHeatIndexCelsius(
          temperatureCelsius: 32,
          relativeHumidity: null,
        ),
        isNull,
      );
      for (final humidity in [-1.0, 101.0, double.nan, double.infinity]) {
        expect(
          calculateHeatIndexCelsius(
            temperatureCelsius: 32,
            relativeHumidity: humidity,
          ),
          isNull,
        );
      }
      expect(
        calculateHeatIndexCelsius(
          temperatureCelsius: double.nan,
          relativeHumidity: 70,
        ),
        isNull,
      );
    });
    test('calculates representative tropical heat index values', () {
      expect(
        calculateHeatIndexCelsius(temperatureCelsius: 30, relativeHumidity: 70),
        closeTo(35.038, 0.001),
      );
      expect(
        calculateHeatIndexCelsius(temperatureCelsius: 32, relativeHumidity: 80),
        closeTo(44.369, 0.001),
      );
      expect(
        calculateHeatIndexCelsius(temperatureCelsius: 35, relativeHumidity: 70),
        closeTo(50.341, 0.001),
      );
      expect(
        calculateHeatIndexCelsius(temperatureCelsius: 20, relativeHumidity: 50),
        closeTo(19.681, 0.001),
      );
      expect(
        calculateHeatIndexCelsius(temperatureCelsius: 30, relativeHumidity: 10),
        closeTo(27.861, 0.001),
      );
      expect(
        calculateHeatIndexCelsius(temperatureCelsius: 28, relativeHumidity: 90),
        closeTo(34.003, 0.001),
      );
    });
    test(
      'maps 27–32 C to Caution, 33–41 C to Extreme Caution, 42–51 C to Danger, and 52+ C to Extreme Danger',
      () {
        for (final value in [27.0, 32.0, 32.99]) {
          expect(HomeHazardItem.heatIndex(value).value, 'Caution');
          expect(HomeHazardItem.heatIndex(value).tone, HomeHazardTone.caution);
        }
        for (final value in [33.0, 41.0, 41.99]) {
          expect(HomeHazardItem.heatIndex(value).value, 'Extreme Caution');
          expect(HomeHazardItem.heatIndex(value).tone, HomeHazardTone.warning);
        }
        for (final value in [42.0, 51.0, 51.99]) {
          expect(HomeHazardItem.heatIndex(value).value, 'Danger');
          expect(HomeHazardItem.heatIndex(value).tone, HomeHazardTone.danger);
        }
        expect(HomeHazardItem.heatIndex(52).value, 'Extreme Danger');
        expect(HomeHazardItem.heatIndex(60).tone, HomeHazardTone.danger);
        expect(HomeHazardItem.heatIndex(26.99).tone, HomeHazardTone.neutral);
        expect(HomeHazardItem.heatIndex(null).value, 'Unavailable');
        expect(HomeHazardItem.heatIndex(35).label, 'Estimated heat index');
        expect(HomeHazardItem.heatIndex(35).isEstimated, isTrue);
      },
    );
  });

  group('live alert safety', () {
    test('official local active unexpired alert outranks derived weather', () {
      final result = presentation(
        alerts: [
          alert({
            'officialLevel': 'TCWS No. 2',
            'category': 'typhoon',
            'severity': 'Low',
          }),
        ],
        current: {'temperature_2m': 38, 'relative_humidity_2m': 85},
      );
      expect(result.hazards.first.isOfficial, isTrue);
      expect(result.hazards.first.value, 'Signal No. 2');
      expect(result.briefingTitle, 'Official advisory for your area');
      expect(result.briefingBody, contains('Signal No. 2'));
      expect(result.advisory?.alert.id, 'official');
      expect(result.monitoringOfficialUpdates, isFalse);
    });

    final excluded = <String, Map<String, dynamic>>{
      'demo': {'verificationStatus': 'demo'},
      'ended': {'lifecycle': 'ended'},
      'cancelled': {'lifecycle': 'cancelled'},
      'expired': {'expiresAt': instant.toIso8601String()},
      'future-effective': {
        'effectiveAt': instant
            .add(const Duration(minutes: 1))
            .toIso8601String(),
      },
      'future-issued': {
        'issuedAt': instant.add(const Duration(minutes: 1)).toIso8601String(),
      },
      'stale': {
        'issuedAt': instant
            .subtract(const Duration(hours: 25))
            .toIso8601String(),
      },
      'non-local': {
        'affectedAreas': ['Davao City'],
      },
      'missing applicability': {'affectedAreas': []},
      'cached item': {'isCached': true},
    };
    for (final entry in excluded.entries) {
      test('${entry.key} alerts do not drive live hazards or mascot mood', () {
        final result = presentation(
          alerts: [
            alert({...entry.value, 'officialLevel': 'TCWS No. 5'}),
          ],
        );
        expect(result.hazards.where((item) => item.isOfficial), isEmpty);
        expect(result.mascotMood, HomeMascotMood.happy);
        expect(result.monitoringOfficialUpdates, isTrue);
        expect(result.hazards.first.value, 'Monitoring official updates');
      });
    }

    test('feed-wide demo and cache flags prevent live hazard decisions', () {
      final official = alert({'officialLevel': 'TCWS No. 5'});
      for (final result in [
        presentation(alerts: [official], demoMode: true),
        presentation(alerts: [official], fromCache: true),
      ]) {
        expect(result.hazards.where((item) => item.isOfficial), isEmpty);
        expect(result.mascotMood, HomeMascotMood.happy);
      }
      expect(
        presentation(alerts: [official], demoMode: true).advisory?.isDemo,
        isTrue,
      );
    });

    test(
      'officialLevel is used only after local applicability is established',
      () {
        final result = presentation(
          alerts: [
            alert({
              'affectedAreas': ['Davao City'],
              'officialLevel': 'TCWS No. 5',
            }),
          ],
        );
        expect(result.briefingBody, isNot(contains('Signal')));
        expect(result.hazards.any((item) => item.value.contains('5')), isFalse);
      },
    );

    test(
      'free-form title and description are never scanned for highest signal or color',
      () {
        final result = presentation(
          alerts: [
            alert({
              'title': 'Signal No. 5 in another area',
              'description': 'RED rainfall elsewhere',
              'officialLevel': '',
            }),
          ],
        );
        expect(result.hazards.first.value, 'Official advisory');
        expect(result.hazards.first.tone, HomeHazardTone.caution);
        expect(result.mascotMood, HomeMascotMood.happy);
      },
    );

    test(
      'structured official levels parse conservatively and case-insensitively',
      () {
        for (final level in [
          'tcws no. 3',
          'SIGNAL #3',
          'Tropical Cyclone Wind Signal No. 3',
        ]) {
          expect(
            presentation(
              alerts: [
                alert({'officialLevel': level}),
              ],
            ).hazards.first.value,
            'Signal No. 3',
          );
        }
        for (final level in [
          'Signal No. 9',
          'Signal No. 2 and Signal No. 5',
          'Red in Davao, Yellow in Manila',
        ]) {
          expect(
            presentation(
              alerts: [
                alert({'officialLevel': level}),
              ],
            ).hazards.first.value,
            'Official advisory',
          );
        }
        for (final pair in [
          ('yellow', HomeHazardTone.caution),
          ('ORANGE rainfall warning', HomeHazardTone.warning),
          ('Red', HomeHazardTone.danger),
        ]) {
          final result = presentation(
            alerts: [
              alert({'category': 'rainfall', 'officialLevel': pair.$1}),
            ],
          );
          expect(result.hazards.first.tone, pair.$2);
          expect(
            result.mascotMood,
            pair.$2 == HomeHazardTone.danger
                ? HomeMascotMood.storm
                : HomeMascotMood.rain,
          );
        }
      },
    );

    test(
      'verified official items precede supplementary items then severity and latest issue',
      () {
        final result = presentation(
          alerts: [
            alert({
              'id': 'supplementary',
              'severity': 'Critical',
              'verificationStatus': 'supplementary',
            }),
            alert({'id': 'low', 'severity': 'Low'}),
            alert({'id': 'medium', 'severity': 'Medium'}),
            alert({'id': 'high', 'severity': 'High'}),
            alert({
              'id': 'critical-old',
              'severity': 'Critical',
              'issuedAt': instant
                  .subtract(const Duration(hours: 2))
                  .toIso8601String(),
            }),
            alert({'id': 'critical-new', 'severity': 'Critical'}),
          ],
        );
        expect(result.advisory?.alert.id, 'critical-new');
        for (final severity in ['Critical', 'High', 'Medium', 'Low']) {
          final lower = [
            'Critical',
            'High',
            'Medium',
            'Low',
          ].skipWhile((item) => item != severity);
          expect(
            presentation(
              alerts: lower
                  .toList()
                  .reversed
                  .map((item) => alert({'id': item, 'severity': item}))
                  .toList(),
            ).advisory?.alert.id,
            severity,
          );
        }
      },
    );

    test('latest updated or issued time controls tie breaks and freshness', () {
      final result = presentation(
        alerts: [
          alert({
            'id': 'updated',
            'issuedAt': instant
                .subtract(const Duration(days: 2))
                .toIso8601String(),
            'updatedAt': instant.toIso8601String(),
          }),
          alert({'id': 'issued'}),
        ],
      );
      expect(result.advisory?.alert.id, 'updated');
      expect(result.advisory?.updatedAt, instant);
      expect(
        presentation(
          alerts: [
            alert({
              'updatedAt': instant
                  .subtract(const Duration(days: 2))
                  .toIso8601String(),
            }),
          ],
        ).monitoringOfficialUpdates,
        isFalse,
      );
      expect(
        presentation(
          alerts: [
            alert({
              'issuedAt': instant
                  .subtract(const Duration(hours: 24))
                  .toIso8601String(),
            }),
          ],
        ).monitoringOfficialUpdates,
        isFalse,
      );
      expect(
        presentation(
          alerts: [
            alert({
              'issuedAt': instant
                  .subtract(const Duration(days: 2))
                  .toIso8601String(),
              'expiresAt': instant
                  .add(const Duration(hours: 1))
                  .toIso8601String(),
            }),
          ],
        ).monitoringOfficialUpdates,
        isFalse,
      );
    });

    test(
      'matches normalized administrative area without substring false positives',
      () {
        expect(
          presentation(
            alerts: [
              alert({
                'affectedAreas': ['  qUeZoN-city  '],
              }),
            ],
          ).monitoringOfficialUpdates,
          isFalse,
        );
        expect(
          presentation(
            alerts: [
              alert({
                'affectedAreas': ['Metro Manila'],
              }),
            ],
          ).monitoringOfficialUpdates,
          isFalse,
        );
        expect(
          presentation(
            alerts: [
              alert({
                'affectedAreas': ['Manila'],
              }),
            ],
          ).monitoringOfficialUpdates,
          isTrue,
        );
        expect(
          presentation(
            alerts: [
              alert({
                'affectedAreas': ['Quezon'],
              }),
            ],
          ).monitoringOfficialUpdates,
          isTrue,
        );
      },
    );

    test(
      'coordinates are a fallback only for empty affected areas and clamp radius to 10–200 km',
      () {
        const origin = GeoPoint(0, 0, 'Test place');
        AlertItem at(double latitude) => alert({
          'affectedAreas': [],
          'coordinates': GeoPoint(latitude, 0).toJson(),
        });
        expect(
          presentation(
            alerts: [at(0.08)],
            location: origin,
            radius: 1,
          ).monitoringOfficialUpdates,
          isFalse,
        );
        expect(
          presentation(
            alerts: [at(0.1)],
            location: origin,
            radius: 1,
          ).monitoringOfficialUpdates,
          isTrue,
        );
        expect(
          presentation(
            alerts: [at(1.7)],
            location: origin,
            radius: 1000,
          ).monitoringOfficialUpdates,
          isFalse,
        );
        expect(
          presentation(
            alerts: [at(1.9)],
            location: origin,
            radius: 1000,
          ).monitoringOfficialUpdates,
          isTrue,
        );
        expect(
          presentation(
            alerts: [at(0)],
            location: origin,
            radius: 10,
          ).monitoringOfficialUpdates,
          isFalse,
        );
        expect(
          presentation(
            alerts: [
              alert({
                'coordinates': origin.toJson(),
                'affectedAreas': ['Davao City'],
              }),
            ],
            location: origin,
          ).monitoringOfficialUpdates,
          isTrue,
        );
      },
    );

    test('missing usable location yields Monitoring official updates', () {
      final result = presentation(
        alerts: [alert()],
        location: const GeoPoint(double.nan, double.nan, 'Current location'),
      );
      expect(result.hazards.first.value, 'Monitoring official updates');
      expect(result.hazards.first.tone, HomeHazardTone.neutral);
    });

    test('cached stale alert remains an advisory summary with stale state', () {
      final result = presentation(
        alerts: [
          alert({
            'issuedAt': instant
                .subtract(const Duration(days: 2))
                .toIso8601String(),
          }),
        ],
        fromCache: true,
      );
      expect(result.advisory?.isStale, isTrue);
      expect(result.advisory?.alert.id, 'official');
      expect(result.monitoringOfficialUpdates, isTrue);
    });

    test(
      'non-English alert yields English Official advisory available summary without original title',
      () {
        final result = presentation(
          alerts: [
            alert({
              'language': 'fil',
              'title': 'Malakas na ulan',
              'description': 'Mag-ingat',
            }),
          ],
        );
        expect(result.advisory?.title, 'Official advisory available');
        expect(result.advisory?.languageLabel, 'Filipino');
        expect(result.briefingBody, isNot(contains('Malakas')));
        expect(result.briefingBody, isNot(contains('Mag-ingat')));
      },
    );

    test(
      'live local advisory is selected before a stale or non-local higher severity item',
      () {
        final result = presentation(
          alerts: [
            alert({
              'id': 'non-local',
              'severity': 'Critical',
              'affectedAreas': ['Davao City'],
            }),
            alert({
              'id': 'stale',
              'severity': 'Critical',
              'issuedAt': instant
                  .subtract(const Duration(days: 2))
                  .toIso8601String(),
            }),
            alert({'id': 'local', 'severity': 'Low'}),
          ],
        );
        expect(result.advisory?.alert.id, 'local');
      },
    );

    test('supplementary levels cannot masquerade as official hazards', () {
      final result = presentation(
        alerts: [
          alert({
            'verificationStatus': 'supplementary',
            'officialLevel': 'TCWS No. 5',
          }),
        ],
      );
      expect(result.hazards.where((item) => item.isOfficial), isEmpty);
      expect(result.hazards.first.value, 'Monitoring official updates');
    });
  });

  group('readiness and mascot', () {
    test(
      'go-bag percentage uses completed over total and contacts use supplied count',
      () {
        final result = presentation(
          kit: [
            KitItem('a', 'Water', done: true),
            KitItem('b', 'Food'),
            KitItem('c', 'Radio'),
          ],
          contacts: 7,
        );
        expect(result.readiness.goBagPercent, 33);
        expect(result.readiness.completedKitItems, 1);
        expect(result.readiness.totalKitItems, 3);
        expect(result.readiness.emergencyContactCount, 7);
        expect(presentation().readiness.goBagPercent, isNull);
      },
    );

    test(
      'family plan is ready only when all three existing fields are non-empty',
      () {
        const complete = {
          'meetingPlace': 'School',
          'outOfTownContact': 'Ana',
          'medicalNotes': 'None',
        };
        expect(
          presentation(familyPlan: complete).readiness.familyPlanReady,
          isTrue,
        );
        for (final key in complete.keys) {
          expect(
            presentation(
              familyPlan: {...complete, key: '  '},
            ).readiness.familyPlanReady,
            isFalse,
          );
          expect(
            presentation(
              familyPlan: {...complete}..remove(key),
            ).readiness.familyPlanReady,
            isFalse,
          );
        }
        expect(
          presentation(
            familyPlan: {'extra': 'Filled'},
          ).readiness.familyPlanReady,
          isFalse,
        );
      },
    );

    test('mood priority is severe local alert then rain then happy', () {
      expect(
        presentation(
          alerts: [
            alert({'severity': 'High'}),
          ],
          current: {'weather_code': 61},
        ).mascotMood,
        HomeMascotMood.storm,
      );
      expect(
        presentation(
          alerts: [
            alert({'severity': 'Critical'}),
          ],
        ).mascotMood,
        HomeMascotMood.storm,
      );
      expect(
        presentation(current: {'weather_code': 61}).mascotMood,
        HomeMascotMood.rain,
      );
      expect(
        presentation(current: {'weather_code': 95}).mascotMood,
        HomeMascotMood.storm,
      );
      expect(
        presentation(current: {'precipitation': 0.2}).mascotMood,
        HomeMascotMood.rain,
      );
      expect(presentation().mascotMood, HomeMascotMood.happy);
    });

    test(
      'stale or unavailable forecast cannot make current weather hazard claims',
      () {
        final result = presentation(
          current: {
            'weather_code': 95,
            'temperature_2m': 38,
            'relative_humidity_2m': 90,
          },
          weatherUpdated: instant.subtract(const Duration(hours: 25)),
        );
        expect(result.weatherIsStale, isTrue);
        expect(result.mascotMood, HomeMascotMood.happy);
        expect(result.hazards.last.value, 'Unavailable');
        expect(result.briefingBody, contains('Refresh'));
      },
    );

    test(
      'presentation hazards are immutable and timestamps are supplied state',
      () {
        final result = presentation();
        expect(() => result.hazards.clear(), throwsUnsupportedError);
        expect(result.weatherUpdated, instant);
        expect(result.alertsUpdated, instant);
      },
    );

    test('presentation exposes location current weather and hourly pulse', () {
      final result = presentation(
        current: const {'temperature_2m': 31.5},
        hourly: {
          'time': [
            instant.toIso8601String(),
            instant.add(const Duration(hours: 1)).toIso8601String(),
          ],
          'temperature_2m': const [31.5, 32.0],
          'precipitation_probability': const [10, 40],
          'weather_code': const [1, 61],
        },
      );

      expect(result.locationLabel, 'Quezon City, Metro Manila');
      expect(result.currentTemperatureCelsius, 31.5);
      expect(result.currentCondition, 'Clear sky');
      expect(result.hourlyPulse, hasLength(2));
      expect(result.hourlyPulse.last.rainProbability, 40);
      expect(result.hourlyPulse.last.weatherCode, 61);
    });

    test('clear current weather drives concise weather-led hero copy', () {
      final result = presentation(
        current: const {
          'temperature_2m': 23.5,
          'relative_humidity_2m': 63,
          'weather_code': 0,
          'precipitation': 0,
        },
      );

      expect(result.briefingTitle, 'Today looks mostly clear.');
      expect(result.briefingBody, contains('Clear sky'));
      expect(result.briefingBody, isNot(contains('go-bag')));
    });
  });
}

final instant = DateTime.utc(2026, 11, 7, 2);

AlertItem alert([Map<String, dynamic> overrides = const {}]) =>
    AlertItem.fromJson({
      'id': 'official',
      'title': 'Weather advisory',
      'description': '',
      'issuedAt': instant.subtract(const Duration(hours: 1)).toIso8601String(),
      'severity': 'Low',
      'agency': 'PAGASA',
      'category': 'typhoon',
      'verificationStatus': 'official',
      'affectedAreas': ['Quezon City'],
      ...overrides,
    });

HomePresentation presentation({
  List<AlertItem> alerts = const [],
  Map<String, dynamic> current = const {},
  Map<String, dynamic> hourly = const {},
  GeoPoint location = const GeoPoint(
    14.676,
    121.0437,
    'Quezon City, Metro Manila',
  ),
  double radius = 100,
  bool fromCache = false,
  bool demoMode = false,
  List<KitItem> kit = const [],
  Map<String, String> familyPlan = const {},
  int contacts = 0,
  DateTime? weatherUpdated,
}) => buildHomePresentation(
  HomePresentationInput(
    weather: WeatherSnapshot(
      current: {
        'temperature_2m': 24,
        'relative_humidity_2m': 50,
        'weather_code': 0,
        ...current,
      },
      hourly: hourly,
      daily: const {},
      condition: 'Clear sky',
      modelCount: 1,
      rainVotes: 0,
    ),
    location: location,
    alerts: alerts,
    kit: kit,
    familyPlan: familyPlan,
    emergencyContactCount: contacts,
    alertsFromCache: fromCache,
    alertsDemoMode: demoMode,
    alertRadiusKm: radius,
    weatherUpdated: weatherUpdated ?? instant,
    alertsUpdated: instant,
    now: instant,
  ),
);
