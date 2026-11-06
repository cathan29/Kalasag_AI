import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_state.dart';
import 'extras.dart';
import 'models.dart';
import 'services.dart';
import 'theme.dart';

String _relative(DateTime? value) {
  if (value == null) return 'Not yet updated';
  final age = DateTime.now().difference(value);
  if (age.inMinutes < 1) return 'Just now';
  if (age.inHours < 1) return '${age.inMinutes} min ago';
  if (age.inDays < 1) return '${age.inHours} hr ago';
  return '${age.inDays} days ago';
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String category = 'all';
  bool nearbyOnly = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final alerts = state.alerts.where((alert) {
      if (category != 'all' && alert.category != category) return false;
      if (!nearbyOnly) return true;
      if (state.location == null || alert.coordinates == null) return false;
      return AlertService.distanceKm(state.location!, alert.coordinates!) <=
          state.alertRadius;
    }).toList();

    if (state.alertsLoading && state.alerts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: state.refreshAlerts,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Disaster alerts',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Philippines-focused reports with clear source labels',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Notification preferences',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                ),
                icon: const Icon(Icons.notifications_outlined),
              ),
              IconButton(
                tooltip: 'Refresh alerts',
                onPressed: state.alertsLoading ? null : state.refreshAlerts,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FeedStatusCard(state: state),
          if (state.alertsError != null) ...[
            const SizedBox(height: 10),
            _InlineNotice(
              icon: Icons.sync_problem_outlined,
              message: state.alertsError!,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.public),
                      label: Text('All PH'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.near_me_outlined),
                      label: Text('Near me'),
                    ),
                  ],
                  selected: {nearbyOnly},
                  onSelectionChanged: (value) =>
                      setState(() => nearbyOnly = value.first),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: nearbyOnly
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      state.location == null
                          ? 'Location is unavailable. No alert can be confirmed as nearby.'
                          : 'Showing reports with mapped points within ${state.alertRadius.round()} km. Nationwide or unmapped advisories are excluded.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  {
                    'all': 'All',
                    'weather': 'Weather',
                    'earthquake': 'Earthquake',
                    'volcano': 'Volcano',
                    'tsunami': 'Tsunami',
                    'flood': 'Flood',
                    'landslide': 'Landslide',
                    'wildfire': 'Fire',
                  }.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: category == entry.key,
                        onSelected: (_) => setState(() => category = entry.key),
                      ),
                    );
                  }).toList(),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            reverseDuration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final offset =
                  Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  );
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: Column(
              key: ValueKey(
                '${nearbyOnly ? 'nearby' : 'all'}-$category-${alerts.length}',
              ),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle('Current reports', trailing: '${alerts.length}'),
                if (alerts.isEmpty)
                  _EmptyMessage(
                    Icons.shield_outlined,
                    nearbyOnly
                        ? 'No mapped reports in this radius'
                        : 'No reports match this filter',
                    state.alerts.isEmpty
                        ? 'This does not mean there is no hazard. Check the official sources below.'
                        : 'Change the category or location scope.',
                  ),
                ...alerts.map((alert) => _DisasterAlertCard(alert: alert)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OfficialAlertSourcesScreen(),
              ),
            ),
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Check Philippine official sources'),
          ),
        ],
      ),
    );
  }
}

