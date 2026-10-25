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
                    Text('Live • Updated ${relative(s.alertsUpdated)}'),
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
                    '${s.alerts.length} active reports\nStay alert and follow official advice.',
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
              'Walang naitalang sakuna ngayon. Ligtas ang araw!',
              'We will keep watching for official updates.',
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
                        'Hive offline storage',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(s.storageLastOperation),
                      const SizedBox(height: 3),
                      Text(
                        s.storageError == null
                            ? 'Data stays available without internet'
                            : 'The app remains usable; try saving again.',
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
