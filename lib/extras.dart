import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_state.dart';
import 'screens.dart';
import 'sos_features.dart';
import 'theme.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});
  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([state.loadHotlines(), state.loadGuides()]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final hotlines = snapshot.data![0] as Map<String, dynamic>;
        final guides = snapshot.data![1] as Map<String, dynamic>;
        final towns = Map<String, dynamic>.from(
          hotlines['municipalities'] ?? {},
        );
        final matches = query.trim().isEmpty
            ? <MapEntry<String, dynamic>>[]
            : towns.entries
                  .where((e) {
                    final haystack = '${e.key} ${e.value['province']}'
                        .toLowerCase();
                    return haystack.contains(query.toLowerCase());
                  })
                  .take(6)
                  .toList();
        MapEntry<String, dynamic>? local;
        final location = state.location?.label.toLowerCase() ?? '';
        for (final town in towns.entries) {
          if (location.contains(town.key.toLowerCase())) {
            local = town;
            break;
          }
        }
        final selected = matches.isNotEmpty ? matches.first : local;
        final phones = Map<String, dynamic>.from(
          selected?.value?['hotlines'] ?? hotlines['national'],
        );
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Emergency',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Text('Verified hotlines and first-aid guides'),
            const SizedBox(height: 14),
            Container(
              height: 130,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFFD33A45), Color(0xFFA51F2A)],
                ),
                image: const DecorationImage(
                  image: AssetImage('assets/mascot/kalasag.png'),
                  fit: BoxFit.cover,
                  opacity: .25,
                ),
              ),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Need help now?\nCall the right responder.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _EmergencyShortcut(
                    icon: Icons.contact_phone_outlined,
                    label: 'My contacts',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EmergencyContactsScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _EmergencyShortcut(
                    icon: Icons.flashlight_on_outlined,
                    label: 'Safety tools',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EmergencyToolsScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search municipality or province',
              ),
              onChanged: (value) => setState(() => query = value),
            ),
            if (matches.isNotEmpty)
              Card(
                child: Column(
                  children: matches
                      .map(
                        (town) => ListTile(
                          title: Text(town.key),
                          subtitle: Text('${town.value['province'] ?? ''}'),
                          onTap: () => setState(() => query = town.key),
                        ),
                      )
                      .toList(),
                ),
              ),
            SectionTitle(
              selected == null
                  ? 'National hotlines'
                  : '${selected.key} hotlines',
            ),
            Card(
              child: Column(
                children: phones.entries
                    .map(
                      (phone) => ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.phone)),
                        title: Text(_phoneLabel(phone.key)),
                        subtitle: Text('${phone.value}'),
                        trailing: FilledButton(
                          onPressed: () => _call('${phone.value}'),
                          child: const Text('Call'),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SectionTitle('First aid & evacuation guides'),
            ...List<dynamic>.from(guides['first_aid'] ?? []).map(
              (guide) => Card(
                child: ExpansionTile(
                  title: Text(guide['condition']),
                  children: _steps(guide['steps']),
                ),
              ),
            ),
            Card(
              child: ExpansionTile(
                title: const Text('Evacuation protocol'),
                children: _steps(guides['evacuation']?['protocols']),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _steps(dynamic values) => List<dynamic>.from(values ?? [])
      .asMap()
      .entries
      .map(
        (e) => ListTile(
          leading: CircleAvatar(
            radius: 12,
            child: Text('${e.key + 1}', style: const TextStyle(fontSize: 11)),
          ),
          title: Text('${e.value}'),
        ),
      )
      .toList();
  String _phoneLabel(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
  Future<void> _call(String number) async {
    final cleaned = number.replaceAll(RegExp(r'[^+\d]'), '');
    final opened = await launchUrl(Uri(scheme: 'tel', path: cleaned));
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone dialer is available.')),
      );
    }
  }
}

class _EmergencyShortcut extends StatelessWidget {
  const _EmergencyShortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: [
            Icon(icon, size: 30),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    ),
  );
}

class SheltersScreen extends StatefulWidget {
  const SheltersScreen({super.key});
  @override
  State<SheltersScreen> createState() => _SheltersScreenState();
}

class _SheltersScreenState extends State<SheltersScreen> {
  String query = '';
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    context.read<AppState>().refreshShelters();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final shelters = state.shelters
        .where(
          (s) => '${s.name} ${s.address} ${s.type}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to readiness',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Evacuation centers'),
        actions: [
          IconButton(
            onPressed: state.refreshShelters,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.refreshShelters,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search shelters',
              ),
              onChanged: (value) => setState(() => query = value),
            ),
            const SizedBox(height: 10),
            SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 10, label: Text('10 km')),
                ButtonSegment(value: 25, label: Text('25 km')),
                ButtonSegment(value: 50, label: Text('50 km')),
              ],
              selected: {state.shelterRadius},
              onSelectionChanged: (v) => state.refreshShelters(v.first),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '${shelters.length} found • ${relative(state.sheltersUpdated)}',
              ),
            ),
            if (state.sheltersLoading && shelters.isEmpty)
              const Center(child: CircularProgressIndicator()),
            if (state.sheltersError != null)
              Text(
                state.sheltersError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (!state.sheltersLoading && shelters.isEmpty)
              const EmptyMessage(
                Icons.business_outlined,
                'No evacuation centers found nearby',
                'Try a wider radius or refresh the OpenStreetMap list.',
              ),
            ...shelters.map(
              (shelter) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shelter.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${shelter.distanceKm?.toStringAsFixed(1) ?? '?'} km • ${shelter.type}',
                      ),
                      if (shelter.address.isNotEmpty) Text(shelter.address),
                      if (shelter.operator.isNotEmpty)
                        Text('Managed by ${shelter.operator}'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: () => _directions(
                              shelter.coordinates.latitude,
                              shelter.coordinates.longitude,
                            ),
                            icon: const Icon(Icons.directions),
                            label: const Text('Directions'),
                          ),
                          if (shelter.phone.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () =>
                                  launchUrl(Uri.parse('tel:${shelter.phone}')),
                              icon: const Icon(Icons.phone),
                              label: const Text('Call'),
                            ),
                          IconButton(
                            onPressed: () => launchUrl(
                              Uri.parse(shelter.sourceUrl),
                              mode: LaunchMode.externalApplication,
                            ),
                            icon: const Icon(Icons.info_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _directions(double lat, double lon) => launchUrl(
    Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon'),
    mode: LaunchMode.externalApplication,
  );
}

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to alerts',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Alert notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title: const Text('Nearby critical alerts'),
              subtitle: const Text(
                'High and Critical advisories with coordinates',
              ),
              value: state.notificationsEnabled,
              onChanged: (v) => state.updateSettings(enabled: v),
            ),
          ),
          const SectionTitle('Alert radius'),
          SegmentedButton<double>(
            segments: const [
              ButtonSegment(value: 50, label: Text('50 km')),
              ButtonSegment(value: 100, label: Text('100 km')),
              ButtonSegment(value: 250, label: Text('250 km')),
            ],
            selected: {state.alertRadius},
            onSelectionChanged: (v) => state.updateSettings(radius: v.first),
          ),
          const SectionTitle('Quiet hours'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Mute alerts overnight'),
                  subtitle: const Text('Alerts remain visible inside Kalasag'),
                  value: state.quietHoursEnabled,
                  onChanged: (v) => state.updateSettings(quiet: v),
                ),
                if (state.quietHoursEnabled)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 22, label: Text('10 PM–7 AM')),
                        ButtonSegment(value: 23, label: Text('11 PM–6 AM')),
                      ],
                      selected: {state.quietStart},
                      onSelectionChanged: (v) => state.updateSettings(
                        start: v.first,
                        end: v.first == 22 ? 7 : 6,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const ListTile(
            leading: Icon(Icons.lock_outline, color: KalasagTheme.success),
            title: Text('Settings stay on this device.'),
          ),
        ],
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  final pages = const [
    WeatherScreen(),
    AlertsScreen(),
    RadarScreen(),
    ReadyScreen(),
    EmergencyScreen(),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: IndexedStack(index: index, children: pages),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (value) => setState(() => index = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.cloud_outlined),
          selectedIcon: Icon(Icons.cloud),
          label: 'Now',
        ),
        NavigationDestination(
          icon: Icon(Icons.warning_amber_outlined),
          selectedIcon: Icon(Icons.warning),
          label: 'Alerts',
        ),
        NavigationDestination(icon: Icon(Icons.radar), label: 'Radar'),
        NavigationDestination(
          icon: Icon(Icons.shield_outlined),
          selectedIcon: Icon(Icons.shield),
          label: 'Ready',
        ),
        NavigationDestination(
          icon: Icon(Icons.phone_outlined),
          selectedIcon: Icon(Icons.phone),
          label: 'SOS',
        ),
      ],
    ),
  );
}
