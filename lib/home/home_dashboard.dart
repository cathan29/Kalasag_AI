import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          sliver: SliverList.list(
            children: [
              _Header(
                model: model,
                isRefreshing: isRefreshing,
                onRefresh: onRefresh,
              ),
              const SizedBox(height: 14),
              _BriefingHero(model: model),
              const SizedBox(height: 18),
              _SectionHeading(title: 'Hazard Status', subtitle: ''),
              const SizedBox(height: 10),
              _Hazards(items: model.hazards),
              const Divider(height: 28),
              const _SectionHeading(
                title: 'Are You Ready?',
                subtitle: 'Your preparedness at a glance',
              ),
              const SizedBox(height: 10),
              _Readiness(summary: model.readiness),
              const Divider(height: 28),
              const _SectionHeading(
                title: 'Hourly Weather Pulse',
                subtitle: 'Rain chance and temperature for the next hours',
              ),
              const SizedBox(height: 10),
              _HourlyPulse(points: model.hourlyPulse),
              const SizedBox(height: 20),
              const _SectionHeading(
                title: 'Official Advisory',
                subtitle: 'Latest available source report',
              ),
              const SizedBox(height: 10),
              _Advisory(summary: model.advisory, onTap: onOpenAdvisory),
              const SizedBox(height: 14),
              _Attribution(model: model),
              const SizedBox(height: 14),
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
        width: 54,
        height: 54,
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
            Text(
              'PHILIPPINE DISASTER-READINESS APP',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
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
    HomeMascotMood.heat => 'assets/mascot/kalasag-weather-heat.png',
    HomeMascotMood.rain => 'assets/mascot/kalasag-weather-rain.png',
    HomeMascotMood.storm => 'assets/mascot/kalasag-weather-storm.png',
  };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final heroHeight = textScale > 1.3 ? 310.0 : 238.0;
      return SizedBox(
        height: heroHeight,
        child: OverflowBox(
          alignment: Alignment.center,
          minWidth: constraints.maxWidth + 36,
          maxWidth: constraints.maxWidth + 36,
          child: SizedBox(
            key: const Key('home-briefing-hero'),
            height: heroHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  asset,
                  key: Key('home-mascot-${model.mascotMood.name}'),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  semanticLabel: 'KALASAG weather companion',
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: constraints.maxWidth * .48,
                    child: _BriefingText(model: model),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _BriefingText extends StatelessWidget {
  const _BriefingText({required this.model});
  final HomePresentation model;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 8, 20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD75A),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          model.briefingTitle,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          model.briefingBody,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFFE6EEF7),
            height: 1.25,
          ),
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
      if (subtitle.isNotEmpty) ...[
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ],
  );
}

class _Hazards extends StatelessWidget {
  const _Hazards({required this.items});
  final List<HomeHazardItem> items;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 3 : 2;
        final tileWidth = (constraints.maxWidth - (columns - 1) * 8) / columns;
        return Wrap(
          key: const Key('home-hazard-wrap'),
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              SizedBox(
                width: tileWidth,
                height: textScale > 1.3 ? 112 : 72,
                child: _HazardTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _HazardTile extends StatelessWidget {
  const _HazardTile({required this.item});
  final HomeHazardItem item;

  (Color, IconData) _visuals(BuildContext context) {
    if (item.isEstimated) {
      return (const Color(0xFFC62828), Icons.thermostat_outlined);
    }
    final label = item.label.toLowerCase();
    if (label.contains('rain')) {
      return (const Color(0xFFE7A321), Icons.water_drop_outlined);
    }
    if (label.contains('cyclone') || label.contains('official alerts')) {
      return (Theme.of(context).colorScheme.primary, Icons.cyclone_outlined);
    }
    return switch (item.tone) {
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
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _visuals(context);
    if (item.isEstimated) {
      return Container(
        key: const Key('home-hazard-heat'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: .55)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.detail,
                    key: const Key('home-hazard-heat-value'),
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final displayValue = item.value == 'Monitoring official updates'
        ? 'Monitoring'
        : item.value;
    final secondary = item.label;
    final isClimate = secondary.toLowerCase() == 'climate outlook';
    return Container(
      key: isClimate ? const Key('home-hazard-climate') : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isClimate)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      displayValue,
                      key: const Key('home-hazard-climate-value'),
                      maxLines: 1,
                      softWrap: false,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  )
                else
                  Text(
                    displayValue,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  secondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isClimate
                        ? color
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isClimate ? FontWeight.w700 : null,
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
  Widget build(BuildContext context) {
    final children = [
      _ReadinessItem(
        icon: Icons.backpack_outlined,
        label: 'Go-Bag',
        value: summary.goBagPercent == null
            ? 'Not set'
            : '${summary.goBagPercent}%',
      ),
      _ReadinessItem(
        icon: Icons.groups_outlined,
        label: 'Family Plan',
        value: summary.familyPlanReady ? 'Ready' : 'Needs setup',
      ),
      _ReadinessItem(
        icon: Icons.contact_phone_outlined,
        label: 'Emergency Contacts',
        value: '${summary.emergencyContactCount}',
      ),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          Expanded(child: children[index]),
          if (index < children.length - 1)
            const SizedBox(height: 62, child: VerticalDivider()),
        ],
      ],
    );
  }
}

class _ReadinessItem extends StatelessWidget {
  const _ReadinessItem({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 25, color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 4),
      Text(
        label,
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall,
      ),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
    final visible = points.take(6).toList(growable: false);
    Widget values(
      String Function(HomeHourlyPoint point) value, {
      TextStyle? style,
    }) => Row(
      children: [
        for (final point in visible)
          Expanded(
            child: Text(
              value(point),
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        values(
          (point) => point.rainProbability == null
              ? '--'
              : '${point.rainProbability}%',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 18,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final endInset = constraints.maxWidth / (visible.length * 2);
              return Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: endInset,
                    right: endInset,
                    child: Container(
                      key: const Key('home-hourly-line'),
                      height: 2,
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  Row(
                    children: [
                      for (var index = 0; index < visible.length; index++)
                        Expanded(
                          child: Center(
                            child: Container(
                              key: index == 0
                                  ? const Key('home-hourly-node-0')
                                  : null,
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: index == 0
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 1.8,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 5),
        values(
          (point) => DateFormat.j().format(point.time.toLocal()),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 2),
        values(
          (point) => point.temperatureCelsius == null
              ? '--'
              : '${point.temperatureCelsius!.round()}\u00b0',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
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
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                item.isDemo ? Icons.science_outlined : Icons.campaign_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.alert.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.source}  -  ${_relative(item.updatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
