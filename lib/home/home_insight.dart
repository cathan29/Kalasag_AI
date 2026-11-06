import 'dart:math' as math;

import '../models.dart';

enum HomeMascotMood { happy, rain, storm }

enum HomeHazardTone { neutral, safe, caution, warning, danger }

class HomeHazardItem {
  const HomeHazardItem({
    required this.label,
    required this.value,
    required this.detail,
    required this.tone,
    this.isOfficial = false,
    this.isEstimated = false,
  });

  /// PAGASA bands use continuous lower bounds, without rounding up risk.
  factory HomeHazardItem.heatIndex(double? celsius) {
    final available = celsius != null && celsius.isFinite;
    final (value, tone) = !available
        ? ('Unavailable', HomeHazardTone.neutral)
        : celsius >= 52
        ? ('Extreme Danger', HomeHazardTone.danger)
        : celsius >= 42
        ? ('Danger', HomeHazardTone.danger)
        : celsius >= 33
        ? ('Extreme Caution', HomeHazardTone.warning)
        : celsius >= 27
        ? ('Caution', HomeHazardTone.caution)
        : ('Current conditions', HomeHazardTone.neutral);
    return HomeHazardItem(
      label: 'Estimated heat index',
      value: value,
      detail: available
          ? '${celsius.toStringAsFixed(1)} \u00b0C'
          : 'Temperature and humidity required',
      tone: tone,
      isEstimated: true,
    );
  }

  final String label, value, detail;
  final HomeHazardTone tone;
  final bool isOfficial, isEstimated;
}

class HomeAdvisorySummary {
  const HomeAdvisorySummary({
    required this.alert,
    required this.title,
    required this.source,
    required this.severity,
    required this.languageLabel,
    required this.updatedAt,
    required this.isStale,
    required this.isDemo,
    required this.isLocal,
  });

  final AlertItem alert;
  final String title, source, severity, languageLabel;
  final DateTime updatedAt;
  final bool isStale, isDemo, isLocal;
}

class HomeReadinessSummary {
  const HomeReadinessSummary({
    required this.goBagPercent,
    required this.completedKitItems,
    required this.totalKitItems,
    required this.familyPlanReady,
    required this.emergencyContactCount,
  });

  /// Null means there are no checklist items, rather than a verified zero.
  final int? goBagPercent;
  final int completedKitItems, totalKitItems, emergencyContactCount;
  final bool familyPlanReady;
}

class HomeHourlyPoint {
  const HomeHourlyPoint({
    required this.time,
    required this.temperatureCelsius,
    required this.rainProbability,
    required this.weatherCode,
  });

  final DateTime time;
  final double? temperatureCelsius;
  final int? rainProbability;
  final int? weatherCode;
}

class HomePresentation {
  HomePresentation({
    required this.mascotMood,
    required this.briefingTitle,
    required this.briefingBody,
    required List<HomeHazardItem> hazards,
    required this.advisory,
    required this.readiness,
    required this.weatherUpdated,
    required this.alertsUpdated,
    required this.weatherIsStale,
    required this.monitoringOfficialUpdates,
    required this.locationLabel,
    required this.currentTemperatureCelsius,
    required this.currentCondition,
    required List<HomeHourlyPoint> hourlyPulse,
  }) : hazards = List.unmodifiable(hazards),
       hourlyPulse = List.unmodifiable(hourlyPulse);

  final HomeMascotMood mascotMood;
  final String briefingTitle, briefingBody;
  final List<HomeHazardItem> hazards;
  final HomeAdvisorySummary? advisory;
  final HomeReadinessSummary readiness;
  final DateTime? weatherUpdated, alertsUpdated;
  final bool weatherIsStale, monitoringOfficialUpdates;
  final String locationLabel, currentCondition;
  final double? currentTemperatureCelsius;
  final List<HomeHourlyPoint> hourlyPulse;
}

class HomePresentationInput {
  const HomePresentationInput({
    required this.weather,
    required this.location,
    required this.alerts,
    required this.kit,
    required this.familyPlan,
    required this.emergencyContactCount,
    required this.alertsFromCache,
    required this.alertsDemoMode,
    required this.alertRadiusKm,
    required this.weatherUpdated,
    required this.alertsUpdated,
    required this.now,
  });

  final WeatherSnapshot weather;
  final GeoPoint location;
  final List<AlertItem> alerts;
  final List<KitItem> kit;
  final Map<String, String> familyPlan;
  final int emergencyContactCount;
  final bool alertsFromCache, alertsDemoMode;
  final double alertRadiusKm;
  final DateTime? weatherUpdated, alertsUpdated;
  final DateTime now;
}

