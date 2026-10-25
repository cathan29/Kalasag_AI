import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'app_state.dart';
import 'models.dart';
import 'theme.dart';
import 'extras.dart';
import 'api_activity_screen.dart';
import 'offline_safety_assistant.dart';
import 'design_system.dart';

String value(dynamic v, [String unit = '']) =>
    v is num ? '${v.round()}$unit' : 'N/A';
IconData weatherIcon(dynamic code) {
  final c = (code as num?)?.round() ?? 0;
  if ([95, 96, 99].contains(c)) return Icons.thunderstorm;
  if ([51, 53, 55, 61, 63, 65, 80, 81, 82].contains(c)) return Icons.water_drop;
  if ([1, 2, 3, 45, 48].contains(c)) return Icons.cloud;
  return Icons.wb_sunny;
}

String relative(DateTime? d) {
  if (d == null) return 'not yet';
  final x = DateTime.now().difference(d);
  if (x.inMinutes < 1) return 'just now';
  if (x.inHours < 1) return '${x.inMinutes}m ago';
  if (x.inDays < 1) return '${x.inHours}h ago';
  return DateFormat.MMMd().format(d);
}

const windySupportedLayers = {'rain', 'wind', 'temp', 'clouds'};

Uri buildWindyEmbedUri({required GeoPoint point, required String overlay}) {
  if (!windySupportedLayers.contains(overlay)) {
    throw ArgumentError.value(overlay, 'overlay', 'Unsupported Windy layer');
  }
  return Uri.https('embed.windy.com', '/embed2.html', {
    'lat': point.latitude.toString(),
    'lon': point.longitude.toString(),
    'detailLat': point.latitude.toString(),
    'detailLon': point.longitude.toString(),
    'zoom': '7',
    'level': 'surface',
    'overlay': overlay,
    'product': 'ecmwf',
    'menu': '',
    'message': 'true',
    'marker': 'true',
    'calendar': 'now',
    'pressure': '',
    'type': 'map',
    'location': 'coordinates',
    'detail': 'true',
    'metricWind': 'km/h',
    'metricTemp': '°C',
    'radarRange': '-1',
  });
}

