import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'models.dart';

const weatherDescriptions = <int, String>{
  0: 'Clear sky',
  1: 'Mainly clear',
  2: 'Partly cloudy',
  3: 'Overcast',
  45: 'Fog',
  48: 'Rime fog',
  51: 'Light drizzle',
  53: 'Moderate drizzle',
  55: 'Dense drizzle',
  61: 'Slight rain',
  63: 'Moderate rain',
  65: 'Heavy rain',
  80: 'Rain showers',
  81: 'Moderate showers',
  82: 'Violent showers',
  95: 'Thunderstorm',
  96: 'Thunderstorm with hail',
  99: 'Severe thunderstorm with hail',
};

class WeatherService {
  static const _models = [
    'best_match',
    'jma_seamless',
    'gfs_seamless',
    'icon_seamless',
  ];
  Future<WeatherSnapshot> fetch(GeoPoint point) async {
    final query = <String, String>{
      'latitude': '${point.latitude}',
      'longitude': '${point.longitude}',
      'current':
          'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m,precipitation,rain,showers,cloud_cover',
      'hourly':
          'temperature_2m,relative_humidity_2m,precipitation,precipitation_probability,weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,wind_speed_10m_max',
      'models': _models.join(','),
      'timezone': 'auto',
      'forecast_days': '3',
      'cell_selection': 'land',
    };
    final response = await http
        .get(Uri.https('api.open-meteo.com', '/v1/forecast', query))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Weather API error ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final current = Map<String, dynamic>.from(json['current'] ?? {});
    final rawHourly = Map<String, dynamic>.from(json['hourly'] ?? {});
    final hourly = _normalizeHourly(rawHourly);
    final daily = _normalizeDaily(
      Map<String, dynamic>.from(json['daily'] ?? {}),
    );
    final codes = _valuesAt(
      rawHourly,
      'weather_code',
      _currentIndex(rawHourly['time'], current['time']),
    );
    final rainVotes = codes.where((v) => _rainCodes.contains(v.round())).length;
    return WeatherSnapshot(
      current: current,
      hourly: hourly,
      daily: daily,
      condition:
          weatherDescriptions[(current['weather_code'] as num?)?.round()] ??
          'Local weather',
      modelCount: codes.length,
      rainVotes: rainVotes,
    );
  }

  static const _rainCodes = {
    51,
    53,
    55,
    56,
    57,
    61,
    63,
    65,
    66,
    67,
    80,
    81,
    82,
    95,
    96,
    99,
  };
  int _currentIndex(dynamic values, dynamic current) {
    final list = List<dynamic>.from(values ?? []);
    final key = '$current';
    final exact = list.indexWhere(
      (v) =>
          '$v'.substring(0, min(13, '$v'.length)) ==
          key.substring(0, min(13, key.length)),
    );
    return exact < 0 ? 0 : exact;
  }

  List<double> _valuesAt(
    Map<String, dynamic> src,
    String variable,
    int index,
  ) => _models
      .map((m) {
        final list = src['${variable}_$m'];
        return list is List && index < list.length
            ? (list[index] as num?)?.toDouble()
            : null;
      })
      .whereType<double>()
      .toList();
  double? _median(List<double> values) {
    if (values.isEmpty) return null;
    values.sort();
    final m = values.length ~/ 2;
    return values.length.isOdd ? values[m] : (values[m - 1] + values[m]) / 2;
  }

  Map<String, dynamic> _normalizeHourly(Map<String, dynamic> src) {
    final times = List<dynamic>.from(src['time'] ?? []);
    final out = <String, dynamic>{'time': times};
    for (final key in [
      'temperature_2m',
      'precipitation',
      'precipitation_probability',
    ]) {
      out[key] = List.generate(
        times.length,
        (i) => _median(_valuesAt(src, key, i)),
      );
    }
    out['weather_code'] = List.generate(
      times.length,
      (i) => _median(_valuesAt(src, 'weather_code', i))?.round(),
    );
    for (final key in [
      'relative_humidity_2m',
      'wind_speed_10m',
      'wind_direction_10m',
      'wind_gusts_10m',
    ]) {
      out[key] = src['${key}_best_match'] ?? src[key] ?? [];
    }
    return out;
  }