HomePresentation buildHomePresentation(HomePresentationInput input) {
  final live =
      input.alerts
          .where(
            (alert) =>
                !input.alertsDemoMode &&
                !input.alertsFromCache &&
                !_isDemo(alert) &&
                !alert.isCached &&
                _isCurrent(alert, input.now) &&
                _isLocal(alert, input),
          )
          .toList()
        ..sort(_compareAlerts);
  final official = live.where(_isOfficial).toList();
  final hazards = <HomeHazardItem>[];
  for (final alert in official) {
    final hazard = _officialHazard(alert);
    if (!hazards.any((item) => item.label == hazard.label)) {
      hazards.add(hazard);
    }
  }
  if (official.isEmpty) {
    hazards.add(
      const HomeHazardItem(
        label: 'Official alerts',
        value: 'Monitoring official updates',
        detail: 'No verified current advisory matched to this location',
        tone: HomeHazardTone.neutral,
      ),
    );
  }

  final weatherCurrent = _recent(input.weatherUpdated, input.now);
  final current = input.weather.current;
  final heat = HomeHazardItem.heatIndex(
    weatherCurrent
        ? calculateHeatIndexCelsius(
            temperatureCelsius: _number(current['temperature_2m']),
            relativeHumidity: _number(current['relative_humidity_2m']),
          )
        : null,
  );
  hazards.add(heat);

  final severeAlert = live.any(
    (alert) =>
        _weatherCategory(alert.category) &&
        (_severityRank(alert.severity) >= 3 ||
            (_isOfficial(alert) &&
                _officialHazard(alert).tone == HomeHazardTone.danger)),
  );
  final rainfallAlert = official.any(
    (alert) => _officialHazard(alert).label == 'Rainfall warning',
  );
  final code = weatherCurrent
      ? _number(current['weather_code'])?.round()
      : null;
  final storm = severeAlert || (code != null && {95, 96, 99}.contains(code));
  final rain =
      rainfallAlert ||
      (code != null &&
          {
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
          }.contains(code)) ||
      (weatherCurrent && (_number(current['precipitation']) ?? 0) > 0);
  final mood = storm
      ? HomeMascotMood.storm
      : rain
      ? HomeMascotMood.rain
      : HomeMascotMood.happy;

  final String title;
  final String body;
  if (official.isNotEmpty) {
    title = 'Official advisory for your area';
    final hazard = hazards.first;
    body =
        '${hazard.label}: ${hazard.value}. Follow official updates and local authority instructions.';
  } else if (!weatherCurrent) {
    title = 'Check the latest conditions';
    body = 'Refresh weather data and monitor official updates for your area.';
  } else if (storm) {
    title = 'Stormy conditions';
    body =
        'Check official updates before travelling and stay prepared for changing weather.';
  } else if (heat.tone == HomeHazardTone.danger ||
      heat.tone == HomeHazardTone.warning) {
    title = 'Plan for the heat';
    body =
        '${heat.label}: ${heat.value}. Limit strenuous outdoor activity and take water and shade breaks.';
  } else if (rain) {
    title = 'Rain in the picture';
    body = 'Prepare for wet conditions and monitor official rainfall updates.';
  } else {
    title = 'Today looks mostly clear.';
    body =
        '${input.weather.condition} expected for the next few hours. Stay prepared and monitor updates.';
  }

  final completed = input.kit.where((item) => item.done).length;
  final hourly = input.weather.hourly;
  final times = List<dynamic>.from(hourly['time'] ?? const []);
  final temperatures = List<dynamic>.from(hourly['temperature_2m'] ?? const []);
  final rainProbabilities = List<dynamic>.from(
    hourly['precipitation_probability'] ?? const [],
  );
  final weatherCodes = List<dynamic>.from(hourly['weather_code'] ?? const []);
  final pulse = <HomeHourlyPoint>[];
  for (var index = 0; index < times.length && pulse.length < 8; index++) {
    final time = DateTime.tryParse('${times[index]}');
    if (time == null || time.isBefore(input.now)) continue;
    pulse.add(
      HomeHourlyPoint(
        time: time,
        temperatureCelsius: index < temperatures.length
            ? _number(temperatures[index])
            : null,
        rainProbability: index < rainProbabilities.length
            ? _number(rainProbabilities[index])?.round()
            : null,
        weatherCode: index < weatherCodes.length
            ? _number(weatherCodes[index])?.round()
            : null,
      ),
    );
  }
  return HomePresentation(
    mascotMood: mood,
    briefingTitle: title,
    briefingBody: body,
    hazards: hazards,
    advisory: _advisory(input, live),
    readiness: HomeReadinessSummary(
      goBagPercent: input.kit.isEmpty
          ? null
          : (completed * 100 / input.kit.length).round(),
      completedKitItems: completed,
      totalKitItems: input.kit.length,
      familyPlanReady: [
        'meetingPlace',
        'outOfTownContact',
        'medicalNotes',
      ].every((key) => (input.familyPlan[key] ?? '').trim().isNotEmpty),
      emergencyContactCount: input.emergencyContactCount,
    ),
    weatherUpdated: input.weatherUpdated,
    alertsUpdated: input.alertsUpdated,
    weatherIsStale: !weatherCurrent,
    monitoringOfficialUpdates: official.isEmpty,
    locationLabel: input.location.label,
    currentTemperatureCelsius: _number(current['temperature_2m']),
    currentCondition: input.weather.condition,
    hourlyPulse: pulse,
  );
}