class EmptyMessage extends StatelessWidget {
  const EmptyMessage(this.icon, this.title, this.message, {super.key});
  final IconData icon;
  final String title, message;
  @override
  Widget build(BuildContext c) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 58, color: Theme.of(c).colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(c).textTheme.titleLarge,
          ),
          const SizedBox(height: 7),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {this.trailing, super.key});
  final String text;
  final String? trailing;
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              c,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (trailing != null)
          Text(trailing!, style: Theme.of(c).textTheme.bodySmall),
      ],
    ),
  );
}

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if ((state.locating || state.weatherLoading) && state.weather == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (state.locationError != null && state.weather == null) {
      return const EmptyMessage(
        Icons.location_off_outlined,
        'Turn on location',
        'Kalasag uses your location to show nearby weather and center the map.',
      );
    }
    if (state.weatherError != null && state.weather == null) {
      return const EmptyMessage(
        Icons.cloud_off_outlined,
        'Weather is temporarily unavailable',
        'Check your connection, then pull down to try again.',
      );
    }
    final weather = state.weather;
    if (weather == null) {
      return const EmptyMessage(
        Icons.cloud_off_outlined,
        'No saved forecast yet',
        'Connect once to load weather for your area.',
      );
    }

    final current = weather.current;
    final hourly = weather.hourly;
    final daily = weather.daily;
    final times = List<dynamic>.from(hourly['time'] ?? []);
    final currentTime = '${current['time']}';
    final start = currentTime.length >= 13
        ? times.indexWhere(
            (item) => '$item'.startsWith(currentTime.substring(0, 13)),
          )
        : -1;
    final from = start < 0 ? 0 : start;
    final next = times.skip(from).take(8).toList();
    final demoAlerts =
        state.alerts.isNotEmpty &&
        state.alerts.every((alert) => alert.source == 'OFFLINE DEMO');
    final currentAlert = state.alerts.isEmpty ? null : state.alerts.first;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([state.refreshWeather(), state.refreshAlerts()]);
      },
      child: ListView(
        padding: KalasagSpace.page,
        children: [
          KalasagPageHeader(
            title: 'Today',
            subtitle: state.location?.label ?? 'Current location',
            action: IconButton.filledTonal(
              tooltip: 'Refresh weather',
              onPressed: state.weatherLoading ? null : state.refreshWeather,
              icon: state.weatherLoading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ),
          _CurrentWeatherCard(
            condition: weather.condition,
            temperature: value(current['temperature_2m'], '°'),
            feelsLike: value(current['apparent_temperature'], '°'),
            code: current['weather_code'],
            updated: relative(state.weatherUpdated),
          ),
          const SizedBox(height: KalasagSpace.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: _Metric(
                      Icons.water_drop_outlined,
                      'Humidity',
                      value(current['relative_humidity_2m'], '%'),
                    ),
                  ),
                  const SizedBox(height: 52, child: VerticalDivider()),
                  Expanded(
                    child: _Metric(
                      Icons.air_rounded,
                      'Wind',
                      value(current['wind_speed_10m'], ' km/h'),
                    ),
                  ),
                  const SizedBox(height: 52, child: VerticalDivider()),
                  Expanded(
                    child: _Metric(
                      Icons.umbrella_outlined,
                      'Rain',
                      current['precipitation'] is num
                          ? '${(current['precipitation'] as num).toStringAsFixed(1)} mm'
                          : 'N/A',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SectionTitle('Safety overview'),
          if (currentAlert == null)
            const KalasagNotice(
              icon: Icons.verified_user_outlined,
              title: 'No advisories to display',
              message:
                  'Keep monitoring official local updates as conditions change.',
              color: KalasagTheme.success,
            )
          else
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(KalasagRadius.md),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlertDetailScreen(currentAlert),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(KalasagSpace.lg),
                  child: Row(
                    children: [
                      Icon(
                        demoAlerts
                            ? Icons.science_outlined
                            : Icons.warning_amber_rounded,
                        color: demoAlerts
                            ? Theme.of(context).colorScheme.primary
                            : KalasagTheme.warning,
                      ),
                      const SizedBox(width: KalasagSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              demoAlerts
                                  ? 'Demo advisory'
                                  : currentAlert.severity,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              currentAlert.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
          const SectionTitle('Quick access'),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RadarScreen()),
                  ),
                  icon: const Icon(Icons.radar_rounded),
                  label: const Text('Weather map'),
                ),
              ),
              const SizedBox(width: KalasagSpace.sm),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: KalasagTheme.danger,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmergencyScreen()),
                  ),
                  icon: const Icon(Icons.sos_rounded),
                  label: const Text('Emergency'),
                ),
              ),
            ],
          ),
          const SectionTitle('Next hours'),
          SizedBox(
            height: 126,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: next.length,
              separatorBuilder: (_, _) => const SizedBox(width: 9),
              itemBuilder: (_, index) {
                final hourlyIndex = from + index;
                return Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: index == 0
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surface,
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(KalasagRadius.md),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        index == 0
                            ? 'Now'
                            : DateFormat.j().format(
                                DateTime.parse('${next[index]}'),
                              ),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Icon(
                        weatherIcon(
                          (hourly['weather_code'] as List?)?[hourlyIndex],
                        ),
                      ),
                      Text(
                        value(
                          (hourly['temperature_2m'] as List?)?[hourlyIndex],
                          '°',
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${value((hourly['precipitation_probability'] as List?)?[hourlyIndex], '%')} rain',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SectionTitle('3-day outlook'),
          Card(
            child: Column(
              children: List.generate(
                (daily['time'] as List? ?? []).take(3).length,
                (index) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 3,
                  ),
                  leading: Icon(
                    weatherIcon((daily['weather_code'] as List?)?[index]),
                  ),
                  title: Text(
                    DateFormat.EEEE().format(
                      DateTime.parse('${daily['time'][index]}'),
                    ),
                  ),
                  subtitle: Text(
                    '${value(daily['precipitation_sum'][index], ' mm')} expected rain',
                  ),
                  trailing: Text(
                    '${value(daily['temperature_2m_max'][index], '°')} / ${value(daily['temperature_2m_min'][index], '°')}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: KalasagSpace.lg),
          Text(
            'Forecast data: Open-Meteo • Updated ${relative(state.weatherUpdated)}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentWeatherCard extends StatelessWidget {
  const _CurrentWeatherCard({
    required this.condition,
    required this.temperature,
    required this.feelsLike,
    required this.code,
    required this.updated,
  });
  final String condition, temperature, feelsLike, updated;
  final dynamic code;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$condition, $temperature, feels like $feelsLike',
    child: Container(
      height: 220,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(KalasagRadius.lg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1769D2), Color(0xFF0E7180), Color(0xFF102A43)],
        ),
        image: const DecorationImage(
          image: AssetImage('assets/mascot/kalasag-weather.png'),
          fit: BoxFit.cover,
          opacity: .25,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33102A43),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const KalasagStatusPill(
                label: 'Current conditions',
                icon: Icons.schedule_rounded,
                color: Colors.white,
              ),
              const Spacer(),
              Icon(weatherIcon(code), color: Colors.white, size: 42),
            ],
          ),
          const Spacer(),
          Text(
            temperature,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 62,
              height: 1,
              fontWeight: FontWeight.w300,
              letterSpacing: -3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            condition,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Feels like $feelsLike • Updated $updated',
            style: const TextStyle(color: Color(0xFFDCEBFA)),
          ),
        ],
      ),
    ),
  );
}

