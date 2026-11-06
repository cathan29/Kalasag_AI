import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kalasag/models.dart';
import 'package:kalasag/services.dart';

void main() {
  test(
    'live alert APIs are disabled by default and demo alerts are returned',
    () async {
      expect(liveAlertApisEnabled, isFalse);

      final alerts = await AlertService().fetch();

      expect(alerts, isNotEmpty);
      expect(alerts.every((alert) => alert.source == 'OFFLINE DEMO'), isTrue);
      expect(alerts.every((alert) => alert.sourceUrl.isEmpty), isTrue);
      expect(alerts.every((alert) => alert.isDemo), isTrue);
    },
  );

  test(
    'normalized backend response preserves provenance and official level',
    () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'retrievedAt': '2026-10-25T10:00:00Z',
            'sources': [
              {
                'id': 'usgs',
                'name': 'USGS Earthquake Catalog',
                'available': true,
                'checkedAt': '2026-10-25T10:00:00Z',
              },
            ],
            'alerts': [
              {
                'id': 'usgs-test',
                'title': 'M5.2 Earthquake',
                'description': 'Test fixture',
                'issuedAt': '2026-10-25T09:00:00Z',
                'visualPriority': 'High',
                'officialLevel': 'Magnitude 5.2',
                'agency': 'USGS',
                'category': 'earthquake',
                'sourceUrl': 'https://earthquake.usgs.gov/',
                'verificationStatus': 'supplementary',
                'lifecycle': 'active',
                'affectedAreas': ['Northern Luzon'],
                'actions': ['Follow local instructions.'],
              },
            ],
          }),
          200,
        ),
      );
      final result = await AlertService(
        client: client,
        backendBaseUrl: 'https://alerts.example',
      ).fetchDetailed();

      expect(result.alerts.single.officialLevel, 'Magnitude 5.2');
      expect(result.alerts.single.verificationStatus, 'supplementary');
      expect(result.sources.single.available, isTrue);
    },
  );

  test('distance calculation supports near-me filtering', () {
    const manila = GeoPoint(14.5995, 120.9842);
    const quezonCity = GeoPoint(14.6760, 121.0437);
    const cebu = GeoPoint(10.3157, 123.8854);

    expect(AlertService.distanceKm(manila, quezonCity), lessThan(20));
    expect(AlertService.distanceKm(manila, cebu), greaterThan(500));
  });

  test('alert JSON round-trip retains lifecycle, actions, and cache state', () {
    final alert = AlertItem.fromJson({
      'id': 'test',
      'title': 'Test alert',
      'description': 'Fixture',
      'issuedAt': '2026-10-25T09:00:00Z',
      'visualPriority': 'Medium',
      'agency': 'Fixture agency',
      'category': 'weather',
      'actions': ['Stay informed.'],
      'lifecycle': 'watch',
      'verificationStatus': 'official',
      'isCached': true,
    });

    expect(alert.actions, ['Stay informed.']);
    expect(alert.lifecycle, 'watch');
    expect(alert.isCached, isTrue);
    expect(AlertItem.fromJson(alert.toJson()).verificationStatus, 'official');
  });
}