  Map<String, dynamic> _normalizeDaily(Map<String, dynamic> src) {
    final out = <String, dynamic>{};
    for (final key in [
      'time',
      'weather_code',
      'temperature_2m_max',
      'temperature_2m_min',
      'precipitation_sum',
      'wind_speed_10m_max',
    ]) {
      out[key] = src['${key}_best_match'] ?? src[key] ?? [];
    }
    return out;
  }
}

const bool liveAlertApisEnabled = bool.fromEnvironment(
  'ENABLE_LIVE_ALERT_APIS',
  defaultValue: false,
);

const String alertBackendBaseUrl = String.fromEnvironment(
  'KALASAG_ALERTS_BASE_URL',
);

class AlertSourceStatus {
  const AlertSourceStatus({
    required this.id,
    required this.name,
    required this.available,
    required this.checkedAt,
    this.message = '',
  });
  final String id, name, message;
  final bool available;
  final DateTime checkedAt;

  factory AlertSourceStatus.fromJson(Map<String, dynamic> json) =>
      AlertSourceStatus(
        id: '${json['id'] ?? ''}',
        name: '${json['name'] ?? json['id'] ?? 'Unknown source'}',
        available: json['available'] == true,
        checkedAt:
            DateTime.tryParse('${json['checkedAt'] ?? ''}') ?? DateTime.now(),
        message: '${json['message'] ?? ''}',
      );
}

class AlertFetchResult {
  const AlertFetchResult({
    required this.alerts,
    required this.sources,
    required this.retrievedAt,
    this.isDemo = false,
  });
  final List<AlertItem> alerts;
  final List<AlertSourceStatus> sources;
  final DateTime retrievedAt;
  final bool isDemo;
  bool get hasFailures => sources.any((source) => !source.available);
}

class AlertService {
  AlertService({http.Client? client, bool? enableLive, String? backendBaseUrl})
    : _client = client ?? http.Client(),
      _enableLive = enableLive ?? liveAlertApisEnabled,
      _backendBaseUrl = backendBaseUrl ?? alertBackendBaseUrl;

  final http.Client _client;
  final bool _enableLive;
  final String _backendBaseUrl;

  static bool _inside(GeoPoint? p) =>
      p != null &&
      p.latitude >= 4 &&
      p.latitude <= 22 &&
      p.longitude >= 115 &&
      p.longitude <= 130;
  Future<List<AlertItem>> fetch() async => (await fetchDetailed()).alerts;

  Future<AlertFetchResult> fetchDetailed() async {
    if (_backendBaseUrl.trim().isNotEmpty) return _fetchBackend();
    if (!_enableLive) {
      return AlertFetchResult(
        alerts: _offlineDemoAlerts(),
        sources: [
          AlertSourceStatus(
            id: 'practice',
            name: 'Practice mode',
            available: true,
            checkedAt: DateTime.now(),
            message: 'Live ingestion is not configured for this build.',
          ),
        ],
        retrievedAt: DateTime.now(),
        isDemo: true,
      );
    }

    final results = await Future.wait([
      _capture('gdacs', 'GDACS', _gdacs),
      _capture('usgs', 'USGS Earthquake Catalog', _usgs),
      _capture('eonet', 'NASA EONET', _eonet),
    ]);
    final alerts = _normalize(results.expand((result) => result.alerts));
    return AlertFetchResult(
      alerts: alerts,
      sources: results.map((result) => result.status).toList(),
      retrievedAt: DateTime.now(),
    );
  }

