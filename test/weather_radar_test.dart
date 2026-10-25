import 'package:flutter_test/flutter_test.dart';
import 'package:kalasag/models.dart';
import 'package:kalasag/screens.dart';

void main() {
  const point = GeoPoint(15.8949, 120.2863, 'Pangasinan');

  test('Windy embed URL configures a real forecast layer and location', () {
    final uri = buildWindyEmbedUri(point: point, overlay: 'rain');

    expect(uri.scheme, 'https');
    expect(uri.host, 'embed.windy.com');
    expect(uri.path, '/embed2.html');
    expect(uri.queryParameters['overlay'], 'rain');
    expect(uri.queryParameters['calendar'], 'now');
    expect(uri.queryParameters['type'], 'map');
    expect(uri.queryParameters['marker'], 'true');
    expect(uri.queryParameters['lat'], '${point.latitude}');
    expect(uri.queryParameters['lon'], '${point.longitude}');
  });

  test('only layers exposed by the Kalasag selector are accepted', () {
    for (final layer in windySupportedLayers) {
      expect(
        () => buildWindyEmbedUri(point: point, overlay: layer),
        returnsNormally,
      );
    }
    expect(
      () => buildWindyEmbedUri(point: point, overlay: 'radar'),
      throwsArgumentError,
    );
  });
}