// Kept temporarily as a migration reference while the new dashboard is
// validated against existing weather-data behavior.
// ignore: unused_element
class _LegacyWeatherScreen extends StatelessWidget {
  // ignore: unused_element_parameter
  const _LegacyWeatherScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if ((s.locating || s.weatherLoading) && s.weather == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (s.locationError != null && s.weather == null) {
      return EmptyMessage(
        Icons.location_off,
        'Location access needed',
        s.locationError!,
      );
    }
    if (s.weatherError != null && s.weather == null) {
      return EmptyMessage(
        Icons.cloud_off,
        'Weather unavailable',
        s.weatherError!,
      );
    }
    final w = s.weather;
    if (w == null) {
      return const EmptyMessage(
        Icons.cloud_off,
        'Weather is offline',
        'Connect once to save your local forecast.',
      );
    }
    final c = w.current, h = w.hourly, d = w.daily;
    final times = List<dynamic>.from(h['time'] ?? []);
    final start = times.indexWhere(
      (x) => '$x'.startsWith('${c['time']}'.substring(0, 13)),
    );
    final from = start < 0 ? 0 : start;
    final next = times.skip(from).take(12).toList();
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([s.refreshWeather(), s.refreshAlerts()]);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Weather',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'API integration evidence',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ApiActivityScreen()),
                ),
                icon: const Icon(Icons.api),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 17),
              const SizedBox(width: 5),
              Expanded(child: Text(s.location?.label ?? 'Current location')),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 250,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1769D2),
                  Color(0xFF08769A),
                  Color(0xFF153151),
                ],
              ),
              image: const DecorationImage(
                image: AssetImage('assets/mascot/kalasag-weather.png'),
                fit: BoxFit.cover,
                opacity: .42,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'NOW',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      weatherIcon(c['weather_code']),
                      color: Colors.white,
                      size: 36,
                    ),
                  ],
                ),
                Text(
                  w.condition,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  value(c['temperature_2m'], '°'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 68,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Text(
                  'Feels like ${value(c['apparent_temperature'], '°')}  •  Checked ${relative(s.weatherUpdated)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.compare_arrows, size: 17),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    w.modelCount > 0
                        ? 'Open-Meteo • ${w.modelCount} models • ${w.rainVotes}/${w.modelCount} detect rain'
                        : 'Open-Meteo live forecast',
                  ),
                ),
                Text(w.modelCount >= 3 ? 'High' : 'Live'),
              ],
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 17),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Metric(
                    Icons.water_drop_outlined,
                    'Humidity',
                    value(c['relative_humidity_2m'], '%'),
                  ),
                  _Metric(
                    Icons.air,
                    'Wind',
                    value(c['wind_speed_10m'], ' km/h'),
                  ),
                  _Metric(
                    Icons.water_drop_outlined,
                    'Rain',
                    c['precipitation'] is num
                        ? '${(c['precipitation'] as num).toStringAsFixed(1)} mm'
                        : 'N/A',
                  ),
                ],
              ),
            ),
          ),
          const SectionTitle('Next 12 hours'),
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: next.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final ix = from + i;
                return Container(
                  width: 74,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: i == 0
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        i == 0
                            ? 'Now'
                            : DateFormat.j().format(
                                DateTime.parse('${next[i]}'),
                              ),
                      ),
                      Icon(weatherIcon((h['weather_code'] as List?)?[ix])),
                      Text(
                        value((h['temperature_2m'] as List?)?[ix], '°'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        value(
                          (h['precipitation_probability'] as List?)?[ix],
                          '%',
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SectionTitle('3-day outlook'),
          Card(
            child: Column(
              children: List.generate(
                (d['time'] as List? ?? []).take(3).length,
                (i) => ListTile(
                  leading: Icon(weatherIcon((d['weather_code'] as List?)?[i])),
                  title: Text(
                    DateFormat.EEEE().format(DateTime.parse('${d['time'][i]}')),
                  ),
                  subtitle: Text(
                    '${value(d['temperature_2m_max'][i], '°')} / ${value(d['temperature_2m_min'][i], '°')}',
                  ),
                  trailing: Text(value(d['precipitation_sum'][i], ' mm')),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.icon, this.label, this.val);
  final IconData icon;
  final String label, val;
  @override
  Widget build(BuildContext c) => Column(
    children: [
      Icon(icon, color: Theme.of(c).colorScheme.secondary),
      Text(label, style: Theme.of(c).textTheme.bodySmall),
      Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
    ],
  );
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String filter = 'all';
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final data = filter == 'all'
        ? s.alerts
        : s.alerts.where((a) => a.category == filter).toList();
    final demoData =
        s.alerts.isNotEmpty &&
        s.alerts.every((alert) => alert.source == 'OFFLINE DEMO');
    if (s.alertsLoading && s.alerts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (s.alertsError != null && s.alerts.isEmpty) {
      return EmptyMessage(
        Icons.warning_amber,
        'Alert feed unavailable',
        s.alertsError!,
      );
    }
    return RefreshIndicator(
      onRefresh: s.refreshAlerts,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alerts',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      demoData
                          ? 'Practice data • Updated ${relative(s.alertsUpdated)}'
                          : 'Official sources • Updated ${relative(s.alertsUpdated)}',
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                ),
                icon: const Icon(Icons.notifications_outlined),
              ),
              IconButton(
                onPressed: s.refreshAlerts,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (s.alerts.isNotEmpty)
            Container(
              height: 135,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: const Color(0xFF1E293B),
                image: const DecorationImage(
                  image: AssetImage('assets/mascot/kalasag-alert.png'),
                  fit: BoxFit.cover,
                  opacity: .48,
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 190,
                  child: Text(
                    demoData
                        ? 'Practice advisories\nExplore the alert experience safely.'
                        : '${s.alerts.length} active reports\nFollow official local advice.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  {
                        'all': 'All',
                        'weather': 'Weather',
                        'earthquake': 'Quakes',
                        'volcano': 'Volcano',
                        'tsunami': 'Tsunami',
                        'wildfire': 'Wildfire',
                      }.entries
                      .map(
                        (x) => Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: ChoiceChip(
                            label: Text(x.value),
                            selected: filter == x.key,
                            onSelected: (_) => setState(() => filter = x.key),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          SectionTitle('Latest advisories', trailing: '${data.length}'),
          if (data.isEmpty)
            const EmptyMessage(
              Icons.shield_outlined,
              'No advisories match this filter',
              'Try another category or refresh for new information.',
            ),
          ...data.map((a) => _AlertCard(a)),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard(this.a);
  final AlertItem a;
  @override
  Widget build(BuildContext context) {
    final color = a.severity == 'Critical'
        ? KalasagTheme.danger
        : a.severity == 'High'
        ? KalasagTheme.warning
        : a.severity == 'Medium'
        ? Theme.of(context).colorScheme.primary
        : KalasagTheme.success;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AlertDetailScreen(a)),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 5, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                a.source.toUpperCase(),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              relative(a.publishedAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          a.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          a.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          a.severity.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen(this.alert, {super.key});
  final AlertItem alert;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Back to alerts',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Advisory details'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Chip(label: Text('${alert.severity} • ${alert.source}')),
        const SizedBox(height: 12),
        Text(
          alert.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(DateFormat.yMMMMd().add_jm().format(alert.publishedAt)),
        const Divider(height: 32),
        Text(alert.description, style: Theme.of(context).textTheme.bodyLarge),
        if (alert.affectedAreas.isNotEmpty) ...[
          const SectionTitle('Affected areas'),
          Text(alert.affectedAreas.join(', ')),
        ],
        if (alert.coordinates != null) ...[
          const SectionTitle('Mapped location'),
          Text(
            '${alert.coordinates!.latitude.toStringAsFixed(3)}, ${alert.coordinates!.longitude.toStringAsFixed(3)}',
          ),
        ],
        if (alert.sourceUrl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: FilledButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(alert.sourceUrl),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open official source'),
            ),
          ),
      ],
    ),
  );
}

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  static const _layers = <String, (String, IconData)>{
    'rain': ('Rain', Icons.water_drop_outlined),
    'wind': ('Wind', Icons.air_rounded),
    'temp': ('Temperature', Icons.thermostat_rounded),
    'clouds': ('Clouds', Icons.cloud_outlined),
  };

  late final WebViewController _controller;
  String _overlay = 'rain';
  String? _loadedSignature;
  String? _scheduledSignature;
  int _progress = 0;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF102A43))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _failed = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() => _failed = true);
            }
          },
        ),
      );
  }

  void _ensureLoaded(GeoPoint point) {
    final signature = '${point.latitude}:${point.longitude}:$_overlay';
    if (_loadedSignature == signature || _scheduledSignature == signature) {
      return;
    }
    _scheduledSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _scheduledSignature != signature) return;
      _loadedSignature = signature;
      _scheduledSignature = null;
      _controller.loadRequest(
        buildWindyEmbedUri(point: point, overlay: _overlay),
      );
    });
  }

  void _showMapInfo() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About this map',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const Text(
              'Use Windy’s play/pause control and timeline inside the map to animate genuine forecast frames. '
              'The selected layer, time indicator, legend, and map update together.',
            ),
            const SizedBox(height: 10),
            const Text(
              'Forecast playback is model guidance, not historical radar observation. '
              'Always follow official local advisories.',
            ),
            const SizedBox(height: 14),
            const KalasagStatusPill(
              label: 'Interactive forecast by Windy',
              icon: Icons.open_in_new_rounded,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final point = state.location;
    if (point == null) {
      return EmptyMessage(
        Icons.location_off_outlined,
        'Location needed',
        state.locationError ?? 'Enable location to center the weather map.',
      );
    }
    _ensureLoaded(point);
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 12, 4),
              child: Row(
                children: [
                  if (canPop)
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  else
                    const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weather map',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          point.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Map information',
                    onPressed: _showMapInfo,
                    icon: const Icon(Icons.info_outline_rounded),
                  ),
                  IconButton(
                    tooltip: 'Refresh map',
                    onPressed: _controller.reload,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 54,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: _layers.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final entry = _layers.entries.elementAt(index);
                  return ChoiceChip(
                    avatar: Icon(entry.value.$2, size: 18),
                    label: Text(entry.value.$1),
                    selected: _overlay == entry.key,
                    onSelected: (_) => setState(() {
                      _overlay = entry.key;
                      _loadedSignature = null;
                    }),
                  );
                },
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: WebViewWidget(controller: _controller),
                  ),
                  if (_progress < 100 && !_failed)
                    Align(
                      alignment: Alignment.topCenter,
                      child: LinearProgressIndicator(value: _progress / 100),
                    ),
                  if (_failed)
                    Positioned.fill(
                      child: ColoredBox(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.cloud_off_outlined, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  'Weather map unavailable',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Check your connection and try loading the map again.',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: _controller.reload,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Try again'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: IgnorePointer(
                      child: KalasagStatusPill(
                        label: '${_layers[_overlay]!.$1} forecast',
                        icon: Icons.play_circle_outline_rounded,
                        color: const Color(0xFF102A43),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Kept temporarily as a migration reference for the original Windy embed.
// ignore: unused_element
class _LegacyRadarScreen extends StatefulWidget {
  // ignore: unused_element_parameter
  const _LegacyRadarScreen({super.key});
  @override
  State<_LegacyRadarScreen> createState() => _LegacyRadarScreenState();
}

class _LegacyRadarScreenState extends State<_LegacyRadarScreen> {
  WebViewController? controller;
  String overlay = 'rain';
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  void _load() {
    final p = context.read<AppState>().location;
    if (p == null) return;
    final url =
        'https://embed.windy.com/embed2.html?lat=${p.latitude}&lon=${p.longitude}&detailLat=${p.latitude}&detailLon=${p.longitude}&width=650&height=450&zoom=7&level=surface&overlay=$overlay&product=ecmwf&menu=&message=true&marker=true&calendar=now&pressure=&type=map&location=coordinates&detail=true&metricWind=km%2Fh&metricTemp=%C2%B0C&radarRange=-1';
    controller ??= WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    controller!.loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (s.location == null) {
      return EmptyMessage(
        Icons.location_off,
        'Location needed',
        s.locationError ?? 'Enable location to center the weather map.',
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(
                'Radar',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: overlay,
                items: const [
                  DropdownMenuItem(value: 'rain', child: Text('Rain')),
                  DropdownMenuItem(value: 'wind', child: Text('Wind')),
                  DropdownMenuItem(value: 'temp', child: Text('Temperature')),
                  DropdownMenuItem(value: 'clouds', child: Text('Clouds')),
                ],
                onChanged: (x) {
                  if (x != null) {
                    setState(() {
                      overlay = x;
                      _load();
                    });
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(child: WebViewWidget(controller: controller!)),
      ],
    );
  }
}

class ReadyScreen extends StatelessWidget {
  const ReadyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final done = s.kit.where((x) => x.done).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Ready',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Text('Your offline emergency plan'),
        const SizedBox(height: 16),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  s.storageError == null
                      ? Icons.offline_bolt_outlined
                      : Icons.storage_outlined,
                  color: s.storageError == null
                      ? KalasagTheme.success
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available offline',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        s.storageError == null
                            ? 'Your checklist and plan stay on this device.'
                            : 'Some changes may not be saved. Try again.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (s.storageReady && s.storageError == null)
                  const Icon(Icons.check_circle, color: KalasagTheme.success),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 176,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFF1E293B),
            image: const DecorationImage(
              image: AssetImage('assets/mascot/kalasag-ready.png'),
              fit: BoxFit.cover,
              opacity: .48,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Go-bag progress',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                '${(100 * done / s.kit.length).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
              ),
              LinearProgressIndicator(value: done / s.kit.length),
              Text(
                '$done of ${s.kit.length} essentials packed',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        SectionTitle('Saved places', trailing: '${s.savedPlaces.length}/5'),
        Card(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: FilledButton.tonalIcon(
                  onPressed: s.location == null ? null : s.saveCurrent,
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Save current location'),
                ),
              ),
              ...s.savedPlaces.map(
                (p) => ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(p.label),
                  subtitle: Text(
                    '${p.latitude.toStringAsFixed(3)}, ${p.longitude.toStringAsFixed(3)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => s.removePlace(p.id),
                  ),
                ),
              ),
            ],
          ),
        ),
        SectionTitle('Go-bag checklist', trailing: '$done/${s.kit.length}'),
        Card(
          child: Column(
            children: s.kit
                .map(
                  (x) => CheckboxListTile(
                    value: x.done,
                    onChanged: (_) => s.toggleKit(x.id),
                    title: Text(
                      x.label,
                      style: TextStyle(
                        decoration: x.done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SectionTitle('Family plan'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _PlanField('Meeting place', 'meetingPlace', s),
                const SizedBox(height: 10),
                _PlanField(
                  'Out-of-town contact',
                  'outOfTownContact',
                  s,
                  phone: true,
                ),
                const SizedBox(height: 10),
                _PlanField('Medical notes', 'medicalNotes', s, lines: 3),
              ],
            ),
          ),
        ),
        const SectionTitle('Safety assistant'),
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.support_agent_outlined),
            ),
            title: const Text('Offline safety guide'),
            subtitle: const Text(
              'Bundled disaster steps without internet or AI credentials',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OfflineSafetyAssistantScreen(),
              ),
            ),
          ),
        ),
        const SectionTitle('Nearby shelters'),
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.business_outlined)),
            title: const Text('Find evacuation centers'),
            subtitle: Text(
              s.shelters.isEmpty
                  ? 'Search nearby centers and save an offline copy'
                  : '${s.shelters.length} centers loaded',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SheltersScreen()),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanField extends StatefulWidget {
  const _PlanField(
    this.label,
    this.keyName,
    this.state, {
    this.phone = false,
    this.lines = 1,
  });
  final String label, keyName;
  final AppState state;
  final bool phone;
  final int lines;
  @override
  State<_PlanField> createState() => _PlanFieldState();
}

class _PlanFieldState extends State<_PlanField> {
  late final TextEditingController c = TextEditingController(
    text: widget.state.familyPlan[widget.keyName],
  );
  @override
  Widget build(BuildContext context) => TextField(
    controller: c,
    maxLines: widget.lines,
    keyboardType: widget.phone ? TextInputType.phone : null,
    decoration: InputDecoration(labelText: widget.label),
    onChanged: (x) => widget.state.updatePlan(widget.keyName, x),
  );
}