class _FeedStatusCard extends StatelessWidget {
  const _FeedStatusCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final practice =
        state.alertsDemoMode ||
        (state.alerts.isNotEmpty && state.alerts.every((a) => a.isDemo));
    final color = practice
        ? Theme.of(context).colorScheme.tertiary
        : state.alertsFromCache
        ? KalasagTheme.warning
        : KalasagTheme.success;
    final title = practice
        ? 'Practice mode — not live'
        : state.alertsFromCache
        ? 'Saved reports — live refresh unavailable'
        : 'Supplementary live reports';
    final description = practice
        ? 'These scenarios teach the interface. They are not current warnings.'
        : state.alertsFromCache
        ? 'Verify the timestamp and open the issuing source before acting.'
        : 'Automated reports come from documented international feeds. Confirm with Philippine authorities.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        border: Border.all(color: color.withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            practice ? Icons.science_outlined : Icons.verified_user_outlined,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(description),
                const SizedBox(height: 6),
                Text(
                  'Retrieved ${_relative(state.alertsUpdated)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (state.alertSources.isNotEmpty)
                  TextButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (_) =>
                          _SourceHealthSheet(sources: state.alertSources),
                    ),
                    child: Text(
                      'Source status (${state.alertSources.where((s) => s.available).length}/${state.alertSources.length})',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: KalasagTheme.warning.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, color: KalasagTheme.warning),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

class _SourceHealthSheet extends StatelessWidget {
  const _SourceHealthSheet({required this.sources});
  final List<AlertSourceStatus> sources;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Text(
          'Automated source status',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...sources.map(
          (source) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              source.available ? Icons.check_circle : Icons.error_outline,
              color: source.available
                  ? KalasagTheme.success
                  : KalasagTheme.warning,
            ),
            title: Text(source.name),
            subtitle: Text(
              source.available
                  ? 'Available · checked ${_relative(source.checkedAt)}'
                  : source.message,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DisasterAlertCard extends StatelessWidget {
  const _DisasterAlertCard({required this.alert});
  final AlertItem alert;

  Color _color() => switch (alert.severity.toLowerCase()) {
    'critical' => KalasagTheme.danger,
    'high' => KalasagTheme.warning,
    'medium' => const Color(0xFF2563EB),
    _ => KalasagTheme.success,
  };

  IconData _icon() => switch (alert.category) {
    'earthquake' => Icons.vibration,
    'volcano' => Icons.landscape_outlined,
    'tsunami' => Icons.tsunami,
    'flood' => Icons.flood_outlined,
    'landslide' => Icons.terrain_outlined,
    'wildfire' => Icons.local_fire_department_outlined,
    _ => Icons.thunderstorm_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final level = alert.officialLevel.isEmpty
        ? alert.severity
        : alert.officialLevel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AlertDetailScreen(alert)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon(), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              alert.source,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            _relative(alert.publishedAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        alert.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        alert.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Tag(text: level, color: color),
                          _Tag(
                            text: alert.isDemo
                                ? 'PRACTICE'
                                : alert.verificationStatus.toUpperCase(),
                            color: alert.isDemo
                                ? Theme.of(context).colorScheme.tertiary
                                : Theme.of(context).colorScheme.primary,
                          ),
                          if (alert.isCached)
                            const _Tag(
                              text: 'SAVED COPY',
                              color: KalasagTheme.warning,
                            ),
                        ],
                      ),
                    ],
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

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 10),
    ),
  );
}

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen(this.alert, {super.key});
  final AlertItem alert;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat.yMMMMd().add_jm();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to alerts',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Advisory details'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          if (alert.isDemo || alert.isCached)
            _InlineNotice(
              icon: alert.isDemo
                  ? Icons.science_outlined
                  : Icons.history_outlined,
              message: alert.isDemo
                  ? 'Practice scenario only. This is not a current emergency warning.'
                  : 'This is a saved copy. Conditions may have changed since retrieval.',
            ),
          const SizedBox(height: 12),
          Text(
            alert.source,
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            alert.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(
                text: alert.severity.toUpperCase(),
                color: KalasagTheme.warning,
              ),
              _Tag(
                text: alert.lifecycle.toUpperCase(),
                color: KalasagTheme.success,
              ),
              if (alert.officialLevel.isNotEmpty)
                _Tag(
                  text: alert.officialLevel.toUpperCase(),
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
          const Divider(height: 32),
          _DetailRow(
            label: 'Issued',
            value: formatter.format(alert.publishedAt.toLocal()),
          ),
          if (alert.updatedAt != null)
            _DetailRow(
              label: 'Updated',
              value: formatter.format(alert.updatedAt!.toLocal()),
            ),
          if (alert.expiresAt != null)
            _DetailRow(
              label: 'Expires',
              value: formatter.format(alert.expiresAt!.toLocal()),
            ),
          if (alert.referenceNumber.isNotEmpty)
            _DetailRow(label: 'Reference', value: alert.referenceNumber),
          const _SectionTitle('Situation'),
          Text(alert.description, style: Theme.of(context).textTheme.bodyLarge),
          if (alert.affectedAreas.isNotEmpty) ...[
            const _SectionTitle('Affected areas'),
            Text(alert.affectedAreas.join(', ')),
          ],
          if (alert.actions.isNotEmpty) ...[
            const _SectionTitle('What to do'),
            ...alert.actions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 20),
                    const SizedBox(width: 9),
                    Expanded(child: Text(action)),
                  ],
                ),
              ),
            ),
          ],
          if (alert.coordinates != null) ...[
            const _SectionTitle('Mapped point'),
            Text(
              '${alert.coordinates!.latitude.toStringAsFixed(3)}, '
              '${alert.coordinates!.longitude.toStringAsFixed(3)}',
            ),
          ],
          const SizedBox(height: 22),
          if (alert.sourceUrl.isNotEmpty)
            FilledButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(alert.sourceUrl),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new),
              label: Text(
                alert.verificationStatus == 'official'
                    ? 'Open official bulletin'
                    : 'Open source report',
              ),
            ),
          const SizedBox(height: 10),
          Text(
            'Kalasag preserves the source terminology when available. Visual priority is an app sorting aid, not a replacement for an agency warning level.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.trailing});
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (trailing != null) Text(trailing!),
      ],
    ),
  );
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage(this.icon, this.title, this.message);
  final IconData icon;
  final String title, message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Column(
      children: [
        Icon(icon, size: 42, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}

class OfficialAlertSourcesScreen extends StatelessWidget {
  const OfficialAlertSourcesScreen({super.key});

  static const sources = [
    (
      agency: 'DOST-PAGASA',
      coverage:
          'Weather, tropical cyclone, rainfall, flood and marine warnings',
      url: 'https://www.pagasa.dost.gov.ph/',
    ),
    (
      agency: 'DOST-PHIVOLCS Earthquake Information',
      coverage: 'Official Philippine earthquake bulletins',
      url: 'https://earthquake.phivolcs.dost.gov.ph/',
    ),
    (
      agency: 'DOST-PHIVOLCS Volcano Bulletins',
      coverage: 'Volcano status and bulletins',
      url: 'https://wovodat.phivolcs.dost.gov.ph/bulletin/list-of-bulletin',
    ),
    (
      agency: 'DOST-PHIVOLCS Tsunami Information',
      coverage: 'Tsunami advisories and warnings',
      url: 'https://tsunami.phivolcs.dost.gov.ph/',
    ),
    (
      agency: 'NDRRMC',
      coverage: 'National situation reports and disaster coordination',
      url: 'https://ndrrmc.gov.ph/',
    ),
    (
      agency: 'DENR-MGB',
      coverage: 'Landslide, flood and geohazard information',
      url: 'https://mgb.gov.ph/',
    ),
    (
      agency: 'HazardHunterPH',
      coverage:
          'Government hazard assessment from PHIVOLCS, MGB and PAGASA data',
      url: 'https://hazardhunter.georisk.gov.ph/',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Philippine official sources')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _InlineNotice(
          icon: Icons.info_outline,
          message:
              'These authoritative pages are verification links. Kalasag does not scrape them or claim an undocumented government API.',
        ),
        const SizedBox(height: 12),
        ...sources.map(
          (source) => Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_outlined),
              title: Text(source.agency),
              subtitle: Text(source.coverage),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => launchUrl(
                Uri.parse(source.url),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