HomeAdvisorySummary? _advisory(
  HomePresentationInput input,
  List<AlertItem> live,
) {
  final real = input.alerts.where((alert) => !_isDemo(alert)).toList()
    ..sort(_compareAlerts);
  final practice = input.alerts.where(_isDemo).toList()..sort(_compareAlerts);
  final pool = live.isNotEmpty
      ? live
      : real.isNotEmpty
      ? real
      : practice;
  if (pool.isEmpty) return null;
  final alert = pool.first;
  final demo = input.alertsDemoMode || _isDemo(alert);
  final language = alert.language.trim().toLowerCase().replaceAll('_', '-');
  final english = language == 'en' || language.startsWith('en-');
  final languageLabel = english
      ? 'English'
      : {'fil', 'tl', 'fil-ph', 'tl-ph'}.contains(language)
      ? 'Filipino'
      : 'Source language';
  return HomeAdvisorySummary(
    alert: alert,
    title: demo
        ? 'Practice advisory'
        : !english
        ? 'Official advisory available'
        : alert.title.trim().isEmpty
        ? 'Official advisory available'
        : alert.title.trim(),
    source: alert.source,
    severity: _severityLabel(alert.severity),
    languageLabel: languageLabel,
    updatedAt: _latestTime(alert),
    isStale:
        !demo &&
        (input.alertsFromCache ||
            alert.isCached ||
            !_isCurrent(alert, input.now)),
    isDemo: demo,
    isLocal: _isLocal(alert, input),
  );
}

bool _isDemo(AlertItem alert) =>
    alert.verificationStatus.trim().toLowerCase() == 'demo' ||
    alert.source.trim().toUpperCase() == 'OFFLINE DEMO';

bool _isOfficial(AlertItem alert) =>
    alert.verificationStatus.trim().toLowerCase() == 'official';

DateTime _latestTime(AlertItem alert) =>
    alert.updatedAt != null && alert.updatedAt!.isAfter(alert.publishedAt)
    ? alert.updatedAt!
    : alert.publishedAt;

bool _recent(DateTime? time, DateTime now) =>
    time != null &&
    !time.isAfter(now) &&
    now.difference(time) <= const Duration(hours: 24);

bool _isCurrent(AlertItem alert, DateTime now) {
  if (alert.lifecycle.trim().toLowerCase() != 'active' ||
      _latestTime(alert).isAfter(now) ||
      (alert.effectiveAt?.isAfter(now) ?? false) ||
      (alert.expiresAt != null && !alert.expiresAt!.isAfter(now))) {
    return false;
  }
  return _recent(_latestTime(alert), now) ||
      (alert.expiresAt?.isAfter(now) ?? false);
}

int _severityRank(String severity) => switch (severity.trim().toLowerCase()) {
  'critical' => 4,
  'high' => 3,
  'medium' => 2,
  'low' => 1,
  _ => 0,
};

String _severityLabel(String severity) => switch (_severityRank(severity)) {
  4 => 'Critical',
  3 => 'High',
  2 => 'Medium',
  1 => 'Low',
  _ => 'Unknown',
};

int _compareAlerts(AlertItem a, AlertItem b) {
  final official = (_isOfficial(b) ? 1 : 0).compareTo(_isOfficial(a) ? 1 : 0);
  if (official != 0) return official;
  final severity = _severityRank(
    b.severity,
  ).compareTo(_severityRank(a.severity));
  if (severity != 0) return severity;
  final time = _latestTime(b).compareTo(_latestTime(a));
  return time != 0 ? time : a.id.compareTo(b.id);
}