  Future<AlertFetchResult> _fetchBackend() async {
    final base = _backendBaseUrl.replaceFirst(RegExp(r'/$'), '');
    final response = await _client
        .get(Uri.parse('$base/v1/alerts'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Alert service returned ${response.statusCode}.');
    }
    final body = Map<String, dynamic>.from(jsonDecode(response.body));
    return AlertFetchResult(
      alerts: _normalize(
        List<dynamic>.from(
          body['alerts'] ?? const [],
        ).map((item) => AlertItem.fromJson(Map<String, dynamic>.from(item))),
      ),
      sources: List<dynamic>.from(body['sources'] ?? const [])
          .map(
            (source) =>
                AlertSourceStatus.fromJson(Map<String, dynamic>.from(source)),
          )
          .toList(),
      retrievedAt:
          DateTime.tryParse('${body['retrievedAt'] ?? ''}') ?? DateTime.now(),
    );
  }

  Future<_ProviderResult> _capture(
    String id,
    String name,
    Future<List<AlertItem>> Function() loader,
  ) async {
    final checkedAt = DateTime.now();
    try {
      return _ProviderResult(
        await loader(),
        AlertSourceStatus(
          id: id,
          name: name,
          available: true,
          checkedAt: checkedAt,
        ),
      );
    } catch (_) {
      return _ProviderResult(
        const [],
        AlertSourceStatus(
          id: id,
          name: name,
          available: false,
          checkedAt: checkedAt,
          message: 'The provider could not be reached.',
        ),
      );
    }
  }

  List<AlertItem> _normalize(Iterable<AlertItem> input) {
    final now = DateTime.now();
    final byKey = <String, AlertItem>{};
    for (final alert in input) {
      if (alert.expiresAt != null && alert.expiresAt!.isBefore(now)) continue;
      final title = alert.title
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
          .trim();
      final key =
          '${alert.category}:$title:${alert.publishedAt.toUtc().toIso8601String().substring(0, 10)}';
      final previous = byKey[key];
      if (previous == null ||
          (alert.updatedAt ?? alert.publishedAt).isAfter(
            previous.updatedAt ?? previous.publishedAt,
          )) {
        byKey[key] = alert;
      }
    }
    final alerts = byKey.values.toList();
    const rank = {'Critical': 4, 'High': 3, 'Medium': 2, 'Low': 1};
    alerts.sort((a, b) {
      if (a.isEnded != b.isEnded) return a.isEnded ? 1 : -1;
      final priority = (rank[b.severity] ?? 0).compareTo(rank[a.severity] ?? 0);
      return priority != 0 ? priority : b.publishedAt.compareTo(a.publishedAt);
    });
    return alerts;
  }

  static double distanceKm(GeoPoint a, GeoPoint b) {
    const radius = 6371.0;
    double radians(double value) => value * pi / 180;
    final dLat = radians(b.latitude - a.latitude);
    final dLon = radians(b.longitude - a.longitude);
    final value =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(radians(a.latitude)) *
            cos(radians(b.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return radius * 2 * atan2(sqrt(value), sqrt(1 - value));
  }

  List<AlertItem> _offlineDemoAlerts() {
    final now = DateTime.now();
    return [
      AlertItem(
        id: 'demo-weather-pangasinan',
        title: 'Demo Heavy Rainfall Advisory',
        description:
            'Offline demonstration data for navigation and data-passing. '
            'This is not a current emergency advisory.',
        publishedAt: now.subtract(const Duration(minutes: 20)),
        severity: 'High',
        source: 'OFFLINE DEMO',
        category: 'weather',
        officialLevel: 'Practice scenario',
        verificationStatus: 'demo',
        lifecycle: 'exercise',
        actions: const [
          'Review your household flood plan.',
          'Check your go-bag supplies.',
        ],
        retrievedAt: now,
        coordinates: const GeoPoint(15.8949, 120.2863, 'Pangasinan'),
        affectedAreas: const ['Pangasinan'],
      ),
      AlertItem(
        id: 'demo-earthquake-luzon',
        title: 'Demo Earthquake Information',
        description:
            'Offline demonstration data for the Kalasag alert-details screen. '
            'This is not a live earthquake report.',
        publishedAt: now.subtract(const Duration(hours: 2)),
        severity: 'Medium',
        source: 'OFFLINE DEMO',
        category: 'earthquake',
        officialLevel: 'Practice scenario',
        verificationStatus: 'demo',
        lifecycle: 'exercise',
        actions: const [
          'Practice Drop, Cover, and Hold On.',
          'Identify safe evacuation routes.',
        ],
        retrievedAt: now,
        coordinates: const GeoPoint(16.4023, 120.5960, 'Northern Luzon'),
        affectedAreas: const ['Northern Luzon'],
      ),
    ];
  }

  Future<List<AlertItem>> _gdacs() async {
    final r = await _client
        .get(
          Uri.parse(
            'https://www.gdacs.org/gdacsapi/api/events/geteventlist/events4app',
          ),
        )
        .timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) throw Exception();
    final j = jsonDecode(r.body);
    final features = List<dynamic>.from(j['features'] ?? []);
    return features
        .map((f) {
          final p = Map<String, dynamic>.from(f['properties'] ?? {});
          final c = f['geometry']?['coordinates'];
          final point = c is List && c.length >= 2
              ? GeoPoint((c[1] as num).toDouble(), (c[0] as num).toDouble())
              : null;
          final country = '${p['country'] ?? p['affectedcountries'] ?? ''}'
              .toLowerCase();
          if (!country.contains('philippine') && !_inside(point)) return null;
          final type = '${p['eventtype'] ?? ''}'.toUpperCase();
          final category = type == 'EQ'
              ? 'earthquake'
              : type == 'VO'
              ? 'volcano'
              : type == 'WF'
              ? 'wildfire'
              : 'weather';
          final level = '${p['alertlevel'] ?? ''}'.toLowerCase();
          final severity = level == 'red'
              ? 'Critical'
              : level == 'orange'
              ? 'High'
              : level == 'green'
              ? 'Medium'
              : 'Low';
          return AlertItem(
            id: 'gdacs-${p['eventid'] ?? p['id']}',
            title: '${p['eventname'] ?? p['name'] ?? 'Disaster alert'}',
            description: _plain(
              '${p['description'] ?? p['severitytext'] ?? 'Disaster affecting the Philippines.'}',
            ),
            publishedAt:
                DateTime.tryParse('${p['todate'] ?? p['fromdate']}') ??
                DateTime.now(),
            severity: severity,
            source: 'GDACS',
            category: category,
            coordinates: _inside(point) ? point : null,
            sourceUrl: '${p['url'] ?? 'https://www.gdacs.org/'}',
          );
        })
        .whereType<AlertItem>()
        .toList();
  }

  Future<List<AlertItem>> _usgs() async {
    final start = DateTime.now()
        .subtract(const Duration(days: 3))
        .toUtc()
        .toIso8601String();
    final uri = Uri.https('earthquake.usgs.gov', '/fdsnws/event/1/query', {
      'format': 'geojson',
      'starttime': start,
      'minlatitude': '4',
      'maxlatitude': '22',
      'minlongitude': '115',
      'maxlongitude': '130',
      'minmagnitude': '3.5',
      'orderby': 'time',
    });
    final r = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) throw Exception();
    final features = List<dynamic>.from(jsonDecode(r.body)['features'] ?? []);
    return features.map((f) {
      final p = f['properties'];
      final c = f['geometry']['coordinates'];
      final mag = (p['mag'] as num?)?.toDouble() ?? 0;
      return AlertItem(
        id: 'usgs-${f['id']}',
        title: 'M${mag.toStringAsFixed(1)} Earthquake',
        description:
            '${p['place'] ?? 'Philippines region'} at a depth of ${((c[2] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} km.',
        publishedAt: DateTime.fromMillisecondsSinceEpoch(
          (p['updated'] as num).round(),
        ),
        severity: mag >= 6
            ? 'Critical'
            : mag >= 5
            ? 'High'
            : mag >= 4
            ? 'Medium'
            : 'Low',
        source: 'USGS',
        category: 'earthquake',
        sourceUrl: p['url'] ?? 'https://earthquake.usgs.gov',
        coordinates: GeoPoint(
          (c[1] as num).toDouble(),
          (c[0] as num).toDouble(),
        ),
      );
    }).toList();
  }

  Future<List<AlertItem>> _eonet() async {
    final uri = Uri.https('eonet.gsfc.nasa.gov', '/api/v3/events', {
      'bbox': '115,22,130,4',
      'days': '30',
      'status': 'open',
      'limit': '100',
    });
    final r = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) throw Exception();
    final events = List<dynamic>.from(jsonDecode(r.body)['events'] ?? []);
    return events
        .map((e) {
          final cats = List<dynamic>.from(e['categories'] ?? []);
          final id = '${cats.isEmpty ? '' : cats.first['id']}';
          final map = {
            'floods': 'weather',
            'severeStorms': 'weather',
            'landslides': 'weather',
            'volcanoes': 'volcano',
            'wildfires': 'wildfire',
          };
          if (!map.containsKey(id)) return null;
          final geo = List<dynamic>.from(e['geometry'] ?? []);
          if (geo.isEmpty) return null;
          final c = geo.last['coordinates'];
          if (c is! List || c.length < 2) return null;
          final point = GeoPoint(
            (c[1] as num).toDouble(),
            (c[0] as num).toDouble(),
          );
          if (!_inside(point)) return null;
          return AlertItem(
            id: 'eonet-${e['id']}',
            title: e['title'] ?? 'Natural event',
            description:
                e['description'] ??
                'Natural event tracked within the Philippine area.',
            publishedAt:
                DateTime.tryParse('${geo.last['date']}') ?? DateTime.now(),
            severity: id == 'severeStorms' || id == 'volcanoes'
                ? 'High'
                : 'Medium',
            source: 'NASA EONET',
            category: map[id]!,
            coordinates: point,
            sourceUrl: e['link'] ?? 'https://eonet.gsfc.nasa.gov/',
          );
        })
        .whereType<AlertItem>()
        .toList();
  }

