import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../design_system.dart';
import 'home_insight.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({
    super.key,
    required this.model,
    required this.isRefreshing,
    required this.onRefresh,
    this.onOpenAdvisory,
  });

  final HomePresentation model;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;
  final VoidCallback? onOpenAdvisory;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: KalasagSpace.page,
          sliver: SliverList.list(
            children: [
              _Header(
                model: model,
                isRefreshing: isRefreshing,
                onRefresh: onRefresh,
              ),
              const SizedBox(height: 18),
              _BriefingHero(model: model),
              const SizedBox(height: 24),
              _SectionHeading(
                title: 'Hazard Status',
                subtitle: model.monitoringOfficialUpdates
                    ? 'Local official data is being monitored'
                    : 'Current verified information for your area',
              ),
              const SizedBox(height: 12),
              _Hazards(items: model.hazards),
              const SizedBox(height: 26),
              const _SectionHeading(
                title: 'Are You Ready?',
                subtitle: 'Your preparedness at a glance',
              ),
              const SizedBox(height: 12),
              _Readiness(summary: model.readiness),
              const SizedBox(height: 26),
              const _SectionHeading(
                title: 'Hourly Weather Pulse',
                subtitle: 'Rain chance and temperature for the next hours',
              ),
              const SizedBox(height: 12),
              _HourlyPulse(points: model.hourlyPulse),
              const SizedBox(height: 26),
              const _SectionHeading(
                title: 'Official Advisory',
                subtitle: 'Latest available source report',
              ),
              const SizedBox(height: 12),
              _Advisory(summary: model.advisory, onTap: onOpenAdvisory),
              const SizedBox(height: 22),
              _Attribution(model: model),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.model,
    required this.isRefreshing,
    required this.onRefresh,
  });
  final HomePresentation model;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Image.asset(
        'assets/mascot/kalasagicon-transparent.png',
        key: const Key('home-brand-logo'),
        width: 46,
        height: 46,
        fit: BoxFit.contain,
        semanticLabel: 'KALASAG logo',
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KALASAG',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(letterSpacing: 1.5),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    model.locationLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      Semantics(
        button: true,
        label: 'Refresh weather and advisories',
        child: IconButton(
          tooltip: 'Refresh weather and advisories',
          onPressed: isRefreshing ? null : onRefresh,
          icon: isRefreshing
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_outlined),
        ),
      ),
    ],
  );
}

class _BriefingHero extends StatelessWidget {
  const _BriefingHero({required this.model});
  final HomePresentation model;

  String get asset => switch (model.mascotMood) {
    HomeMascotMood.happy => 'assets/mascot/kalasag-weather-happy.png',
    HomeMascotMood.rain => 'assets/mascot/kalasag-weather-rain.png',
    HomeMascotMood.storm => 'assets/mascot/kalasag-weather-storm.png',
  };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 380;
      final image = ClipRRect(
        borderRadius: narrow
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : BorderRadius.circular(20),
        child: Image.asset(
          asset,
          key: Key('home-mascot-${model.mascotMood.name}'),
          height: narrow ? 210 : 280,
          width: double.infinity,
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
          semanticLabel: 'KALASAG weather companion',
        ),
      );
      final text = _BriefingText(model: model);
      if (narrow) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF102A43),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [image, text],
          ),
        );
      }
      return SizedBox(
        height: 280,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * .56,
                ),
                child: text,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _BriefingText extends StatelessWidget {
  const _BriefingText({required this.model});
  final HomePresentation model;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: const BoxDecoration(
      color: Color(0xF0102A43),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          model.currentTemperatureCelsius == null
              ? model.currentCondition
              : '${model.currentTemperatureCelsius!.round()}\u00b0  ${model.currentCondition}',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: const Color(0xFFFFD75A)),
        ),
        const SizedBox(height: 10),
        Text(
          model.briefingTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          model.briefingBody,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFE6EEF7)),
        ),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});
  final String title, subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class _Hazards extends StatelessWidget {
  const _Hazards({required this.items});
  final List<HomeHazardItem> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth < 430
          ? constraints.maxWidth
          : (constraints.maxWidth - 10) / 2;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final item in items)
            SizedBox(
              width: width,
              child: _HazardTile(item: item),
            ),
        ],
      );
    },
  );
}

class _HazardTile extends StatelessWidget {
  const _HazardTile({required this.item});
  final HomeHazardItem item;

