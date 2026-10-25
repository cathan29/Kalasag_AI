import 'package:flutter_test/flutter_test.dart';
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
    },
  );
}