  String _plain(String value) => value
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class _ProviderResult {
  const _ProviderResult(this.alerts, this.status);
  final List<AlertItem> alerts;
  final AlertSourceStatus status;
}

double distanceKm(GeoPoint a, GeoPoint b) {
  const r = 6371.0;
  double rad(double d) => d * pi / 180;
  final dLat = rad(b.latitude - a.latitude),
      dLon = rad(b.longitude - a.longitude);
  final x =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(rad(a.latitude)) *
          cos(rad(b.latitude)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  return 2 * r * atan2(sqrt(x), sqrt(1 - x));
}

class ShelterService {
  Future<List<Shelter>> fetch(GeoPoint origin, double radiusKm) async {
    final query =
        '[out:json][timeout:25];(node["amenity"="shelter"](around:${(radiusKm * 1000).round()},${origin.latitude},${origin.longitude});way["amenity"="shelter"](around:${(radiusKm * 1000).round()},${origin.latitude},${origin.longitude});relation["amenity"="shelter"](around:${(radiusKm * 1000).round()},${origin.latitude},${origin.longitude});node["social_facility"="shelter"](around:${(radiusKm * 1000).round()},${origin.latitude},${origin.longitude}););out center tags;';
    final r = await http
        .post(
          Uri.parse('https://overpass-api.de/api/interpreter'),
          body: {'data': query},
        )
        .timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) throw Exception('Shelter service unavailable');
    final els = List<dynamic>.from(jsonDecode(r.body)['elements'] ?? []);
    return els
        .map((e) {
          final t = Map<String, dynamic>.from(e['tags'] ?? {});
          final lat = (e['lat'] ?? e['center']?['lat']) as num?;
          final lon = (e['lon'] ?? e['center']?['lon']) as num?;
          if (lat == null || lon == null) return null;
          final p = GeoPoint(lat.toDouble(), lon.toDouble());
          return Shelter(
            id: '${e['type']}-${e['id']}',
            name: t['name'] ?? 'Evacuation center',
            address: [
              t['addr:street'],
              t['addr:city'],
            ].whereType<String>().join(', '),
            type: t['shelter_type'] ?? 'Emergency shelter',
            coordinates: p,
            operator: t['operator'] ?? '',
            phone: t['phone'] ?? '',
            capacity: '${t['capacity'] ?? ''}',
            distanceKm: distanceKm(origin, p),
            sourceUrl: 'https://www.openstreetmap.org/${e['type']}/${e['id']}',
          );
        })
        .whereType<Shelter>()
        .toList()
      ..sort((a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));
  }
}