  (Color, IconData) _visuals(BuildContext context) => switch (item.tone) {
    HomeHazardTone.safe => (
      const Color(0xFF218A61),
      Icons.verified_user_outlined,
    ),
    HomeHazardTone.caution => (const Color(0xFFE7A321), Icons.info_outline),
    HomeHazardTone.warning => (
      const Color(0xFFE87817),
      Icons.warning_amber_outlined,
    ),
    HomeHazardTone.danger => (
      Theme.of(context).colorScheme.error,
      Icons.dangerous_outlined,
    ),
    HomeHazardTone.neutral => (
      Theme.of(context).colorScheme.outline,
      Icons.shield_outlined,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _visuals(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  item.detail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _Readiness extends StatelessWidget {
  const _Readiness({required this.summary});
  final HomeReadinessSummary summary;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final children = [
        _ReadinessItem(
          icon: Icons.backpack_outlined,
          label: 'Go-Bag',
          value: summary.goBagPercent == null
              ? 'Not set'
              : '${summary.goBagPercent}%',
          detail: '${summary.completedKitItems}/${summary.totalKitItems} items',
        ),
        _ReadinessItem(
          icon: Icons.groups_outlined,
          label: 'Family Plan',
          value: summary.familyPlanReady ? 'Ready' : 'Needs setup',
          detail: summary.familyPlanReady
              ? 'Plan completed'
              : 'Complete all plan details',
        ),
        _ReadinessItem(
          icon: Icons.contact_phone_outlined,
          label: 'Emergency Contacts',
          value: '${summary.emergencyContactCount}',
          detail: summary.emergencyContactCount == 1
              ? 'Saved contact'
              : 'Saved contacts',
        ),
      ];
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: constraints.maxWidth < 380
            ? Column(
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    children[index],
                    if (index < children.length - 1) const Divider(height: 24),
                  ],
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    Expanded(child: children[index]),
                    if (index < children.length - 1)
                      const SizedBox(height: 70, child: VerticalDivider()),
                  ],
                ],
              ),
      );
    },
  );
}

class _ReadinessItem extends StatelessWidget {
  const _ReadinessItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });
  final IconData icon;
  final String label, value, detail;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            Text(
              detail,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _HourlyPulse extends StatelessWidget {
  const _HourlyPulse({required this.points});
  final List<HomeHourlyPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const _EmptyPanel(
        icon: Icons.schedule_outlined,
        text: 'Hourly forecast is not available yet.',
      );
    }
    return Container(
      height: 132,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        scrollDirection: Axis.horizontal,
        itemCount: points.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final point = points[index];
          return SizedBox(
            width: 76,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.j().format(point.time.toLocal()),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Icon(
                  _weatherIcon(point.weatherCode),
                  color: Theme.of(context).colorScheme.primary,
                ),
                Text(
                  point.rainProbability == null
                      ? 'Rain --'
                      : 'Rain ${point.rainProbability}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  point.temperatureCelsius == null
                      ? '--'
                      : '${point.temperatureCelsius!.round()}\u00b0',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

IconData _weatherIcon(int? code) {
  if (code == null) return Icons.cloud_outlined;
  if ({95, 96, 99}.contains(code)) return Icons.thunderstorm_outlined;
  if ({51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82}.contains(code)) {
    return Icons.water_drop_outlined;
  }
  if ({0, 1}.contains(code)) return Icons.wb_sunny_outlined;
  return Icons.cloud_outlined;
}

class _Advisory extends StatelessWidget {
  const _Advisory({required this.summary, required this.onTap});
  final HomeAdvisorySummary? summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final item = summary;
    if (item == null) {
      return const _EmptyPanel(
        icon: Icons.campaign_outlined,
        text: 'No advisory is available. Continue monitoring official sources.',
      );
    }
    final tags = [
      item.isDemo
          ? 'Practice'
          : item.isStale
          ? 'Stale'
          : item.isLocal
          ? 'Local'
          : 'Area not confirmed',
      item.severity,
      item.languageLabel,
    ];
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.campaign_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${item.source}  -  ${_relative(item.updatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final tag in tags)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right_outlined),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _Attribution extends StatelessWidget {
  const _Attribution({required this.model});
  final HomePresentation model;

  @override
  Widget build(BuildContext context) => Text(
    'Forecast: Open-Meteo  -  Updated ${_relative(model.weatherUpdated)}',
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

String _relative(DateTime? value) {
  if (value == null) return 'time unavailable';
  final difference = DateTime.now().difference(value);
  if (difference.isNegative || difference.inMinutes < 1) return 'just now';
  if (difference.inHours < 1) return '${difference.inMinutes} min ago';
  if (difference.inDays < 1) return '${difference.inHours} hr ago';
  return DateFormat.MMMd().add_jm().format(value.toLocal());
}