HomeHazardItem _officialHazard(AlertItem alert) {
  final level = alert.officialLevel
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .toLowerCase();
  final signal = RegExp(
    r'^(?:tcws|(?:tropical cyclone wind )?signal)\s*(?:no\.?\s*|#\s*)?([1-5])$',
  ).firstMatch(level);
  if (signal != null) {
    final number = int.parse(signal.group(1)!);
    return HomeHazardItem(
      label: 'Tropical cyclone wind signal',
      value: 'Signal No. $number',
      detail: 'Official local advisory',
      isOfficial: true,
      tone: number >= 3
          ? HomeHazardTone.danger
          : number == 2
          ? HomeHazardTone.warning
          : HomeHazardTone.caution,
    );
  }
  final rainfall = RegExp(
    r'^(yellow|orange|red)(?: (?:rainfall )?(?:warning|advisory))?$',
  ).firstMatch(level);
  if (rainfall != null && alert.category.toLowerCase().contains('rain')) {
    final color = rainfall.group(1)!;
    return HomeHazardItem(
      label: 'Rainfall warning',
      value: '${color[0].toUpperCase()}${color.substring(1)} warning',
      detail: 'Official local advisory',
      isOfficial: true,
      tone: color == 'red'
          ? HomeHazardTone.danger
          : color == 'orange'
          ? HomeHazardTone.warning
          : HomeHazardTone.caution,
    );
  }
  return HomeHazardItem(
    label: 'Official alerts',
    value: 'Official advisory',
    detail: 'Verified advisory for your area',
    isOfficial: true,
    tone: _severityRank(alert.severity) >= 4
        ? HomeHazardTone.danger
        : _severityRank(alert.severity) >= 3
        ? HomeHazardTone.warning
        : HomeHazardTone.caution,
  );
}

bool _weatherCategory(String category) => RegExp(
  r'weather|rain|flood|typhoon|cyclone|storm',
).hasMatch(category.toLowerCase());

String _normalizeArea(String value) => value
    .toLowerCase()
    .replaceAll('\u00f1', 'n')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim();

bool _isLocal(AlertItem alert, HomePresentationInput input) {
  if (alert.affectedAreas.isNotEmpty) {
    final label = _normalizeArea(input.location.label);
    if (label.isEmpty ||
        {
          'current location',
          'unknown',
          'location',
          'philippines',
        }.contains(label)) {
      return false;
    }
    final localAreas =
        input.location.label
            .split(',')
            .map(_normalizeArea)
            .where((part) => part.isNotEmpty)
            .toSet()
          ..add(label);
    return alert.affectedAreas.any(
      (area) => localAreas.contains(_normalizeArea(area)),
    );
  }
  final point = alert.coordinates;
  if (point == null || !_validPoint(point) || !_validPoint(input.location)) {
    return false;
  }
  // Only absent area data permits coordinate fallback; conflicting area data wins.
  final radius = input.alertRadiusKm.isNaN
      ? 10.0
      : input.alertRadiusKm.clamp(10.0, 200.0);
  final lat1 = input.location.latitude * math.pi / 180;
  final lat2 = point.latitude * math.pi / 180;
  final deltaLat = lat2 - lat1;
  final deltaLon = (point.longitude - input.location.longitude) * math.pi / 180;
  final a =
      math.pow(math.sin(deltaLat / 2), 2) +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(deltaLon / 2), 2);
  final distance = 6371 * 2 * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
  return distance <= radius;
}

bool _validPoint(GeoPoint point) =>
    point.latitude.isFinite &&
    point.longitude.isFinite &&
    point.latitude.abs() <= 90 &&
    point.longitude.abs() <= 180;

double? _number(dynamic value) =>
    value is num && value.isFinite ? value.toDouble() : null;

/// NOAA's Steadman screening and adjusted Rothfusz regression, in Celsius.
/// https://www.wpc.ncep.noaa.gov/html/heatindex_equation.shtml
/// This is an estimate, not a PAGASA station observation.
double? calculateHeatIndexCelsius({
  required double? temperatureCelsius,
  required double? relativeHumidity,
}) {
  if (temperatureCelsius == null ||
      relativeHumidity == null ||
      !temperatureCelsius.isFinite ||
      !relativeHumidity.isFinite ||
      relativeHumidity < 0 ||
      relativeHumidity > 100) {
    return null;
  }
  final t = temperatureCelsius * 9 / 5 + 32;
  final rh = relativeHumidity;
  var index = (0.5 * (t + 61 + (t - 68) * 1.2 + rh * 0.094) + t) / 2;
  if (index >= 80) {
    index =
        -42.379 +
        2.04901523 * t +
        10.14333127 * rh -
        0.22475541 * t * rh -
        0.00683783 * t * t -
        0.05481717 * rh * rh +
        0.00122874 * t * t * rh +
        0.00085282 * t * rh * rh -
        0.00000199 * t * t * rh * rh;
    if (rh < 13 && t >= 80 && t <= 112) {
      index -= (13 - rh) / 4 * math.sqrt((17 - (t - 95).abs()) / 17);
    } else if (rh > 85 && t >= 80 && t <= 87) {
      index += (rh - 85) / 10 * (87 - t) / 5;
    }
  }
  final result = (index - 32) * 5 / 9;
  return result.isFinite ? result : null;
}
